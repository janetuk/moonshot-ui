#include <libmoonshot.h>

#include <stdio.h>

int main (int    argc,
          char **argv[])
{
    MoonshotError *error = NULL;
    int success;

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
                                             &error);

    if (success) {
        printf ("Got identity: %s %s %s\n", nai, password, server_certificate_hash);
        return 0;
    } else {
        printf ("Error: %s\n", error->message);
        return 1;
    }
}
