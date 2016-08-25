#include <string.h>
#include <openssl/bio.h>
#include <openssl/pem.h>

#include <stdio.h>

char* get_cert_valid_before(const unsigned char* buf, int len, char* datebuf, int datebuf_len)
{
    datebuf[0]='\0';

    unsigned char *p = (unsigned char*) buf;
    X509* x = d2i_X509(NULL, &p, len);
    if (x == NULL) {
        return "Error calling d2i_X509()!";
    }

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
