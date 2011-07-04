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

#include <dbus/dbus-glib.h>
#include <dbus/dbus.h>

#include "libmoonshot.h"

#define MOONSHOT_DBUS_NAME "org.janet.Moonshot"
#define MOONSHOT_DBUS_PATH "/org/janet/moonshot"

/* This library is overly complicated currently due to the requirement
 * that it work on Debian Squeeze - this has GLib 2.24 which requires us
 * to use dbus-glib instead of GDBus. If/when this requirement is
 * dropped the DBus version of the library can be greatly simplified.
 */

typedef struct {
    char *nai;
    char *password;
    char *server_certificate_hash;
    char *ca_certificate;
    char *subject_name_constraint;
    char *subject_alt_name_constraint;
} MoonshotIdentityData;

static MoonshotIdentityData *moonshot_identity_data_new ()
{
    return g_slice_new (MoonshotIdentityData);
}

static void moonshot_identity_data_free (void *data)
{
    g_slice_free (MoonshotIdentityData, data);
}

static DBusGProxy *moonshot_dbus_proxy = NULL;

GQuark moonshot_error_quark (void)
{
    return g_quark_from_static_string ("moonshot-error-quark");
}

static DBusGProxy *dbus_connect (GError **g_error)
{
    DBusConnection  *connection;
    DBusError        dbus_error;
    DBusGConnection *g_connection;
    DBusGProxy      *g_proxy;
    dbus_bool_t      name_has_owner;

    g_return_val_if_fail (*g_error == NULL, NULL);

    dbus_error_init (&dbus_error);

    /* Check for moonshot server and start the service if possible. We use
     * libdbus here because dbus-glib doesn't handle autostarting the service.
     * If/when we move to GDBus this code can become a one-liner.
     */

    connection = dbus_bus_get (DBUS_BUS_SESSION, &dbus_error);

    if (dbus_error_is_set (&dbus_error)) {
        *g_error = g_error_new (MOONSHOT_ERROR,
                                MOONSHOT_ERROR_DBUS_ERROR,
                                "DBus error: %s",
                                dbus_error.message);
        dbus_error_free (&dbus_error);
        return NULL;
    }

    name_has_owner  = dbus_bus_name_has_owner (connection,
                                               MOONSHOT_DBUS_NAME,
                                               &dbus_error);

    if (dbus_error_is_set (&dbus_error)) {
        *g_error = g_error_new (MOONSHOT_ERROR,
                                MOONSHOT_ERROR_DBUS_ERROR,
                                "DBus error: %s",
                                dbus_error.message);

        dbus_error_free (&dbus_error);
        return NULL;
    }

    if (! name_has_owner) {
        dbus_bus_start_service_by_name (connection,
                                        MOONSHOT_DBUS_NAME,
                                        0,
                                        NULL,
                                        &dbus_error);

        if (dbus_error_is_set (&dbus_error)) {
            if (strcmp (dbus_error.name + 27, "ServiceUnknown") == 0) {
                /* Missing .service file; the moonshot-ui install is broken */
                *g_error = g_error_new (MOONSHOT_ERROR,
                                        MOONSHOT_ERROR_SERVICE_NOT_FOUND,
                                        "The Moonshot service was not found. "
                                        "Please make sure that moonshot-ui is "
                                        "correctly installed.");
            } else {
                *g_error = g_error_new (MOONSHOT_ERROR,
                                        MOONSHOT_ERROR_DBUS_ERROR,
                                        "DBus error: %s",
                                        dbus_error.message);
            }
            dbus_error_free (&dbus_error);
            return NULL;
        }
    }

    /* Now the service should be running */

    g_connection = dbus_g_bus_get (DBUS_BUS_SESSION, g_error);

    if (*g_error != NULL)
        return NULL;

    g_proxy = dbus_g_proxy_new_for_name_owner (g_connection,
                                               MOONSHOT_DBUS_NAME,
                                               MOONSHOT_DBUS_PATH,
                                               MOONSHOT_DBUS_NAME,
                                               g_error);

    return g_proxy; 
}

static void dbus_call_complete_cb (DBusGProxy     *proxy,
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

/**
 * moonshot_get_identity:
 * @cancellable: A #GCancellable, or %NULL.
 * @callback: A #GAsyncReadyCallback, which will be called when the
 *            operation completes, fails or is cancelled.
 * @user_data: Data to pass to @callback
 * @nai: Name and issuer constraint for the required identity, or %NULL.
 * @password: Password for the identity, or %NULL.
 * @service: Service constraint for the required identity, or %NULL.
 *
 * This function initiates a call to the Moonshot server to request an ID card.
 * The server will be activated if it is not already running. The user interface
 * will be displayed if there is more than one matching identity and the user 
 * will be asked to select one.
 *
 * When an identity has been selected, or the operation fails or is cancelled,
 * @callback will be run.
 *
 * Note that the actual IPC call may not be made until control returns to the
 * GLib main loop.
 */
void moonshot_get_identity (GCancellable        *cancellable,
                            GAsyncReadyCallback  callback,
                            gpointer             user_data,
                            const char          *nai,
                            const char          *password,
                            const char          *service)
{
    DBusGProxyCall     *call_id;
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
                                       G_TYPE_STRING, service);
}

/**
 * moonshot_get_identity_finish:
 * @result: The #GAsyncResult which was passed to your callback.
 * @nai: A pointer to a string which receives the name and issuer of the
 *       selected identity.
 * @password: A pointer to a string which receives the password.
 * @server_certificate_hash: Receives a hash of the identity server's
 *                           certificate, or %NULL.
 * @ca_certificate: The CA certificate, if @server_certificate_hash was %NULL.
 * @subject_name_constraint: Set if @ca_certificate is set, otherwise %NULL.
 * @subject_alt_name_constraint: Set if @ca_certificate is set, otherwise %NULL.
 * @error: Return location for an error, or %NULL.
 *
 * Gets the details of the identity card that was selected, if any.
 *
 * There are two types of trust anchor that may be returned. If
 * @server_certificate_hash is non-empty, the remaining parameters will be
 * empty. Otherwise, the @ca_certificate parameter and the subject name
 * constraints will be returned.
 *
 * Return value: %TRUE if an identity was successfully selected, %FALSE on
 *               failure.
 */
gboolean moonshot_get_identity_finish (GAsyncResult  *result,
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
}


    /**
     * Returns the default identity - most recently used.
     *
     * @param nai_out NAI stored in the ID card
     * @param password_out Password stored in the ID card
     *
     * @return true on success, false if no identities are stored
     */
