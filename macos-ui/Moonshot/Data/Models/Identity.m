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
            self.has2fa = [identityDict[@"has2fa"] boolValue];
            self.secondFactor = identityDict[@"secondfactor"];
            self.trustAnchor = identityDict[@"trustAnchor"];
            self.servicesArray = identityDict[@"servicesArray"];
            self.selectionRules = identityDict[@"selectionRules"];
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
    [resultDict setObject:[NSNumber numberWithBool:self.has2fa] forKey:@"has2fa"];
    [resultDict setObject:self.secondFactor forKey:@"secondfactor"];
    [resultDict setObject:self.trustAnchor forKey:@"trustAnchor"];
    [resultDict setObject:self.servicesArray forKey:@"servicesArray"];
    [resultDict setObject:self.selectionRules forKey:@"selectionRules"];

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
        self.has2fa = [decoder decodeBoolForKey:@"has2fa"];
        self.secondFactor = [decoder decodeObjectForKey:@"secondFactor"];
        self.trustAnchor = [decoder decodeObjectForKey:@"trustAnchor"];
        self.servicesArray = [decoder decodeObjectForKey:@"servicesArray"];
        self.selectionRules = [decoder decodeObjectForKey:@"selectionRules"];
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
    [encoder encodeBool:self.has2fa forKey:@"has2fa"];
    [encoder encodeObject:self.secondFactor forKey:@"secondFactor"];
    [encoder encodeObject:self.servicesArray forKey:@"servicesArray"];
    [encoder encodeObject:self.selectionRules forKey:@"selectionRules"];
    [encoder encodeObject:self.trustAnchor forKey:@"trustAnchor"];
}

@end
