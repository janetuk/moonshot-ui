#include <string.h>
#include <openssl/bio.h>
#include <openssl/pem.h>
#include <openssl/evp.h>
#include <sys/types.h>
#include <keyutils.h>

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
    unsigned char *cert = malloc(cert_len + sizeof(int));
    unsigned char *p = cert;
    int result = 0;

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

#define SALT_SIZE 16
#define ITERATIONS 2000
long data_encrypt(unsigned char *plaintext, long plaintext_len,
                 unsigned char *passwd, unsigned char *ciphertext)
{
    EVP_CIPHER_CTX *ctx = NULL;
    int len;
    int ciphertext_len = -1;
    char keymat[12 + 32], tag[16], salt[SALT_SIZE], *key, *iv;

    if (!RAND_bytes(salt, SALT_SIZE))
        goto cleanup;

    if (!PKCS5_PBKDF2_HMAC(passwd, strlen(passwd), salt, SALT_SIZE, ITERATIONS,
                           EVP_sha1(), 32 + 12, keymat))
        goto cleanup;

    key = keymat;
    iv = keymat + 32;

    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new()))
        goto cleanup;

    /* Initialise the encryption operation. */
    if(1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL))
        goto cleanup;

    /* Initialise key and IV */
    if(1 != EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv))
        goto cleanup;

    /* Provide the message to be encrypted, and obtain the encrypted output.
     * EVP_EncryptUpdate can be called multiple times if necessary
     */
    if(1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len))
        goto cleanup;

    ciphertext_len = len;

    /* Finalise the encryption. Normally ciphertext bytes may be written at
     * this stage, but this does not occur in GCM mode
     */
    if(1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len))
        goto cleanup;
    ciphertext_len += len;

    /* Get the tag */
    if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, 16, tag))
        goto cleanup;

    /* Add salt */
    memcpy(ciphertext + ciphertext_len, salt, SALT_SIZE);
    ciphertext_len += SALT_SIZE;

    /* Add tag */
    memcpy(ciphertext + ciphertext_len, tag, 16);
    ciphertext_len += 16;

cleanup:
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}

/* We keep this function to support old password-based encrypted credential files.
   TODO: This function will eventually go out */
long data_decrypt_legacy(unsigned char *ciphertext, long ciphertext_len,
                         unsigned char *key, unsigned char *plaintext)
{
    EVP_CIPHER_CTX *ctx = NULL;
    int len;
    int plaintext_len;
    int ret = -1;
    char *tag = ciphertext + ciphertext_len - 16;
    ciphertext_len -= 16;

    char *iv = ciphertext + ciphertext_len - 12;
    ciphertext_len -= 12;

    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new()))
        goto cleanup;

    /* Initialise the decryption operation. */
    if(!EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL))
        goto cleanup;

    /* Initialise key and IV */
    if(!EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv)) goto cleanup;

    /* Provide the message to be decrypted, and obtain the plaintext output.
     * EVP_DecryptUpdate can be called multiple times if necessary
     */
    if(!EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len))
        goto cleanup;
    plaintext_len = len;

    /* Set expected tag value. Works in OpenSSL 1.0.1d and later */
    if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, tag))
        goto cleanup;

    /* Finalise the decryption. A positive return value indicates success,
     * anything else is a failure - the plaintext is not trustworthy.
     */
    ret = EVP_DecryptFinal_ex(ctx, plaintext + len, &len);

cleanup:
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    if(ret > 0)
    {
        /* Success */
        plaintext_len += len;
        return plaintext_len;
    }
    else
    {
        /* Verify failed */
        return -1;
    }
}

long data_decrypt_pbkdf2(unsigned char *ciphertext, long ciphertext_len,
                  unsigned char *passwd, unsigned char *plaintext)
{
    EVP_CIPHER_CTX *ctx = NULL;
    int len;
    int plaintext_len;
    int ret = -1;
    char keymat[32 + 12], *key, *iv, *salt, *tag;

    tag = ciphertext + ciphertext_len - 16;
    ciphertext_len -= 16;

    salt = ciphertext + ciphertext_len - SALT_SIZE;
    ciphertext_len -= SALT_SIZE;

    if (!PKCS5_PBKDF2_HMAC(passwd, strlen(passwd), salt, SALT_SIZE, ITERATIONS,
                           EVP_sha1(), 32 + 12, keymat))
        goto cleanup;

    key = keymat;
    iv = keymat + 32;

    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new()))
        goto cleanup;

    /* Initialise the decryption operation. */
    if(!EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL))
        goto cleanup;

    /* Initialise key and IV */
    if(!EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv))
        goto cleanup;

    /* Provide the message to be decrypted, and obtain the plaintext output.
     * EVP_DecryptUpdate can be called multiple times if necessary
     */
    if(!EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len))
        goto cleanup;
    plaintext_len = len;

    /* Set expected tag value. Works in OpenSSL 1.0.1d and later */
    if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, 16, tag))
        goto cleanup;

    /* Finalise the decryption. A positive return value indicates success,
     * anything else is a failure - the plaintext is not trustworthy.
     */
    ret = EVP_DecryptFinal_ex(ctx, plaintext + len, &len);

cleanup:
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    /* Success */
    if(ret > 0) {
        plaintext_len += len;
        return plaintext_len;
    }
    /* Verify failed */
    else {
        return -1;
    }
}

long data_decrypt(unsigned char *ciphertext, long ciphertext_len,
                  unsigned char *passwd, unsigned char *plaintext)
{
    long rc = data_decrypt_pbkdf2(ciphertext, ciphertext_len, passwd, plaintext);
    if (rc > 0)
        return rc;
    fprintf(stderr, "Trying legacy\n");
    return data_decrypt_legacy(ciphertext, ciphertext_len, passwd, plaintext);
}

long get_encryption_key(char* buffer, int buflen)
{
    key_serial_t key;
    long len = -1;
    key = request_key("user", "moonshot-ui", NULL, KEY_SPEC_SESSION_KEYRING);
    if (key == -1)
        return -1;
    return keyctl_read(key, buffer, buflen);
}
