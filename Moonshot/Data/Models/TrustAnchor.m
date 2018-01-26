//
//  TrustAnchor.m
//  Moonshot
//
//  Created by Elena Jakjoska on 12/29/17.
//

#import "TrustAnchor.h"

@implementation TrustAnchor

- (id)initWithDictionaryObject:(NSDictionary *)trustAnchorDict {
    self = [super init];
    if(self){
        if([trustAnchorDict isKindOfClass:[NSDictionary class]]){
            self.serverCertificate = trustAnchorDict[@"server-cert"];
            self.caCertificate = trustAnchorDict[@"ca-cert"];
            self.subject = trustAnchorDict[@"subject"];
            self.subjectAlt = trustAnchorDict[@"subject-alt"];
        }
    }
    return self;
}

- (NSDictionary *)getDictionaryRepresentation {
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
    [resultDict setObject:self.serverCertificate forKey:@"server-cert"];
    [resultDict setObject:self.caCertificate forKey:@"ca-cert"];
    [resultDict setObject:self.subject forKey:@"subject"];
    [resultDict setObject:self.subjectAlt forKey:@"subject-alt"];
    return resultDict;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.serverCertificate = [decoder decodeObjectForKey:@"server-cert"];
        self.caCertificate = [decoder decodeObjectForKey:@"ca-cert"];
        self.subject = [decoder decodeObjectForKey:@"subject"];
        self.subjectAlt = [decoder decodeObjectForKey:@"subject-alt"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.serverCertificate forKey:@"server-cert"];
    [encoder encodeObject:self.caCertificate forKey:@"ca-cert"];
    [encoder encodeObject:self.subject forKey:@"subject"];
    [encoder encodeObject:self.subjectAlt forKey:@"subject-alt"];
}

@end
