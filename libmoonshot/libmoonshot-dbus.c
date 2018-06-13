/* libmoonshot - Moonshot client library
 * Copyright (c) 2011-2018, JANET(UK)
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
 * Original (?) Author: Sam Thursfield <samthursfield@codethink.co.uk>
 */

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <gio/gio.h>
#include <glib/gspawn.h>

#include "libmoonshot.h"
#include "libmoonshot-common.h"

/**
 * The entry points to this module are the non-static functions at the end.
 *
 * These execute DBus commands against the org.janet.Moonshot service. This is done
 * over the DBus session bus, if available. If the session bus is unavailable, a private
 * stand-in for the session bus is launched so our methods can communicate with a
 * Moonshot instance. This bus is shut down when our procedure calls complete.
 *
 * This code is thread-safe from its external entry points. Internally, the thread
 * safety is ensured by the get_dbus_proxy() method. Using any of the internal functions
 * without going through get_dbus_proxy() will very likely break thread safety.
 *
 * Reasonable effort is made to avoid unnecessary DBus traffic. When using the
 * session bus, a single bus proxy is created and reused for subsequent procedure
 * calls. If we created our own bus, the bus and our proxy will be reused for any
 * concurrent calls, but will be shut down as soon as the last reference to the bus
 * proxy is released.
 *
 */
#define MOONSHOT_DBUS_NAME "org.janet.Moonshot"
#define MOONSHOT_DBUS_PATH "/org/janet/moonshot"
#define MOONSHOT_DBUS_ADDR_MAX_LEN 1024

/* Type for managing our own bus */
typedef struct {
  gchar *address; /* bus address */
  GPid pid; /* pid of the dbus-daemon */
  gint stdout;
} MoonshotDBusBus;

/* Struct for keeping a connection record */
typedef struct {
  GDBusConnection *connection;
  MoonshotDBusBus *bus; /* non-null only if we launched our own bus */
} MoonshotDBusConnection;

/* Struct for keeping a DBus proxy record */
typedef struct {
  GDBusProxy *dbus_proxy;
  MoonshotDBusConnection *connection;
} MoonshotDBusProxy;

void moonshot_free (void *data)
{
  g_free (data);
}

/**
 * Read and validate a DBus address from a file descriptor
 *
 * Expects a newline-terminated string with no extra characters.
 * Must be at most MOONSHOT_DBUS_ADDR_MAX_LEN charcaters, including
 * the newline.
 *
 * The return value must be freed with moonshot_free()
 *
 * @param fd file descriptor to read
 * @param error error return, set when return value is null
 * @return string containing the valid address or null on error
 */
static gchar *dbus_read_bus_addr(gint fd, MoonshotError **error)
{
  gchar dbus_addr[MOONSHOT_DBUS_ADDR_MAX_LEN];
  ssize_t dbus_addr_len = -1;
  gchar *result = NULL;

  /* Read the bus address from the fine descriptor. It should have a trailing '\n' */
  dbus_addr_len = read(fd, dbus_addr, sizeof(dbus_addr));
  if ((dbus_addr_len <= 1) || (dbus_addr[dbus_addr_len-1] != '\n')) {
    /* No \n or nothing left after the \n is removed, so we did not get an address.
     * This will also happen if dbus_addr[] was not long enough to contain the address. */
    *error = moonshot_error_new(MOONSHOT_ERROR_IPC_ERROR,
                               "Error reading bus address");
    return NULL;
  }

   /* terminate the string, this replaces the \n */
  dbus_addr[dbus_addr_len-1] = '\0';

  /* check that the address is valid */
  if (! g_dbus_is_address(dbus_addr)) {
    *error = moonshot_error_new(MOONSHOT_ERROR_IPC_ERROR,
                                "Invalid bus address: %s",
                                dbus_addr);
    return NULL;
  }

  result = g_strdup(dbus_addr); /* make a copy to send back to the caller */
  if (result == NULL) {
    /* this is unlikely to succeed if we just failed to dup a string, but at least try */
    *error = moonshot_error_new(MOONSHOT_ERROR_IPC_ERROR,
                                "Error copying bus address");
    return NULL;
  }

  return result;
}

/**
 * Terminate a dbus-proxy process and free our record
 *
 * @param bus record of the bus started by dbus_launch_bus()
 */
static void dbus_terminate_bus(MoonshotDBusBus *bus)
{
  g_return_if_fail(bus != NULL);

  close(bus->stdout);
  if (bus->pid > 0)
    kill(bus->pid, SIGTERM);
  g_spawn_close_pid(bus->pid);
  if (bus->address)
    g_free(bus->address);
  g_free(bus);
}

/**
 * Launch a private D-Bus session bus
 *
 * Used if we cannot find a session bus and need a stand-in
 *
 * Terminate the bus with dbus_terminate_bus()
 *
 * @param error (out) error, only set if return value is null
 * @return address of the new bus in D-Bus format, or null on error
 */
static MoonshotDBusBus *dbus_launch_bus(MoonshotError **error)
{
  MoonshotDBusBus *bus;
  GError *g_error = NULL;
  gchar *dbus_daemon_argv[] = {
    MOONSHOT_DBUS_DAEMON,
    "--nofork",
    "--print-address",
    "--nopidfile",
    "--config-file", MOONSHOT_DBUS_BUS_CONF,
    NULL
  };

  bus = g_new0(MoonshotDBusBus, 1);
  if (bus == NULL) {
    *error = moonshot_error_new(MOONSHOT_ERROR_IPC_ERROR,
                                "Error allocating bus record");
    return NULL;
  }

  /* Spawn the dbus-daemon process. */
  if (!g_spawn_async_with_pipes(NULL, /* working_directory */
                                dbus_daemon_argv,
                                NULL, /* envp, defaults to our own environment */
                                G_SPAWN_DEFAULT, /* flags */
                                NULL, /* child_setup */
                                NULL, /* user_data for child_setup */
                               &(bus->pid),
                                NULL, /* standard_input, defaults to /dev/null */
                               &(bus->stdout),
                                NULL, /* standard error, defaults to our own */
                                &g_error)) {
    *error = moonshot_error_new(MOONSHOT_ERROR_IPC_ERROR,
                                "Error spawning dbus-daemon: %s",
                                g_error->message);
    g_error_free(g_error);
    return NULL;
  }

  /* Read the bus address. Terminate the child process if this fails. */
  bus->address = dbus_read_bus_addr(bus->stdout, error);
  if (bus->address == NULL) {
    dbus_terminate_bus(bus);
    bus = NULL;
  }

  return bus;
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

/**
 * Does this connection use the session bus?
 *
 * True if it does. False if it uses a bus we started ourselves.
 */
static gboolean dbus_connection_uses_session_bus(MoonshotDBusConnection *conn)
{
  return (conn && (!conn->bus)); /* bus is null for the session bus */
}

/**
 * Disconnect and clean up a connection
 *
 * Terminates the connection's bus if we started it oureslves.
 */
static void dbus_disconnect(MoonshotDBusConnection *conn)
{
  g_return_if_fail(conn != NULL);

  if (conn->connection)
    g_dbus_connection_close_sync(conn->connection, NULL, NULL);

  if (conn->bus) {
    dbus_terminate_bus(conn->bus);
  }
  moonshot_free(conn);
}

/**
 * Open a connection to a DBus session bus, starting one if necessary
 *
 * @param error points to an error if return value is null
 * @return an open connection to the bus, or null on failure
 */
static MoonshotDBusConnection *dbus_connect(MoonshotError **error)
{
  MoonshotDBusConnection *conn = NULL;
  GError          *g_error = NULL;

  g_return_val_if_fail (*error == NULL, NULL);

  if (is_setid()) {
    *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                 "Cannot use IPC while setid");
    return NULL;
  }

  conn = g_new0(MoonshotDBusConnection, 1);
  if (conn == NULL) {
    *error = moonshot_error_new(MOONSHOT_ERROR_IPC_ERROR,
                                "Error allocating DBus connection");
    return NULL;
  }

  /* Try to open an existing session bus. */
  conn->connection = g_bus_get_sync(G_BUS_TYPE_SESSION,
                                    NULL, /* no cancellable */
                                   &g_error);

  if (conn->connection == NULL) {
    /* That failed. Try to start our own session bus and connect. */
    g_error_free(g_error); /* ignore that error */
    g_error = NULL;

    conn->bus = dbus_launch_bus(error);
    if (conn->bus == NULL) {
      g_free(conn);
      return NULL;
    }

    /* Bus should be running, try to connect. */
    conn->connection = g_dbus_connection_new_for_address_sync(
      conn->bus->address,
      G_DBUS_CONNECTION_FLAGS_AUTHENTICATION_CLIENT
        | G_DBUS_CONNECTION_FLAGS_MESSAGE_BUS_CONNECTION,
      NULL, /* observer */
      NULL, /* cancellable */
     &g_error);

    if (conn->connection == NULL) {
      *error = moonshot_error_new(MOONSHOT_ERROR_IPC_ERROR,
                                  "DBus error connecting to bus: %s",
                                  g_error->message);
      g_error_free(g_error);
      dbus_terminate_bus(conn->bus);
      g_free(conn);
      return NULL;
    }
  }

  /* we now have an open connection to a bus */
  return conn;
}

/**
 * Create a bus proxy for the moonshot service using an open connection
 *
 * @param connection open connection to the bus
 * @param error error set when return value is null
 * @return bus proxy or null on error
 */
static GDBusProxy *dbus_create_proxy(MoonshotDBusConnection *conn, MoonshotError **error)
{
  GDBusProxy *g_proxy;
  GError     *g_error = NULL;

  /* This will autostart the service if it is not already running. */
  g_proxy = g_dbus_proxy_new_sync(
      conn->connection,
      G_DBUS_PROXY_FLAGS_NONE,
      NULL, /* expected interface */
      MOONSHOT_DBUS_NAME,
      MOONSHOT_DBUS_PATH,
      MOONSHOT_DBUS_NAME,
      NULL, /* no cancellable */
      &g_error);

  if (g_error != NULL) {
    *error = moonshot_error_new (MOONSHOT_ERROR_IPC_ERROR,
                                 "DBus error creating proxy: %s",
                                 g_error->message);
    g_error_free (g_error);
    return NULL;
  }

  return g_proxy;
}

/**
 * Callback to disconnect from the DBus when our bus proxy is finalized
 *
 * @param data Pointer to MoonshotDBusProxy instance whose
 */
static void dbus_proxy_notify(gpointer data, GObject *where_the_object_was)
{
  MoonshotDBusProxy *proxy = (MoonshotDBusProxy *) data;

  /* Ensure we were called with the right object! */
  g_return_if_fail(proxy->dbus_proxy ==  where_the_object_was);

  dbus_disconnect(proxy->connection);
  proxy->dbus_proxy = NULL;
  proxy->connection = NULL;
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
 * MT-safe
 *
 * @param error (out) *error will be non-null on error
 * @return reference to a D-Bus proxy or null on error
 */
static GDBusProxy *get_dbus_proxy (MoonshotError **error)
{
  static GStaticMutex init_lock = G_STATIC_MUTEX_INIT;
  static MoonshotDBusProxy shared_proxy = {NULL, NULL};

  /* Mutex protects access to shared_proxy */
  g_static_mutex_lock (&init_lock);

  /* do we already have a live proxy? */
  if (shared_proxy.dbus_proxy != NULL) {
    g_object_ref(shared_proxy.dbus_proxy);
    goto cleanup;
  }

  /* get a connection if we don't already have one */
  if (shared_proxy.connection == NULL) {
    g_type_init (); /* harmless but deprecated, may still be needed on CentOS 6 */

    shared_proxy.connection = dbus_connect(error); /* sets error if return value is null */
    if (shared_proxy.connection == NULL)
      goto cleanup;
  }

  /* we have a connection, create a proxy */
  shared_proxy.dbus_proxy = dbus_create_proxy(shared_proxy.connection, error); /* sets error if return value is null */
  if (shared_proxy.dbus_proxy == NULL)
    goto cleanup;

  /* set a weak ref so we get a callback when the object is freed */
  g_object_weak_ref(G_OBJECT(shared_proxy.dbus_proxy),
                    dbus_proxy_notify,
                    &shared_proxy);

  /* If we are on the session bus, hold a reference for reuse on later calls. */
  if (dbus_connection_uses_session_bus(shared_proxy.connection))
    g_object_ref(shared_proxy.dbus_proxy);

cleanup:
  g_static_mutex_unlock (&init_lock);
  return shared_proxy.dbus_proxy;
}

/* Output strings are always set to non-null, even if no identity is returned.
 * These must be freed with moonshot_free() by the caller.
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
    /* On failure, the output strings are non-null (pointing to "" strings). The
     * caller will free them. */
    *error = moonshot_error_new (MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
                                 "No identity was returned by the Moonshot "
                                 "user interface.");
    return FALSE;
  }

  return TRUE;
}

/* Output strings are always set to non-null, even if no identity is returned.
 * These must be freed with moonshot_free() by the caller.
 */
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
    g_error_free(g_error);
    /* On failure, the output strings are non-null (pointing to "" strings). The
     * caller will free them. */
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
    g_error_free(g_error);
    return FALSE;
  }

  g_variant_get(result, "(b)", &success);
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
  int         confirmed = 0;
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
    g_error_free(g_error);
    return FALSE;
  }

  g_variant_get(result, "(ib)", &confirmed, &success);
  g_variant_unref(result);

  return confirmed;
}
