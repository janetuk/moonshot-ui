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
    // hex -> bytes
    const char *hex_str = [hexdata UTF8String];
    int i = 0;
    long datalen = hexdata.length / 2;
    unsigned char *cert = malloc(datalen + sizeof(int));
    
    // hex -> bytes
    for (i = 0; i < datalen; i++)
        sscanf(&hex_str[i*2], "%02X", &cert[i]);
    
    NSData *data = [[NSData alloc] initWithBytes:cert length:datalen];
    return [self initWithDerData:data];
}

- (id) initWithB64String: (NSString*) b64data {
    // hex -> bytes
    NSString *b64clean = [[b64data stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSData *data = [[NSData alloc] initWithBase64EncodedString:b64clean options:0];
    return [self initWithDerData:data];
}

- (id) initWithDerData: (NSData*) data {
    self = [super init];
    unsigned char *cert = (unsigned char*)[data bytes];
    unsigned char *p = cert;
    unsigned char hashdata[32];
    int cert_len = (int) data.length;
    NSLog(@"DATA LENGTH IS %d", cert_len);
    
    // SHA256 fingerprint
    CC_SHA256(cert, cert_len, hashdata);
    NSMutableString *hexfingerprint = [[NSMutableString alloc]init];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i)
        [hexfingerprint appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)hashdata[i]]];
    [self setHexfingerprint:hexfingerprint];
    
    // parse cert (needs to be on a temporary pointer "p" as it gets modified)
    X509* x = d2i_X509(NULL, (const unsigned char**) &p, cert_len);
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
    [self setTextsummary:[NSString stringWithUTF8String:(const char*) cert_text]];
cleanup:
    X509_free(x);
    return self;
}
@end
