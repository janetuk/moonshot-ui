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

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <dbus/dbus-glib.h>
#include <dbus/dbus.h>
#include <dbus/dbus-glib-lowlevel.h>
#include <glib/gspawn.h>


#include "libmoonshot.h"
#include "libmoonshot-common.h"

/*30 days in ms*/
#define INFINITE_TIMEOUT 10*24*60*60*1000

#define MOONSHOT_DBUS_NAME "org.janet.Moonshot"
#define MOONSHOT_DBUS_PATH "/org/janet/moonshot"

/* This library is overly complicated currently due to the requirement
 * that it work on Debian Squeeze - this has GLib 2.24 which requires us
 * to use dbus-glib instead of GDBus. If/when this requirement is
 * dropped the DBus version of the library can be greatly simplified.
 */

/* Note that ideally this library would not depend on GLib. This would be
 * possible using libdbus directly and running our own message loop while
 * waiting for calls.
 */

void moonshot_free (void *data)
{
    g_free (data);
}
static char *moonshot_launch_argv[] = {
  MOONSHOT_LAUNCH_SCRIPT, NULL
};

static char *moonshot_dbus_launched_argv[] = {
  MOONSHOT_SERVER, "--dbus-launched", "--cli", NULL
};

static DBusGConnection *dbus_launch_moonshot()
{
    DBusGConnection *connection = NULL;
    GError *error = NULL;
    DBusError dbus_error;
    GPid child_pid;
    gint fd_stdin = -1, fd_stdout = -1;
    ssize_t addresslen;
    dbus_error_init(&dbus_error);
    char dbus_address[1024];
  
    if (g_spawn_async_with_pipes( NULL /*cwd*/,
				  moonshot_launch_argv, NULL /*environ*/,
				  0 /*flags*/, NULL /*setup*/, NULL,
				  &child_pid, &fd_stdin, &fd_stdout,
				  NULL /*stderr*/, NULL /*error*/) == 0 ) {
      return NULL;
    }

    addresslen = read( fd_stdout, dbus_address, sizeof dbus_address);
    close(fd_stdout);
    /* we require at least 2 octets of address because we trim the newline*/
    if (addresslen <= 1) {
    fail: dbus_error_free(&dbus_error);
      if (connection != NULL)
	dbus_g_connection_unref(connection);
      close(fd_stdin);
      g_spawn_close_pid(child_pid);
      return NULL;
    }
    dbus_address[addresslen-1] = '\0';

    connection = dbus_g_connection_open(dbus_address, &error);
    if (error) {
      g_error_free(error);
      goto fail;
    }
    if (!dbus_bus_register(dbus_g_connection_get_connection(connection),
			   &dbus_error))
      goto fail;
	return connection;
}

static int is_setid()
{
#ifdef HAVE_GETEUID
  if ((getuid() != geteuid()) || 
      (getgid() != getegid())) {
    return 1;
  }
#endif
  return 0;
}

static DBusGProxy *dbus_connect (MoonshotError **error, GPid *server_pid)
{
    DBusConnection  *dbconnection;
    DBusError        dbus_error;
    DBusGConnection *connection;
    DBusGProxy      *g_proxy;
    GError          *g_error = NULL;
    dbus_bool_t      name_has_owner;
    int              ad_hoc_dbus_session = FALSE;

    g_return_val_if_fail (*error == NULL, NULL);

    dbus_error_init (&dbus_error);

    /* Check for moonshot server and start the service if possible. We use
     * libdbus here because dbus-glib doesn't handle autostarting the service.
     * If/when we move to GDBus this code can become a one-liner.
     */

    if (is_setid()) {
        *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
	                             "Cannot use IPC while setid");
        return NULL;
    }
#ifdef IPC_DBUS_GLIB
    if (getenv("DISPLAY")==NULL) {
        connection = dbus_launch_moonshot();
        ad_hoc_dbus_session = TRUE;
        if (connection == NULL) {
            *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                         "Headless dbus launch failed");
            return NULL;
        }
    } else
#endif
    {
        connection = dbus_g_bus_get (DBUS_BUS_SESSION, &g_error);

        if (g_error_matches(g_error, DBUS_GERROR, DBUS_GERROR_NOT_SUPPORTED)) {
            /*Generally this means autolaunch failed because probably DISPLAY is unset*/
            connection = dbus_launch_moonshot();
            ad_hoc_dbus_session = TRUE;
            if (connection != NULL) {
                g_error_free(g_error);
                g_error = NULL;
            }
        }
        if (g_error != NULL) {
            *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                         "DBus error: %s",
                                         g_error->message);
            g_error_free (g_error);
            return NULL;
        }
    }


    dbconnection = dbus_g_connection_get_connection(connection);
    *server_pid = 0;

    /*
      For the CLI operation the server needs to be a child process of the
      application using libmoonshot, or it is not possible to get direct access
      to stdout and stdin.
      Spawn a CLI Moonshot server when:
        1) There is no DISPLAY environment variable.
        2) We are in control of stdin and stdout (ie. we are running in the
           foreground). Otherwise the Moonshot CLI UI cannot get interactive.
        3) There was a pre-existing DBUS session (we did not launched the
           session above). Otherwise, we would have problems with the keyring.
    */
    if (getenv("DISPLAY") == NULL && isatty(fileno(stdout))
          && isatty(fileno(stdin)) && !ad_hoc_dbus_session) {
        if (!g_spawn_async_with_pipes(NULL, moonshot_dbus_launched_argv, NULL,
                                      0, NULL, NULL, server_pid,
                                      NULL, NULL, NULL, NULL)) {
            *server_pid = 0;
        }
    }

    // Check whether there is a bus ownner.
    // If server_pid != 0, we wait until the service has become the ownwer (it might take some milliseconds)
    do {
        name_has_owner  = dbus_bus_name_has_owner (dbconnection,
                                                    MOONSHOT_DBUS_NAME,
                                                    &dbus_error);

        if (dbus_error_is_set (&dbus_error)) {
            *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                       "DBus error: %s",
                                       dbus_error.message);
            dbus_error_free (&dbus_error);
            return NULL;
        }
    } while (*server_pid != 0 && !name_has_owner);

    if (! name_has_owner) {
        dbus_bus_start_service_by_name (dbconnection,
                                        MOONSHOT_DBUS_NAME,
                                        0,
                                        NULL,
                                        &dbus_error);

        if (dbus_error_is_set (&dbus_error)) {
            if (strcmp (dbus_error.name + 27, "ServiceUnknown") == 0) {
                /* Missing .service file; the moonshot-ui install is broken */
                *error = moonshot_error_new (MOONSHOT_ERROR_UNABLE_TO_START_SERVICE,
                                             "The Moonshot service was not found. "
                                             "Please make sure that moonshot-ui is "
                                             "correctly installed.");
            } else {
                *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                             "DBus error: %s",
                                             dbus_error.message);
            }
            dbus_error_free (&dbus_error);
            return NULL;
        }
    }

    /* Now the service should be running */
    g_error = NULL;

    g_proxy = dbus_g_proxy_new_for_name_owner (connection,
                                               MOONSHOT_DBUS_NAME,
                                               MOONSHOT_DBUS_PATH,
                                               MOONSHOT_DBUS_NAME,
                                               &g_error);

    if (g_error != NULL) {
        *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                     "DBus error: %s",
                                     g_error->message);
        g_error_free (g_error);
        return NULL;
    }

    return g_proxy; 
}

static DBusGProxy *get_dbus_proxy (MoonshotError **error, GPid *server_pid)
{
    static DBusGProxy    *dbus_proxy = NULL;
    DBusGProxy           *rv = NULL;
    static GStaticMutex   init_lock = G_STATIC_MUTEX_INIT;

    g_static_mutex_lock (&init_lock);

    if (dbus_proxy == NULL) {
        /* Make sure GObject is initialised, in case we are the only user
         * of GObject in the process
         */
        g_type_init ();
        dbus_proxy = dbus_connect (error, server_pid);
    }

    if (dbus_proxy != NULL)
        g_object_ref (dbus_proxy);

    g_static_mutex_unlock (&init_lock);

    rv = dbus_proxy;
    // if a new server was created, the static dbus_proxy should not perdure
    if (server_pid != 0) {
        g_object_unref(dbus_proxy);
        dbus_proxy = NULL;
    }

    return rv;
}

/* Releases the resources allocated for the proxy
 * (including the DBUS server if it was not autostarted) */
static void release_dbus_proxy(DBusGProxy *dbus_proxy, GPid server_pid)
{
  g_object_unref (dbus_proxy);
  if (server_pid > 0) {
    kill(server_pid, SIGKILL);
    g_spawn_close_pid (server_pid);
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
    GError     *g_error = NULL;
    DBusGProxy *dbus_proxy;
    int         success;
    GPid server_pid = 0;
    dbus_proxy = get_dbus_proxy (error, &server_pid);

    if (*error != NULL)
        return FALSE;

    g_return_val_if_fail (DBUS_IS_G_PROXY (dbus_proxy), FALSE);

    dbus_g_proxy_call_with_timeout (dbus_proxy,
                       "GetIdentity",
				    INFINITE_TIMEOUT,
				    &g_error,
                       G_TYPE_STRING, nai,
                       G_TYPE_STRING, password,
                       G_TYPE_STRING, service,
                       G_TYPE_INVALID,
                       G_TYPE_STRING, nai_out,
                       G_TYPE_STRING, password_out,
                       G_TYPE_STRING, server_certificate_hash_out,
                       G_TYPE_STRING, ca_certificate_out,
                       G_TYPE_STRING, subject_name_constraint_out,
                       G_TYPE_STRING, subject_alt_name_constraint_out,
                       G_TYPE_BOOLEAN, &success,
                       G_TYPE_INVALID);

    release_dbus_proxy(dbus_proxy, server_pid);

    if (g_error != NULL) {
        *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                     g_error->message);
        return FALSE;
    }

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
    GError     *g_error = NULL;
    DBusGProxy *dbus_proxy;
    int         success = FALSE;

    GPid server_pid = 0;

    dbus_proxy = get_dbus_proxy (error, &server_pid);

    if (*error != NULL)
        return FALSE;

    g_return_val_if_fail (DBUS_IS_G_PROXY (dbus_proxy), FALSE);

    dbus_g_proxy_call_with_timeout (dbus_proxy,
                       "GetDefaultIdentity",
				    INFINITE_TIMEOUT,
                       &g_error,
                       G_TYPE_INVALID,
                       G_TYPE_STRING, nai_out,
                       G_TYPE_STRING, password_out,
                       G_TYPE_STRING, server_certificate_hash_out,
                       G_TYPE_STRING, ca_certificate_out,
                       G_TYPE_STRING, subject_name_constraint_out,
                       G_TYPE_STRING, subject_alt_name_constraint_out,
                       G_TYPE_BOOLEAN, &success,
                       G_TYPE_INVALID);

    release_dbus_proxy(dbus_proxy, server_pid);

    if (g_error != NULL) {
        *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                     g_error->message);
        return FALSE;
    }

    if (success == FALSE) {
        *error = moonshot_error_new (MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
                                     "No identity was returned by the Moonshot "
                                     "user interface.");
        return FALSE;
    }

    return TRUE;
}

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
                              int            force_flat_file_store,
                              MoonshotError **error)
{
    GError      *g_error = NULL;
    DBusGProxy  *dbus_proxy;
    int          success = FALSE;
    int          i;
    const char **rules_patterns_strv,
               **rules_always_confirm_strv,
               **services_strv;

    GPid server_pid = 0;

    dbus_proxy = get_dbus_proxy (error, &server_pid);

    if (*error != NULL)
        return FALSE;

    g_return_val_if_fail (DBUS_IS_G_PROXY (dbus_proxy), FALSE);
    g_return_val_if_fail (rules_patterns_length == rules_always_confirm_length, FALSE);

    /* Marshall array and struct parameters for DBus */
    rules_patterns_strv = g_malloc ((rules_patterns_length + 1) * sizeof (const char *));
    rules_always_confirm_strv = g_malloc ((rules_patterns_length + 1) * sizeof (const char *));
    services_strv = g_malloc ((services_length + 1) * sizeof (const char *));

    for (i = 0; i < rules_patterns_length; i ++) {
        rules_patterns_strv[i] = rules_patterns[i];
        rules_always_confirm_strv[i] = rules_always_confirm[i];
    }

    for (i = 0; i < services_length; i ++)
        services_strv[i] = services[i];

    rules_patterns_strv[rules_patterns_length] = NULL;
    rules_always_confirm_strv[rules_patterns_length] = NULL;
    services_strv[services_length] = NULL;

    dbus_g_proxy_call (dbus_proxy,
                       "InstallIdCard",
                       &g_error,
                       G_TYPE_STRING, display_name,
                       G_TYPE_STRING, user_name,
                       G_TYPE_STRING, password,
                       G_TYPE_STRING, realm,
                       G_TYPE_STRV, rules_patterns_strv,
                       G_TYPE_STRV, rules_always_confirm_strv,
                       G_TYPE_STRV, services_strv,
                       G_TYPE_STRING, ca_cert,
                       G_TYPE_STRING, subject,
                       G_TYPE_STRING, subject_alt,
                       G_TYPE_STRING, server_cert,
                       G_TYPE_INT, force_flat_file_store,
                       G_TYPE_INVALID,
                       G_TYPE_BOOLEAN, &success,
                       G_TYPE_INVALID);

    release_dbus_proxy(dbus_proxy, server_pid);
    g_free(rules_patterns_strv);
    g_free(rules_always_confirm_strv);
    g_free(services_strv);

    if (g_error != NULL) {
        *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                     g_error->message);
        return FALSE;
    }

    return success;
}

int moonshot_confirm_ca_certificate (const char           *identity_name,
                                     const char           *realm,
                                     const unsigned char  *ca_hash,
                                     int                   hash_len,
                                     MoonshotError       **error)
{
    GError     *g_error = NULL;
    int         success = 99;
    int         confirmed = 99;
    char        hash_str[65];
    GPid server_pid = 0;
    DBusGProxy *dbus_proxy = get_dbus_proxy (error, &server_pid);
    int         out = 0;
    int         i;

    if (*error != NULL) {
        return FALSE;
    }

    g_return_val_if_fail (DBUS_IS_G_PROXY (dbus_proxy), FALSE);

    /* Convert hash byte array to string */
    out = 0;
    for (i = 0; i < hash_len; i++) {
        sprintf(&(hash_str[out]), "%02X", ca_hash[i]);
        out += 2;
    }

    dbus_g_proxy_call_with_timeout (dbus_proxy,
                                    "ConfirmCaCertificate",
                                    INFINITE_TIMEOUT,
                                    &g_error,
                                    G_TYPE_STRING, identity_name,
                                    G_TYPE_STRING, realm,
                                    G_TYPE_STRING, hash_str,
                                    G_TYPE_INVALID,
                                    G_TYPE_INT,   &confirmed,
                                    G_TYPE_BOOLEAN, &success,
                                    G_TYPE_INVALID);

    release_dbus_proxy(dbus_proxy, server_pid);

    if (g_error != NULL) {
        *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                     g_error->message);
        return FALSE;
    }

    return (int) confirmed;
}
