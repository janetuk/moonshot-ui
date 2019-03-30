#include <glib.h>
#include <openssl/pem.h>
#include <stdio.h>
#include <time.h>
#include <glib/gprintf.h>

/* DISCLAIMER: This application does not free any memory on purpose.
 * As it is intended to be a oneshot application, which won't run for more than
 * a few seconds at most, freeing memory would make code uglier while memory
 * waste is not a big concern at all.
 */

static gchar* ca_cert_filename = NULL;
static gchar* server_cert_filename = FALSE;
static gboolean force = FALSE;
static gchar* username = NULL;
static gchar* realm = NULL;
static gchar* password = NULL;
static gchar** rules = NULL;

static GOptionEntry options[] = {
    {"ca-cert", 'c', 0, G_OPTION_ARG_FILENAME, &ca_cert_filename, "Path to the Trust Anchor's CA certificate", NULL},
    {"server-cert", 's', 0, G_OPTION_ARG_FILENAME, &server_cert_filename, "Path to the Trust Anchor's server certificate", NULL},
    {"selection-rule", 'r', 0, G_OPTION_ARG_STRING_ARRAY, &rules, "A selection rule. Can be specified multiple times", NULL},
    {"omit-expired", 'f', 0, G_OPTION_ARG_NONE, &force, "Generate the credential even if the certificate is expired", NULL},
    {NULL}
};

X509* read_pem(char* filename) {
    X509 *rv = NULL;
    FILE *fp = fopen(filename, "rt");
    if (fp != NULL) {
        rv = PEM_read_X509(fp, NULL, NULL, NULL);
        fclose(fp);
    }
    return rv;
}

gchar* get_cert_fingerprint(X509* cert) {
    gchar *rv = NULL;
    unsigned char fprint[EVP_MAX_MD_SIZE];
    unsigned int fprint_size;
    const EVP_MD *fprint_type = EVP_sha256();
    if (X509_digest(cert, fprint_type, fprint, &fprint_size)) {
        int i;
        rv = g_malloc0(fprint_size * 2 + 1);
        for (i=0; i<fprint_size; i++)
            g_snprintf(&rv[i*2], 3, "%02x", fprint[i]);
    }
    return rv;
}

gchar* get_cert_subject_name(X509 *cert) {
    gchar buffer[1024];
    int rv = X509_NAME_get_text_by_NID(X509_get_subject_name((X509 *) cert), NID_commonName, buffer, 1024);
    if (rv < 0)
        return NULL;
    return g_strdup(buffer);
}

gchar* get_cert_raw_pem(char *filename) {
    GError *error = NULL;
    gchar* ca_cert_pem = NULL;
    gchar **ca_cert_lines = NULL;
    gchar* last_line = NULL;

    // Get the PEM data as split lines
    if (!g_file_get_contents(filename, &ca_cert_pem, NULL, &error))
        return NULL;
    ca_cert_lines = g_strsplit(ca_cert_pem, "\n", 0);

    // remove the trailing ---- line
    do {
        int n_lines = g_strv_length(ca_cert_lines);
        last_line = ca_cert_lines[n_lines - 1];
        ca_cert_lines[n_lines - 1] = NULL;
    } while (last_line[0] != '-');

    // return all but the first line
    return g_strjoinv("\n", &ca_cert_lines[1]);
}

gboolean check_cert_date(X509 *cert) {
    time_t now = time(NULL);
    if (X509_cmp_time(X509_get_notAfter(cert), &now) < 0) {
        g_fprintf(stderr, "Error: the certificate is expired!\n");
        return FALSE;
    }
    if (X509_cmp_time(X509_get_notBefore(cert), &now) > 0) {
        g_fprintf(stderr, "Error: the certificate is not valid yet!\n");
        return FALSE;
    }
    return TRUE;
}

int main(int argc, char* argv[])
{
    GError *error = NULL;
    GOptionContext *context = NULL;
    X509 *cert = NULL;
    gchar* subject = NULL;
    gchar* fingerprint = NULL;
    gchar** rule = NULL;

    // parse arguments
    context = g_option_context_new("USERNAME REALM PASSWORD - Generate XML credentials for a specific IDP");
    g_option_context_add_main_entries(context, options, NULL);
    if (!g_option_context_parse (context, &argc, &argv, &error) || argc < 3) {
        if (error)
            g_fprintf(stderr, "error: %s\n", error->message);
        g_fprintf(stderr, "Run '%s --help' to see a full list of available arguments\n", argv[0]);
        exit (1);
    }

    username = argv[1];
    realm = argv[2];
    password = argv[3];

    // check if all the mandatory arguements have been provided
    if (username == NULL || password == NULL || realm == NULL) {
        g_fprintf(stderr, "You MUST provide a value for all the mandatory arguments.\n");
        g_fprintf(stderr, "%s", g_option_context_get_help(context, TRUE, NULL));
        return 1;
    }

    // Read server cert and compute the fingerprint
    if (server_cert_filename != NULL) {
        cert = read_pem(server_cert_filename);
        if (cert == NULL) {
            g_fprintf(stderr, "The indicated server certificate is not a PEM file.\n");
            return 1;
        }
        if (!check_cert_date(cert) && !force) {
            g_fprintf(stderr, "The indicated server certificate is expired.\n");
            return 1;
        }

        subject = get_cert_subject_name(cert);
        fingerprint = get_cert_fingerprint(cert);
    }

    // Read the CA certificate
    if (ca_cert_filename != NULL) {
        if (server_cert_filename == NULL) {
            g_fprintf(stderr, "You need to indicate a server certificate when using a CA certificate.\n");
            return 1;
        }
        cert = read_pem(ca_cert_filename);
        // check cert is indeed an X.509 PEM certificate
        if (cert == NULL) {
            g_fprintf(stderr, "The indicated CA certificate is not a PEM file.\n");
            return 1;
        }
        if (!check_cert_date(cert) && !force) {
            g_fprintf(stderr, "The indicated CA certificate is expired.\n");
            return 1;
        }
    }

    g_printf("<?xml version='1.0' encoding='UTF-8'?>\n");
    g_printf("<identities>\n");
    g_printf("    <identity>\n");
    g_printf("        <display-name>%s@%s</display-name>\n", username, realm);
    g_printf("        <user>%s</user>\n", username);
    g_printf("        <password>%s</password>\n", password);
    g_printf("        <realm>%s</realm>\n", realm);
    if (rules != NULL) {
        g_printf("        <selection-rules>\n");
        for (rule = rules; *rule != NULL; rule++) {
            g_printf("          <rule>\n");
            g_printf("            <pattern>%s</pattern>\n", *rule);
            g_printf("            <always-confirm>false</always-confirm>\n");
            g_printf("          </rule>\n");
        }
        g_printf("        </selection-rules>\n");
    }
    if (ca_cert_filename || server_cert_filename) {
        g_printf("        <trust-anchor>\n");
        if(ca_cert_filename) {
            g_printf("            <ca-cert>\n");
            g_printf("%s\n", get_cert_raw_pem(ca_cert_filename));;
            g_printf("            </ca-cert>\n");
            g_printf("            <subject>\n");
            g_printf("                %s\n", subject);
            g_printf("            </subject>\n");
        }
        else if (server_cert_filename) {
            g_printf("            <server-cert>\n");
            g_printf("                %s\n", fingerprint);
            g_printf("            </server-cert>\n");
        }
        g_printf("        </trust-anchor>\n");
    }
    g_printf("    </identity>\n");
    g_printf("</identities>\n");

    return 0;
}
