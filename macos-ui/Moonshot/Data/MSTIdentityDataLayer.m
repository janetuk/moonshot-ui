//
//  MSTIdentityDataLayer.m
//  Moonshot
//
//  Created by Ivan Aleksovski on 11/11/16.
//

#import "MSTIdentityDataLayer.h"
#import "MSTKeychainHelper.h"
#import "MSTConstants.h"

@implementation MSTIdentityDataLayer

#pragma mark - Singletone management

static MSTIdentityDataLayer *sharedInstance;

+ (MSTIdentityDataLayer *)sharedInstance {
    @synchronized(self)
    {
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            sharedInstance = [[self alloc] init];
        });
        return sharedInstance;
    }
}

- (void)getAllIdentitiesWithBlock:(void (^)(NSArray <Identity *> *items))block {
	__weak __typeof__(self) weakSelf = self;

	[self getAllRealIdentitiesWithBlock:^(NSArray<Identity *> *items) {
		NSMutableArray *mutableItems = [items mutableCopy];

		if (items.count == 0) {
			//Add the "no identity"
			Identity *noIdentity = [[Identity alloc] init];
			noIdentity.identityId = MST_NO_IDENTITY;
			noIdentity.displayName = NSLocalizedString(@"No_Identity", @"");
			noIdentity.username = @"";
			noIdentity.realm = @"";
			noIdentity.passwordRemembered = YES;
			noIdentity.trustAnchor = nil;
			noIdentity.has2fa = 0;
			noIdentity.servicesArray = [[NSMutableArray alloc] init];
			[mutableItems addObject:noIdentity];
			[weakSelf addNewIdentity:noIdentity withBlock:nil];
		}
		block(mutableItems);
	}];
}

- (void)getAllRealIdentitiesWithBlock:(void (^)(NSArray <Identity *> *items))block {
    NSMutableArray *items = [NSMutableArray array];
    if ([MSTKeychainHelper unarchiveObjectForKey:MST_IDENTITIES]) {
        items = [MSTKeychainHelper unarchiveObjectForKey:MST_IDENTITIES];
    }
    block(items);
}

- (void)addNewIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block {
    __block NSMutableArray *newIdentityArray = [[NSMutableArray alloc] init];
    [self getAllRealIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        newIdentityArray = [items mutableCopy];
    }];
    [newIdentityArray addObject:newIdentity];
    [self saveObject:newIdentityArray forKey:MST_IDENTITIES];
	if (block) {
		block(nil);
	}
}

- (void)editIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block {
    [self getAllRealIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        __weak __typeof__(self) weakSelf = self;
        NSMutableArray *newIdentityArray = [[NSMutableArray arrayWithArray:items] mutableCopy];
        for (int i = 0; i < [newIdentityArray count]; i++) {
			Identity *identity = newIdentityArray[i];
            if ([identity.identityId isEqualToString:newIdentity.identityId]) {
                [newIdentityArray replaceObjectAtIndex:i withObject:newIdentity];
                [weakSelf saveObject:newIdentityArray forKey:MST_IDENTITIES];
                break;
            }
        }
		if (block) {
			block(nil);
		}
    }];
}

- (void)removeIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block {
	if ([newIdentity.identityId isEqualToString:MST_NO_IDENTITY]) {
		NSError *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:9999 userInfo:@{}];
		block(error);
		return;
	}
    [self getAllRealIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        NSMutableArray *newIdentityArray = [[NSMutableArray arrayWithArray:items] mutableCopy];
        __weak __typeof__(self) weakSelf = self;
        if ([newIdentityArray count] > 0) {
            for (int i = 0; i < [newIdentityArray count]; i++) {
				Identity *identity = newIdentityArray[i];
                if ([identity.identityId isEqualToString:newIdentity.identityId]) {
                    [newIdentityArray removeObjectAtIndex:i];
                    [weakSelf saveObject:newIdentityArray forKey:MST_IDENTITIES];
                    break;
                }
            }
        }
		NSError *error;
		block(error);
    }];
}

- (BOOL)saveObject:(id)object forKey:(NSString *)defaultsKey {
    return [MSTKeychainHelper archiveObject:object forKey:defaultsKey];
}

- (Identity *)getExistingIdentitySelectionFor:(NSString *)nai service:(NSString *)service password:(NSString *)password {
	NSMutableArray *items = [NSMutableArray array];
	if ([MSTKeychainHelper unarchiveObjectForKey:MST_IDENTITIES]) {
		items = [MSTKeychainHelper unarchiveObjectForKey:MST_IDENTITIES];
	}
	
	for (Identity *identity in items) {
		for (NSString *itemService in identity.servicesArray) {
			if ([itemService isEqualToString:service]) {
				return identity;
			}
		}
	}

	for (Identity *identity in items) {
		for (SelectionRules *selectionRule in identity.selectionRules) {
			// Check if service complies to selectionRule
			if ([selectionRule.alwaysConfirm isEqualToString:@"false"]) {
				if ([self serviceName:service matchesSelectionRule:selectionRule.pattern]) {
					[identity.servicesArray addObject:service];
					[self editIdentity:identity withBlock:^(NSError *error) {
					}];
					return identity;
				}
			}
		}
	}
	
	return nil;
}

- (BOOL)serviceName:(NSString *)serviceName matchesSelectionRule:(NSString *)selectionRule {
	NSPredicate *pred = [NSPredicate predicateWithFormat:@"self LIKE %@", selectionRule];
	BOOL match = [pred evaluateWithObject:serviceName];
	return match;
}

- (Identity *)getExistingIdentitySelectionFor:(NSString *)nai realm:(NSString *)realm {
	NSMutableArray *items = [NSMutableArray array];
	if ([MSTKeychainHelper unarchiveObjectForKey:MST_IDENTITIES]) {
		items = [MSTKeychainHelper unarchiveObjectForKey:MST_IDENTITIES];
	}
	
	for (Identity *identity in items) {
		if ([identity.username isEqualToString:nai] && [identity.realm isEqualToString:realm]) {
			return identity;
		}
	}
	
	return nil;
}


@end
