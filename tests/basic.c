#include <glib.h>

#include "libmoonshot.h"

/* FIXME: Using XDG_HOME_DIR and a test runner, we could give
 * moonshot-ui a set of test identities and assert that they
 * are returned correctly
 */

gpointer test_func (gpointer data)
{
    MoonshotError **error = data;
    gboolean        success;

    char *nai,
         *password,
         *server_certificate_hash,
         *ca_certificate,
         *subject_name_constraint,
         *subject_alt_name_constraint;

    success = moonshot_get_default_identity (&nai,
                                             &password,
                                             &server_certificate_hash,
                                             &ca_certificate,
                                             &subject_name_constraint,
                                             &subject_alt_name_constraint,
                                             error);

    if (success) {
      success = (nai != NULL)
                && (password != NULL)
                && (server_certificate_hash != NULL)
                && (ca_certificate != NULL)
                && (subject_name_constraint != NULL)
                && (subject_alt_name_constraint != NULL);

      if (nai)
        moonshot_free (nai);
      if (password)
        moonshot_free (password);
      if (server_certificate_hash)
        moonshot_free (server_certificate_hash);
      if (ca_certificate)
        moonshot_free (ca_certificate);
      if (subject_name_constraint)
        moonshot_free (subject_name_constraint);
      if (subject_alt_name_constraint)
        moonshot_free (subject_alt_name_constraint);
    }

    return GINT_TO_POINTER (success);
}


void test_connect ()
{
    MoonshotError *error = NULL;
    gboolean       success;

    success = GPOINTER_TO_INT (test_func (&error));

    if (success)
        return;

    g_print ("FAIL: %s\n", error->message);
    g_assert_not_reached ();
}

void test_multithread ()
{
    const int N = 100;

    GThread       *thread[N];
    MoonshotError *error[N];
    gboolean       success[N];

    GError *g_error = NULL;
    int i;

    for (i=0; i<N; i++) {
        error[i] = NULL;
        thread[i] = g_thread_create (test_func,
                                     &error[i],
                                     TRUE,
                                     &g_error);
        g_assert_no_error (g_error);
    }

    for (i=0; i<N; i++)
        success[i] = GPOINTER_TO_INT (g_thread_join (thread[i]));

    for (i=0; i<N; i++) {
        if (! success[i]) {
            g_print ("FAIL[%i]: %s\n", i, error[i]->message);
            g_assert_not_reached ();
        }
    }
}

/* More stuff to test:
 *   - server not available (dbus fail)
 *   - no identities available (moonshot fail)
 *   - valgrind
 *   - mt
 */

int main (int argc, char *argv[])
{
    g_type_init ();
    g_test_init (&argc, &argv, NULL);

    g_test_add_func ("/basic/connect", test_connect);
    g_test_add_func ("/basic/multithread", test_multithread);

    g_test_run ();
}
