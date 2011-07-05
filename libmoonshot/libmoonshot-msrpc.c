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

#define MOONSHOT_ENDPOINT_NAME "/org/janet/Moonshot"
#define MOONSHOT_INSTALL_PATH_KEY "Software\\Moonshot"


static void launch_server (MoonshotError **error) {
    HKEY key = NULL;
    STARTUPINFO startup_info = { 0 };
    PROCESS_INFORMATION process_info = { 0 };
    LONG status;
    DWORD value_type;
    DWORD length;
    char exe_path[1024];

    status = RegOpenKeyEx (HKEY_LOCAL_MACHINE,
                           MOONSHOT_INSTALL_PATH_KEY,
                           0,
                           KEY_READ,
                           &key);

    if (status != 0) {
        *error = moonshot_error_new (MOONSHOT_ERROR_OS_ERROR,
                                     "Unable to read registry key HKLM\\%s",
                                     MOONSHOT_INSTALL_PATH_KEY);
        return;
    }

    length = 1023;
    status = RegQueryValueEx (key, NULL, NULL, &value_type, exe_path, &length);

    if (value_type != REG_SZ) {
        *error = moonshot_error_new (MOONSHOT_ERROR_OS_ERROR,
                                     "Value of registry key HKLM\\%s is invalid. "
                                     "Please set it to point to the location of "
                                     "moonshot.exe",
                                     MOONSHOT_INSTALL_PATH_KEY);
        return;
    }


    if (status != 0) {
        *error = moonshot_error_new (MOONSHOT_ERROR_OS_ERROR,
                                     "Unable to read value of registry key HKLM\\%s",
                                     MOONSHOT_INSTALL_PATH_KEY);
        return;
    }

    startup_info.cb = sizeof (startup_info);

    status = CreateProcess (exe_path, NULL,
                            NULL, NULL,
                            FALSE, DETACHED_PROCESS,
                            NULL, NULL,
                            &startup_info, &process_info);

    if (status != 0) {
        *error = moonshot_error_new (MOONSHOT_ERROR_UNABLE_TO_START_SERVICE,
                                     "Unable to spawn the moonshot server at '%s'",
                                     exe_path);
        return;
    }
}

/*static void dbus_call_complete_cb (DBusGProxy     *proxy,
                                   DBusGProxyCall *call_id,
                                   void           *user_data)
{
    GError *error = NULL;
    GSimpleAsyncResult   *token;
    MoonshotIdentityData *identity_data;
    gboolean              success;

    token = G_SIMPLE_ASYNC_RESULT (user_data);
    identity_data = moonshot_identity_data_new ();

    dbus_g_proxy_end_call (moonshot_dbus_proxy,
                           call_id,
                           &error,
                           G_TYPE_STRING, &identity_data->nai,
                           G_TYPE_STRING, &identity_data->password,
                           G_TYPE_STRING, &identity_data->server_certificate_hash,
                           G_TYPE_STRING, &identity_data->ca_certificate,
                           G_TYPE_STRING, &identity_data->subject_name_constraint,
                           G_TYPE_STRING, &identity_data->subject_alt_name_constraint,
                           G_TYPE_BOOLEAN, &success,
                           G_TYPE_INVALID);

    if (error != NULL) {
        g_simple_async_result_set_from_error (token, error);
    }
    else
    if (success == FALSE) {
        error = g_error_new (MOONSHOT_ERROR,
                             MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
                             "No matching identity was available");
        g_simple_async_result_set_from_error (token, error);
        g_error_free (error);
    }
    else {        
        g_simple_async_result_set_op_res_gpointer (token,
                                                   identity_data,
                                                   moonshot_identity_data_free);
    }

    g_simple_async_result_complete (token);
    g_object_unref (token);
}
*/

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
    int status;

    status = rpc_client_bind (&moonshot_binding_handle,
                              MOONSHOT_ENDPOINT_NAME,
                              RPC_PER_USER);

    printf ("RPC status: %i\n", status);

    /*DBusGProxyCall     *call_id;
    GSimpleAsyncResult *result; 
    GError *error = NULL;

    if (moonshot_dbus_proxy == NULL)
        moonshot_dbus_proxy = dbus_connect (&error);

    if (moonshot_dbus_proxy == NULL) {
        result = g_simple_async_result_new (NULL,
                                            callback,
                                            user_data,
                                            moonshot_get_identity);
        g_simple_async_result_set_from_error (result, error);
        g_simple_async_result_complete_in_idle (result);
        g_error_free (error);
        return;
    }

    g_return_if_fail (DBUS_IS_G_PROXY (moonshot_dbus_proxy));

    result = g_simple_async_result_new (NULL,
                                        callback,
                                        user_data,
                                        moonshot_get_identity);

    call_id = dbus_g_proxy_begin_call (moonshot_dbus_proxy,
                                       "GetIdentity",
                                       dbus_call_complete_cb,
                                       result, NULL,
                                       G_TYPE_STRING, nai,
                                       G_TYPE_STRING, password,
                                       G_TYPE_STRING, service);*/
}

/*gboolean moonshot_get_identity_finish (GAsyncResult  *result,
                                       char         **nai,
                                       char         **password,
                                       char         **server_certificate_hash,
                                       char         **ca_certificate,
                                       char         **subject_name_constraint,
                                       char         **subject_alt_name_constraint,
                                       GError       **error)
{
    MoonshotIdentityData *identity;

    g_return_val_if_fail (g_simple_async_result_is_valid (result,
                                                          NULL,
                                                          moonshot_get_identity),
                          FALSE);

    if (g_simple_async_result_propagate_error (G_SIMPLE_ASYNC_RESULT (result), error))
        return FALSE;

    identity = g_simple_async_result_get_op_res_gpointer (G_SIMPLE_ASYNC_RESULT (result));

    *nai = identity->nai;
    *password = identity->password;
    *server_certificate_hash = identity->server_certificate_hash;
    *ca_certificate = identity->ca_certificate;
    *subject_name_constraint = identity->subject_name_constraint;
    *subject_alt_name_constraint = identity->subject_alt_name_constraint;

    return TRUE;
}*/


int moonshot_get_default_identity (char          **nai_out,
                                   char          **password_out,
                                   char          **server_certificate_hash_out,
                                   char          **ca_certificate_out,
                                   char          **subject_name_constraint_out,
                                   char          **subject_alt_name_constraint_out,
                                   MoonshotError **error)
{
    int status;

    status = rpc_client_bind (&moonshot_binding_handle,
                              MOONSHOT_ENDPOINT_NAME,
                              RPC_PER_USER);

    printf ("RPC status: %i\n", status);
};
