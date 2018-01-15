//
//  Identity.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/20/16.
//

#import "Identity.h"

@implementation Identity

- (id)initWithDictionaryObject:(NSDictionary *)identityDict {
    self = [super init];
    if(self){
        if([identityDict isKindOfClass:[NSDictionary class]]){
            self.identityId = identityDict[@"identityId"];
            self.displayName = identityDict[@"displayName"];
            self.username = identityDict[@"username"];
            self.password = identityDict[@"password"];
            self.realm = identityDict[@"realm"];
            self.dateAdded = identityDict[@"dateAdded"];
            self.passwordRemembered = [identityDict[@"passwordRemembered"] boolValue];
            self.caCertificate = [identityDict[@"caCertificate"] boolValue];
            self.trustAnchor = [identityDict[@"trustAnchor"] boolValue];
            self.serverCertificate = [identityDict[@"serverCertificate"] boolValue];
            self.servicesArray = identityDict[@"servicesArray"];
            self.selectionRulesArray = identityDict[@"selectionRulesArray"];
            self.selectionRules = [[SelectionRules alloc] initWithDictionaryObject:identityDict[@"selectionRules"]];
            self.trustAnchorArray = identityDict[@"trustAnchorArray"];
        }
    }
    return self;
}

- (NSDictionary *)getDictionaryRepresentation {
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
    [resultDict setObject:self.identityId forKey:@"identityId"];
    [resultDict setObject:self.displayName forKey:@"displayName"];
    [resultDict setObject:self.username forKey:@"username"];
    [resultDict setObject:self.password forKey:@"password"];
    [resultDict setObject:self.realm forKey:@"realm"];
    [resultDict setObject:self.dateAdded forKey:@"dateAdded"];
    [resultDict setObject:[NSNumber numberWithBool:self.passwordRemembered] forKey:@"passwordRemembered"];
    [resultDict setObject:[NSNumber numberWithBool:self.caCertificate] forKey:@"caCertificate"];
    [resultDict setObject:[NSNumber numberWithBool:self.trustAnchor] forKey:@"trustAnchor"];
    [resultDict setObject:[NSNumber numberWithBool:self.serverCertificate] forKey:@"serverCertificate"];
    [resultDict setObject:self.servicesArray forKey:@"servicesArray"];
    [resultDict setObject:self.selectionRulesArray forKey:@"selectionRulesArray"];
    [resultDict setObject:self.selectionRules forKey:@"selectionRules"];
    [resultDict setObject:self.trustAnchorArray forKey:@"trustAnchorArray"];

    return resultDict;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        self.identityId = [decoder decodeObjectForKey:@"identityId"];
        self.displayName = [decoder decodeObjectForKey:@"displayName"];
        self.username = [decoder decodeObjectForKey:@"username"];
        self.password = [decoder decodeObjectForKey:@"password"];
        self.realm = [decoder decodeObjectForKey:@"realm"];
        self.dateAdded = [decoder decodeObjectForKey:@"dateAdded"];
        self.passwordRemembered = [decoder decodeBoolForKey:@"passwordRemembered"];
        self.caCertificate = [decoder decodeBoolForKey:@"caCertificate"];
        self.trustAnchor = [decoder decodeBoolForKey:@"trustAnchor"];
        self.serverCertificate = [decoder decodeBoolForKey:@"serverCertificate"];
        self.servicesArray = [decoder decodeObjectForKey:@"servicesArray"];
        self.selectionRulesArray = [decoder decodeObjectForKey:@"selectionRulesArray"];
        self.selectionRules = [decoder decodeObjectForKey:@"selectionRules"];
        self.trustAnchorArray = [decoder decodeObjectForKey:@"trustAnchorArray"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.identityId forKey:@"identityId"];
    [encoder encodeObject:self.displayName forKey:@"displayName"];
    [encoder encodeObject:self.username forKey:@"username"];
    [encoder encodeObject:self.password forKey:@"password"];
    [encoder encodeObject:self.realm forKey:@"realm"];
    [encoder encodeObject:self.dateAdded forKey:@"dateAdded"];
    [encoder encodeBool:self.passwordRemembered forKey:@"passwordRemembered"];
    [encoder encodeBool:self.caCertificate forKey:@"caCertificate"];
    [encoder encodeBool:self.trustAnchor forKey:@"trustAnchor"];
    [encoder encodeBool:self.serverCertificate forKey:@"serverCertificate"];
    [encoder encodeObject:self.servicesArray forKey:@"servicesArray"];
    [encoder encodeObject:self.selectionRulesArray forKey:@"selectionRulesArray"];
    [encoder encodeObject:self.selectionRules forKey:@"selectionRules"];
    [encoder encodeObject:self.trustAnchorArray forKey:@"trustAnchorArray"];
}

@end
