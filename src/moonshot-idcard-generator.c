#include <glib.h>
#include <openssl/pem.h>
#include <stdio.h>
#include <time.h>
#include <glib/gprintf.h>

/* DISCLAIMER: This application does not free any memory on purpose.
 * As it is intended to be a oneshot application, that won't run for more than
 * a few seconds at most, freeing memory would make code uglier while memory
 * waste is not a big concern at all.
 */

static gchar* cert_filename = NULL;
static gboolean is_server_cert = FALSE;
static gchar* username = NULL;
static gchar* password = NULL;
static gchar* realm = NULL;
static gboolean force = FALSE;


static GOptionEntry options[] = {
    {"cert", 'c', 0, G_OPTION_ARG_FILENAME, &cert_filename, "Path to the Trust Anchor certificate", NULL},
    {"is-server-cert", 's', 0, G_OPTION_ARG_NONE, &is_server_cert,
     "The Trust Anchor is a server certificate (if omitted it is assumed to be a CA certificate", NULL},
    {"realm", 'r', 0, G_OPTION_ARG_STRING, &realm, "Realm of the IDP", NULL},
    {"username", 'u', 0, G_OPTION_ARG_STRING, &username, "Username for the credential.", NULL},
    {"password", 'p', 0, G_OPTION_ARG_STRING, &password, "Password for the credential.", NULL},
    {"omit-expired", 'f', 0, G_OPTION_ARG_NONE, &force, "Generate the credential even if the certificate is expired", NULL},
    {NULL}
};

X509* get_pem(char* filename) {
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

    // Get the PEM data as split lines
    if (!g_file_get_contents(filename, &ca_cert_pem, NULL, &error))
        return NULL;
    ca_cert_lines = g_strsplit(ca_cert_pem, "\n", 0);
    ca_cert_lines[g_strv_length(ca_cert_lines) - 3] = NULL;
    return g_strjoinv("\n", &ca_cert_lines[1]);
}

gboolean check_cert_date(X509 *cert) {
    time_t now = time(NULL);
    if (X509_cmp_time(X509_get_notAfter(cert), &now) < 0) {
        printf("Error: the certificate is expired!\n");
        return FALSE;
    }
    if (X509_cmp_time(X509_get_notBefore(cert), &now) > 0) {
        printf("Error: the certificate is not valid yet!\n");
        return FALSE;
    }
    return TRUE;
}


int main(int argc, char* argv[])
{
    GError *error = NULL;
    GOptionContext *context = NULL;
    X509 *cert = NULL;

    // parse arguments
    context = g_option_context_new("- Generate XML credentials for a specific IDP");
    g_option_context_add_main_entries(context, options, NULL);
    if (!g_option_context_parse (context, &argc, &argv, &error)) {
        g_print("error: %s\n", error->message);
        g_print("Run '%s --help' to see a full list of available arguments\n", argv[0]);
        exit (1);
    }

    // check if all the mandatory arguements have been provided
    if (cert_filename == NULL || username == NULL || password == NULL || realm == NULL) {
        g_print("You MUST provide a value for all the mandatory arguments.\n");
        g_print("%s", g_option_context_get_help(context, TRUE, NULL));
        return 1;
    }

    // Read the certificate
    cert = get_pem(cert_filename);
    // check cert is indeed an X.509 PEM certificate
    if (cert == NULL) {
        g_print("The indicated certificate is not a PEM file.\n");
        return 1;
    }

    if (!check_cert_date(cert) && !force)
        return 1;


    g_printf("<?xml version='1.0' encoding='UTF-8'?>\n");
    g_printf("<identities>\n");
    g_printf("    <identity>\n");
    g_printf("        <display-name>%s@%s</display-name>\n", username, realm);
    g_printf("        <user>%s</user>\n", username);
    g_printf("        <password>%s</password>\n", password);
    g_printf("        <realm>%s</realm>\n", realm);
    g_printf("        <trust-anchor>\n");
    if (is_server_cert) {
        g_printf("            <server-cert>\n");
        g_printf("                %s\n", get_cert_fingerprint(cert));
        g_printf("            </server-cert>\n");
    }
    else {
        g_printf("            <ca-cert>\n");
        g_printf("%s\n", get_cert_raw_pem(cert_filename));;
        g_printf("            </ca-cert>\n");
        g_printf("            <subject>\n");
        g_printf("                %s\n", get_cert_subject_name(cert));
        g_printf("            </subject>\n");
    }
    g_printf("        </trust-anchor>\n");
    g_printf("    </identity>\n");
    g_printf("</identities>\n");

    return 0;
}
