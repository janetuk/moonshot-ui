#include <glib.h>

#include "libmoonshot.h"

void test_connect ()
{
    char *nai,
         *password,
         *server_certificate_hash,
         *ca_certificate,
         *subject_name_constraint,
         *subject_alt_name_constraint;
    int success;
    MoonshotError *error = NULL;

    success = moonshot_get_identity ("test",
                                     "test",
                                     "test",
                                     &nai,
                                     &password,
                                     &server_certificate_hash,
                                     &ca_certificate,
                                     &subject_name_constraint,
                                     &subject_alt_name_constraint,
                                     &error);

    if (success == 0) {
        g_print ("FAIL %s\n", error->message);
    } else {
        g_print ("PASS\n");
    }
}

/* More stuff to test:
 *   - server not available (dbus fail)
 *   - no identities available (moonshot fail)
 *   - valgrind
 */

int main (int argc, char *argv[])
{
    g_type_init ();
    g_test_init (&argc, &argv, NULL);

    g_test_add_func ("/basic/connect", test_connect);

    g_test_run ();
}
