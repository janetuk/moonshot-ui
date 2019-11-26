//
//  X509Cert.m
//  Moonshot
//
//  Created by alex on 26/11/2019.
//  Copyright © 2019 Devsy. All rights reserved.
//

#import "X509Cert.h"
#import <CommonCrypto/CommonHMAC.h>
#include <openssl/pem.h>
#include <openssl/evp.h>

@implementation X509Cert

- (id) initWithHexString: (NSString*) hexdata {
    self = [super init];
    // hex -> bytes
    const char *hex_str = [hexdata UTF8String];
    int i = 0, cert_len = hexdata.length / 2;
    unsigned char hashdata[32];
    unsigned char *cert = malloc(cert_len + sizeof(int));
    unsigned char *p = cert;
    
    // hex -> bytes
    for (i = 0; i < cert_len; i++)
        sscanf(&hex_str[i*2], "%02X", &cert[i]);
        
    // SHA256 fingerprint
    CC_SHA256(cert, cert_len, hashdata);
    NSMutableString *hexfingerprint = [[NSMutableString alloc]init];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i)
        [hexfingerprint appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)hashdata[i]]];
    [self setHexfingerprint:hexfingerprint];
    
    // parse cert (needs to be on a temporary pointer "p" as it gets modified)
    X509* x = d2i_X509(NULL, &p, cert_len);
    if (x == NULL) {
        NSLog(@"Error parsing server certificate!");
        goto cleanup;
    }
        
    unsigned char cert_text[4096];
    BIO* out_bio = BIO_new(BIO_s_mem());
    if (X509_print(out_bio, x)) {
        int write = BIO_read(out_bio, cert_text, 4096);
        cert_text[write]='\0';
    }
    BIO_free(out_bio);
    [self setTextsummary:[NSString stringWithUTF8String:cert_text]];
cleanup:
    X509_free(x);
    free(cert);
    return self;
}

@end
