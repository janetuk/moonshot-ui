/* libmoonshot - Moonshot client library
 * Copyright (c) 2011, JANET(UK)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of JANET(UK) nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * Author: Sam Thursfield <samthursfield@codethink.co.uk>
 */

#include <windows.h>
//#include <rpc.h>
#include <msrpc-mingw.h>

#include "libmoonshot.h"
#include "libmoonshot-common.h"
#include "moonshot-msrpc.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#define MOONSHOT_ENDPOINT_NAME "/org/janet/Moonshot"
#define MOONSHOT_INSTALL_PATH_KEY "Software\\Moonshot"

void *__RPC_USER MIDL_user_allocate (size_t size) {
    return malloc (size);
}

void __RPC_USER MIDL_user_free (void *data) {
    if (data == NULL)
        return;

    free (data);
}

void moonshot_free (void *data)
{
    free (data);
}

static MoonshotError *moonshot_error_new_from_status (MoonshotErrorCode code,
                                                      DWORD             status)
{
    MoonshotError *error = malloc (sizeof (MoonshotError));
    error->code = code;
    error->message = malloc (256);

    FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM, NULL, status, 0, (LPSTR)error->message, 255, NULL);
    return error;
}

static MoonshotError *moonshot_error_new_with_status (MoonshotErrorCode code,
                                                      DWORD             status,
                                                      const char        *format, ...)
{
    MoonshotError *error = malloc (sizeof (MoonshotError));
    char *buffer;
    va_list args;
    int length;

    va_start (args, format);

    error->code = code;

    buffer = malloc (strlen (format) + 256 + 3);
    strcpy (buffer, format);
    strcat (buffer, ": ");

    FormatMessage (FORMAT_MESSAGE_FROM_SYSTEM,
                   NULL,
                   status,
                   0,
                   (LPSTR)buffer + strlen (format) + 3,
                   255,
                   NULL);

    length = _vscprintf (buffer, args);
    error->message = malloc (length + 1);
    _vsnprintf (error->message, length, buffer, args);
    free (buffer);

    va_end (args);

    return error;
}

static void launch_server (MoonshotError **error) {
    HKEY key = NULL;
    STARTUPINFO startup_info = { 0 };
    PROCESS_INFORMATION process_info = { 0 };
    LONG status;
    BOOL success;
    DWORD value_type;
    DWORD length;
    char exe_path[1024];

    status = RegOpenKeyEx (HKEY_LOCAL_MACHINE,
                           MOONSHOT_INSTALL_PATH_KEY,
                           0,
                           KEY_READ,
                           &key);

    if (status == ERROR_FILE_NOT_FOUND) {
        *error = moonshot_error_new
                   (MOONSHOT_ERROR_INSTALLATION_ERROR,
                    "Moonshot is not installed correctly on this system. "
                    "(Registry key HKLM\\%s was not found).",
                    MOONSHOT_INSTALL_PATH_KEY);
        return;
    } else if (status != 0) {
        *error = moonshot_error_new_with_status
                   (MOONSHOT_ERROR_OS_ERROR,
                    status,
                    "Unable to read registry key HKLM\\%s",
                    MOONSHOT_INSTALL_PATH_KEY);
        return;
    }

    length = 1023;
    status = RegQueryValueEx (key, NULL, NULL, &value_type, (LPBYTE )exe_path, &length);

    if (value_type != REG_SZ) {
        *error = moonshot_error_new_with_status
                   (MOONSHOT_ERROR_INSTALLATION_ERROR,
                    status,
                    "Value of registry key HKLM\\%s is invalid. Please set it "
                    "to point to the location of moonshot.exe",
                    MOONSHOT_INSTALL_PATH_KEY);
        return;
    }


    if (status != 0) {
        *error = moonshot_error_new_with_status
                   (MOONSHOT_ERROR_OS_ERROR,
                    status,
                    "Unable to read value of registry key HKLM\\%s",
                    MOONSHOT_INSTALL_PATH_KEY);
        return;
    }

    startup_info.cb = sizeof (startup_info);
    success = CreateProcess (exe_path,
                             NULL,
                             NULL,
                             NULL,
                             TRUE,
                             DETACHED_PROCESS,
                             NULL,
                             NULL,
                             &startup_info, &process_info);

    if (! success) {
        *error = moonshot_error_new_with_status
                   (MOONSHOT_ERROR_UNABLE_TO_START_SERVICE,
                    GetLastError (),
                    "Unable to spawn the moonshot server at '%s'",
                    exe_path);
        return;
    }
}

static void bind_rpc (MoonshotError **error)
{
    DWORD status;
    int   i;

    status = rpc_client_bind (&moonshot_binding_handle,
                              MOONSHOT_ENDPOINT_NAME,
                              RPC_PER_USER);

    if (status != RPC_S_OK) {
        *error = moonshot_error_new_from_status (MOONSHOT_ERROR_IPC_ERROR,
                                                 status);
        return;
    }

    status = RpcMgmtIsServerListening (moonshot_binding_handle);

    if (status == RPC_S_NOT_LISTENING) {
        launch_server (error);

        if (*error != NULL)
            return;

        /* Allow 1 minute for the server to launch before we time out */
        for (i=0; i<600; i++) {
            Sleep (100); /* ms */

            status = RpcMgmtIsServerListening (moonshot_binding_handle);

            if (status == RPC_S_OK)
                return;

            if (status != RPC_S_NOT_LISTENING)
                break;
        }
    }

    if (status != RPC_S_OK)
        *error = moonshot_error_new_from_status (MOONSHOT_ERROR_IPC_ERROR,
                                                 status);
}

static void init_rpc (MoonshotError **error)
{
    static volatile LONG binding_init_flag = 2;

    /* Hack to avoid requiring a moonshot_init() function. Windows does not
     * provide any synchronisation primitives that can be statically init'ed,
     * but we can use its atomic variable access functions to achieve the same.
     * See: http://msdn.microsoft.com/en-us/library/ms684122%28v=vs.85%29.aspx
     */

    if (binding_init_flag == 0)
        return;

    if (InterlockedCompareExchange (&binding_init_flag, 1, 2) == 2) {
        bind_rpc (error);

        /* We'll handle all exceptions locally to avoid interfering with any
         * other RPC/other exception handling that goes on in the process,
         * and so we can store the problem in a MooshotError instead of
         * aborting.
         */
        rpc_set_global_exception_handler_enable (FALSE);

        if (InterlockedCompareExchange (&binding_init_flag, 0, 1) != 1) {
            /* This should never happen */
            fprintf (stderr, "moonshot: Internal synchronisation error");
        }
    } else {
        while (binding_init_flag != 0)
            Sleep (100); /* ms */
    }
}


int moonshot_get_identity (const char     *nai,
                           const char     *password,
                           const char     *service,
                           char          **nai_out,
                           char          **password_out,
                           char          **server_certificate_hash_out,
                           char          **ca_certificate_out,
                           char          **subject_name_constraint_out,
                           char          **subject_alt_name_constraint_out,
                           MoonshotError **error)
{
    int success = FALSE;
    RpcAsyncCall call;

    init_rpc (error);

    if (*error != NULL)
        return FALSE;

    rpc_async_call_init (&call);

    if (nai == NULL) nai = "";
    if (password == NULL) password = "";
    if (service == NULL) service = "";

    *nai_out = NULL;
    *password_out = NULL;
    *server_certificate_hash_out = NULL;
    *ca_certificate_out = NULL;
    *subject_name_constraint_out = NULL;
    *subject_alt_name_constraint_out = NULL;

    RPC_TRY_EXCEPT {
        moonshot_get_identity_rpc (&call,
                                   nai,
                                   password,
                                   service,
                                   nai_out,
                                   password_out,
                                   server_certificate_hash_out,
                                   ca_certificate_out,
                                   subject_name_constraint_out,
                                   subject_alt_name_constraint_out);

        success = rpc_async_call_complete_int (&call);
    }
    RPC_EXCEPT {
        *error = moonshot_error_new_from_status (MOONSHOT_ERROR_IPC_ERROR,
                                                 RPC_GET_EXCEPTION_CODE ());
    }
    RPC_END_EXCEPT

    if (*error != NULL)
        return FALSE;

    if (success == FALSE) {
        *error = moonshot_error_new (MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
                                     "No identity was returned by the Moonshot "
                                     "user interface.");
        return FALSE;
    }

    return TRUE;
}


int moonshot_get_default_identity (char          **nai_out,
                                   char          **password_out,
                                   char          **server_certificate_hash_out,
                                   char          **ca_certificate_out,
                                   char          **subject_name_constraint_out,
                                   char          **subject_alt_name_constraint_out,
                                   MoonshotError **error)
{
    int success = FALSE;
    RpcAsyncCall call;

    init_rpc (error);

    if (*error != NULL)
        return FALSE;

    rpc_async_call_init (&call);

    *nai_out = NULL;
    *password_out = NULL;
    *server_certificate_hash_out = NULL;
    *ca_certificate_out = NULL;
    *subject_name_constraint_out = NULL;
    *subject_alt_name_constraint_out = NULL;

    RPC_TRY_EXCEPT {
        moonshot_get_default_identity_rpc (&call,
                                           nai_out,
                                           password_out,
                                           server_certificate_hash_out,
                                           ca_certificate_out,
                                           subject_name_constraint_out,
                                           subject_alt_name_constraint_out);

        success = rpc_async_call_complete_int (&call);
    }
    RPC_EXCEPT {
        *error = moonshot_error_new_from_status (MOONSHOT_ERROR_IPC_ERROR,
                                                 RPC_GET_EXCEPTION_CODE ());
    }
    RPC_END_EXCEPT

    if (*error != NULL)
        return FALSE;

    if (success == FALSE) {
        *error = moonshot_error_new (MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
                                     "No identity was returned by the Moonshot "
                                     "user interface.");
        return FALSE;
    }

    return TRUE;
};

int moonshot_install_id_card (const char     *display_name,
                              const char     *user_name,
                              const char     *password,
                              const char     *realm,
                              char           *rules_patterns[],
                              int             rules_patterns_length,
                              char           *rules_always_confirm[],
                              int             rules_always_confirm_length,
                              char           *services[],
                              int             services_length,
                              const char     *ca_cert,
                              const char     *subject,
                              const char     *subject_alt,
                              const char     *server_cert,
                              int             force_flat_file_store,
                              MoonshotError **error)
{
    int success = FALSE;

    init_rpc (error);
    if (*error != NULL)
        return FALSE;

    if (user_name == NULL) user_name = "";
    if (password == NULL) password = "";
    if (realm == NULL) realm = "";
    if (ca_cert == NULL) ca_cert = "";
    if (subject == NULL) subject = "";
    if (subject_alt == NULL) subject_alt = "";
    if (server_cert == NULL) server_cert = "";

    RPC_TRY_EXCEPT {
        success = moonshot_install_id_card_rpc (display_name,
                                                user_name,
                                                password,
                                                realm,
                                                rules_patterns,
                                                rules_patterns_length,
                                                rules_always_confirm,
                                                rules_always_confirm_length,
                                                services,
                                                services_length,
                                                ca_cert,
                                                subject,
                                                subject_alt,
                                                server_cert,
                                                force_flat_file_store);
    }
    RPC_EXCEPT {
        *error = moonshot_error_new_from_status (MOONSHOT_ERROR_IPC_ERROR,
                                                 RPC_GET_EXCEPTION_CODE ());
    }
    RPC_END_EXCEPT
    return success;
}

BOOL WINAPI DllMain (HINSTANCE  hinst,
                     DWORD      reason,
                     void      *reserved)
{
    if (reason == DLL_PROCESS_DETACH) {
        /* Process exiting/DLL being unloaded. This is a good
         * opportunity to free the RPC binding.
         *
         * FIXME: we can't use the msrpc-mingw routine for this in case
         * it was already unloaded. I'd love to work out how to link
         * that library statically into libmoonshot-0.dll.
         */
        RpcBindingFree (&moonshot_binding_handle);
    }

    return TRUE;
}
