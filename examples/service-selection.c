#include <glib.h>
#include "libmoonshot.h"

int main (int argc, char *argv[])
{
    MoonshotError *error;
    gboolean        success;

    char *nai,
         *password,
         *server_certificate_hash,
         *ca_certificate,
         *subject_name_constraint,
         *subject_alt_name_constraint;

    success = moonshot_get_identity ("user1@foo.baz",
                                     "",
                                     "",
                                     &nai,
                                     &password,
                                     &server_certificate_hash,
                                     &ca_certificate,
                                     &subject_name_constraint,
                                     &subject_alt_name_constraint,
                                     &error);

    if (success)
        g_debug ("Got id: %s %s\n", nai, password);

    moonshot_free (nai);
    moonshot_free (password);
    moonshot_free (server_certificate_hash);
    moonshot_free (ca_certificate);
    moonshot_free (subject_name_constraint);
    moonshot_free (subject_alt_name_constraint);
}
