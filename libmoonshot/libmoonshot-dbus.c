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
#include <gio/gio.h>
#include <glib/gspawn.h>

#include "libmoonshot.h"
#include "libmoonshot-common.h"

/*30 days in ms*/
#define INFINITE_TIMEOUT 10*24*60*60*1000

#define MOONSHOT_DBUS_NAME "org.janet.Moonshot"
#define MOONSHOT_DBUS_PATH "/org/janet/moonshot"

/* Original comment was:
 * Note that ideally this library would not depend on GLib. This would be
 * possible using libdbus directly and running our own message loop while
 * waiting for calls.
 *
 * As of June 2018, it's unclear that using libdbus directly is a good idea.
 * Its documentation strongly encourages use of higher-level bindings.
 * I don't know yet whether we're in an exceptional situation.
 */

void moonshot_free (void *data)
{
  g_free (data);
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

static GDBusProxy *dbus_connect (MoonshotError **error)
{
  GDBusConnection *connection;
  GDBusProxy      *g_proxy;
  GError          *g_error = NULL;

  g_return_val_if_fail (*error == NULL, NULL);

  /* Check for moonshot server and start the service if possible. */

  /* TODO: is this still necessary with gdbus? */

  if (is_setid()) {
    *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                 "Cannot use IPC while setid");
    return NULL;
  }

  connection = g_bus_get_sync(G_BUS_TYPE_SESSION,
                              NULL, /* no cancellable */
                              &g_error);

  if (g_error != NULL) {
    *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                 "DBus error: %s",
                                 g_error->message);
    g_error_free (g_error);
    return NULL;
  }

  /* This will autostart the service if MOONSHOT_DBUS_NAME is a well-known name.
   * To inhibit that behavior, add G_DBUS_PROXY_FLAGS_DO_NOT_AUTO_START and/or
   * G_DBUS_PROXY_FLAGS_DO_NOT_AUTO_START_AT_CONSTRUCTION
   */
  g_proxy = g_dbus_proxy_new_sync(
      connection,
      G_DBUS_PROXY_FLAGS_NONE, /* TODO check flags */
      NULL, /* TODO define our expected interface */
      MOONSHOT_DBUS_NAME,
      MOONSHOT_DBUS_PATH,
      MOONSHOT_DBUS_NAME,
      NULL, /* no cancellable */
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

/**
 * Get a handle on our D-Bus proxy, instantiating one if needed
 *
 * This is used to share a D-Bus proxy throughout the process.
 * The first call instantiates a static D-Bus proxy. Subsequent
 * calls return references to the existing proxy.
 *
 * The reference count of the GDBusProxy is incremented by one
 * on each call. The caller must release its reference using
 * g_object_unref() when it is done.
 *
 * @param error (out) *error will be non-null on error
 * @return reference to a D-Bus proxy or null on error
 */
static GDBusProxy *get_dbus_proxy (MoonshotError **error)
{
  static GDBusProxy    *dbus_proxy = NULL;
  static GStaticMutex   init_lock = G_STATIC_MUTEX_INIT;

  g_static_mutex_lock (&init_lock);

  if (dbus_proxy == NULL) {
    /* Make sure GObject is initialised, in case we are the only user
     * of GObject in the process
     */
    g_type_init (); /* harmless but deprecated, may still be needed on CentOS 6 */
    dbus_proxy = dbus_connect (error);
  }

  /* Increment the reference count for the caller.
   *
   * Do this even if we just instantiated the GDBusProxy - the dbus_proxy local
   * variable is static, which we want the reference count to reflect. The
   * GDBusProxy should not be released when the caller is done or this whole
   * proxy sharing scheme is defeated! */
  if (dbus_proxy != NULL)
    g_object_ref (dbus_proxy);

  g_static_mutex_unlock (&init_lock);

  return dbus_proxy;
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
  GDBusProxy *dbus_proxy;
  gboolean    success;
  GVariant   *result = NULL;

  dbus_proxy = get_dbus_proxy (error);

  if (*error != NULL)
    return FALSE;

  g_return_val_if_fail (G_IS_DBUS_PROXY (dbus_proxy), FALSE);

  /* This method consumes the floating parameter GVariant.
   * Returns null if g_error is set. */
  result = g_dbus_proxy_call_sync(dbus_proxy,
                                  "GetIdentity",
                                  g_variant_new("(sss)",
                                                nai,
                                                password,
                                                service),
                                  G_DBUS_CALL_FLAGS_NONE,
                                  G_MAXINT, /* infinite timeout */
                                  NULL, /* no cancellable */
                                  &g_error);
  g_object_unref(dbus_proxy);

  if (g_error != NULL) {
    *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                 g_error->message);
    return FALSE;
  }

  /* unpack results - allocates space for strings */
  g_variant_get(result,
                "(ssssssb)",
                nai_out,
                password_out,
                server_certificate_hash_out,
                ca_certificate_out,
                subject_name_constraint_out,
                subject_alt_name_constraint_out,
                &success);
  g_variant_unref(result);

  if (success == FALSE) {
    *error = moonshot_error_new (MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
                                 "No identity was returned by the Moonshot "
                                 "user interface.");
    /* TODO do we need to free the strings? */
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
  GDBusProxy *dbus_proxy;
  gboolean    success = FALSE;
  GVariant   *result = NULL;

  dbus_proxy = get_dbus_proxy (error);

  if (*error != NULL)
    return FALSE;

  g_return_val_if_fail (G_IS_DBUS_PROXY (dbus_proxy), FALSE);

  result = g_dbus_proxy_call_sync(dbus_proxy,
                                  "GetDefaultIdentity",
                                  NULL, /* no parameters */
                                  G_DBUS_CALL_FLAGS_NONE,
                                  G_MAXINT, /* infinite timeout */
                                  NULL, /* No cancellable */
                                  &g_error);

  g_object_unref (dbus_proxy);

  if (g_error != NULL) {
    *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                 g_error->message);
    return FALSE;
  }

  /* unpack results - allocates space for strings */
  g_variant_get(result,
                "(ssssssb)",
                nai_out,
                password_out,
                server_certificate_hash_out,
                ca_certificate_out,
                subject_name_constraint_out,
                subject_alt_name_constraint_out,
                &success);
  g_variant_unref(result);

  if (success == FALSE) {
    *error = moonshot_error_new (MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
                                 "No identity was returned by the Moonshot "
                                 "user interface.");
    /* TODO do we need to free the strings? */
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
  GDBusProxy  *dbus_proxy;
  gboolean     success = FALSE;
  int          i;
  const char **rules_patterns_strv,
      **rules_always_confirm_strv,
      **services_strv;
  GVariant    *result = NULL;

  dbus_proxy = get_dbus_proxy (error);

  if (*error != NULL)
    return FALSE;

  g_return_val_if_fail (G_IS_DBUS_PROXY (dbus_proxy), FALSE);
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

  /* '^as' in the variant format string corresponds to the strv type */
  result = g_dbus_proxy_call_sync(dbus_proxy,
                                  "InstallIdCard",
                                  g_variant_new("(ssss^as^as^asssssi)",
                                                display_name,
                                                user_name,
                                                password,
                                                realm,
                                                rules_patterns_strv,
                                                rules_always_confirm_strv,
                                                services_strv,
                                                ca_cert,
                                                subject,
                                                subject_alt,
                                                server_cert,
                                                force_flat_file_store),
                                  G_DBUS_CALL_FLAGS_NONE,
                                  G_MAXINT, /* infinite timeout */
                                  NULL, /* no cancellable */
                                  &g_error);
  g_object_unref (dbus_proxy);
  g_free(rules_patterns_strv);
  g_free(rules_always_confirm_strv);
  g_free(services_strv);

  if (g_error != NULL) {
    *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                 g_error->message);
    return FALSE;
  }

  g_variant_get(result, "b", &success);
  g_variant_unref(result);

  return success;
}

int moonshot_confirm_ca_certificate (const char           *identity_name,
                                     const char           *realm,
                                     const unsigned char  *ca_hash,
                                     int                   hash_len,
                                     MoonshotError       **error)
{
  GError     *g_error = NULL;
  gboolean    success = FALSE;
  int         confirmed = 99; /* TODO is this for debugging or a meaningful value? */
  char        hash_str[65];
  GDBusProxy *dbus_proxy = get_dbus_proxy (error);
  int         out = 0;
  int         i;
  GVariant   *result = NULL;

  if (*error != NULL) {
    return FALSE;
  }

  g_return_val_if_fail (G_IS_DBUS_PROXY (dbus_proxy), FALSE);

  /* Convert hash byte array to string */
  out = 0;
  for (i = 0; i < hash_len; i++) {
    sprintf(&(hash_str[out]), "%02X", ca_hash[i]);
    out += 2;
  }

  result = g_dbus_proxy_call_sync(dbus_proxy,
                                  "ConfirmCaCertificate",
                                  g_variant_new("(sss)",
                                                identity_name,
                                                realm,
                                                hash_str),
                                  G_DBUS_CALL_FLAGS_NONE,
                                  G_MAXINT, /* infinite timeout */
                                  NULL, /* no cancellable */
                                  &g_error);
  g_object_unref (dbus_proxy);

  if (g_error != NULL) {
    *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                 g_error->message);
    return FALSE;
  }

  g_variant_get(result, "(ib)", &confirmed, &success);
  g_variant_unref(result);

  return confirmed;
}
