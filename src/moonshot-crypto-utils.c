#include <string.h>
#include <openssl/bio.h>
#include <openssl/pem.h>

#include <stdio.h>

const char* get_cert_valid_before(const unsigned char* buf, int len, char* datebuf, int datebuf_len)
{
    datebuf[0]='\0';

    X509* x = d2i_X509(NULL, &buf, len);
    if (x == NULL)
        return "Error calling d2i_X509()!";

    BIO* out_bio = BIO_new(BIO_s_mem());
    ASN1_TIME* time = X509_get_notAfter(x);

    if (ASN1_TIME_print(out_bio, time)) {
        int write = BIO_read(out_bio, datebuf, datebuf_len - 1);
        datebuf[write]='\0';
    }

    datebuf[datebuf_len - 1] = '\0';
    BIO_free(out_bio);
    X509_free(x);
    return "";
}

int get_cert_is_expired_now(const unsigned char* buf, int len)
{
    int pday, psec, rv;

    X509* x = d2i_X509(NULL, &buf, len);
    if (x == NULL)
        return 0;

    ASN1_TIME* time = X509_get_notAfter(x);
    rv = X509_cmp_current_time(time);
    X509_free(x);
    return rv < 0;
}

int sha256(unsigned char *bytes, int len, unsigned char *hash_str)
{
    unsigned int hash_len = 0;
    unsigned char hash[32];
    int result = -1, i = 0;
#if OPENSSL_VERSION_NUMBER >= 0x10100000L
    EVP_MD_CTX *ctx = EVP_MD_CTX_new();
#else
    EVP_MD_CTX ctx_internal;
    EVP_MD_CTX_init(&ctx_internal);
    EVP_MD_CTX *ctx = &ctx_internal;
#endif
    if (!EVP_DigestInit_ex(ctx, EVP_sha256(), NULL)) {
        fprintf(stderr, "sha256(init_sec_context.c): EVP_DigestInit_ex failed: %s",
                ERR_error_string(ERR_get_error(), NULL));
        goto cleanup;
    }
    if (!EVP_DigestUpdate(ctx, bytes, len)) {
        fprintf(stderr, "sha256(init_sec_context.c): EVP_DigestUpdate failed: %s",
                ERR_error_string(ERR_get_error(), NULL));
        goto cleanup;
    }
    if (!EVP_DigestFinal(ctx, hash, &hash_len)) {
        fprintf(stderr, "sha256(init_sec_context.c): EVP_DigestFinal failed: %s",
                ERR_error_string(ERR_get_error(), NULL));
        goto cleanup;
    }
    result = hash_len;

cleanup:
#if OPENSSL_VERSION_NUMBER >= 0x10100000L
    EVP_MD_CTX_free(ctx);
#endif

    /* Convert hash byte array to string */
    for (i = 0; i < 32; i++)
        sprintf(&(hash_str[i * 2]), "%02X", hash[i]);

  return result;
}

void x509_to_text(X509 *cert,
                  unsigned char* cert_text, int cert_text_len)
{
    BIO* out_bio = BIO_new(BIO_s_mem());
    if (X509_print(out_bio, cert)) {
        int write = BIO_read(out_bio, cert_text, cert_text_len - 1);
        cert_text[write]='\0';
    }
    BIO_free(out_bio);
}

int parse_hex_certificate(const unsigned char* hex_str,
                          unsigned char *sha256_hex_fingerprint,
                          unsigned char* cert_text, int cert_text_len)
{
    // hex -> bytes
    int i = 0, cert_len = strlen(hex_str) / 2;
    unsigned char *cert = malloc(cert_len);
    unsigned char *p = cert;
    int result = 0;
    X509_NAME *name = NULL;

    // make sure we initialise buffers
    sha256_hex_fingerprint[0] = cert_text[0] = '\0';

    // hex -> bytes
    for (i = 0; i < cert_len; i++)
        sscanf(&hex_str[i*2], "%02X", &cert[i]);

    // SHA256 fingerprint
    if (sha256(cert, cert_len, sha256_hex_fingerprint) != 32)
        goto cleanup;

    // parse cert (needs to be on a temporary pointer "p" as it gets modified)
    X509* x = d2i_X509(NULL, &p, cert_len);
    if (x == NULL) {
        fprintf(stderr, "Error parsing server certificate!\n");
        goto cleanup;
    }

    x509_to_text(x, cert_text, cert_text_len);
    result = 1;
cleanup:
    X509_free(x);
    free(cert);
    return result;
}

int parse_der_certificate(const unsigned char* der, int der_len,
                          unsigned char* cert_text, int cert_text_len)
{
    // parse cert (needs to be on a temporary pointer "p" as it gets modified)
    X509* x = d2i_X509(NULL, &der, der_len);
    if (x == NULL) {
        fprintf(stderr, "Error parsing server certificate!\n");
        return 0;
    }
    x509_to_text(x, cert_text, cert_text_len);
    X509_free(x);
    return 1;
}
