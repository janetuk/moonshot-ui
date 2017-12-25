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
	[self getAllRealIdentitiesWithBlock:^(NSArray<Identity *> *items) {
		//Add the "no identity"
		Identity *noIdentity = [[Identity alloc] init];
		noIdentity.identityId = MST_NO_IDENTITY;
		noIdentity.displayName = NSLocalizedString(@"No_Identity", @"");
        noIdentity.username = NSLocalizedString(@"No_Identity", @"");
        noIdentity.realm = NSLocalizedString(@"No_Identity", @"");
        noIdentity.trustAnchor = NSLocalizedString(@"None", @"");
        noIdentity.caCertificate = NO;
        noIdentity.servicesArray = [NSMutableArray arrayWithObjects:NSLocalizedString(@"No_Identity", @""),nil];
        NSMutableArray *itemsWithNoIdentity = [items mutableCopy];
		[itemsWithNoIdentity addObject:noIdentity];
		block(itemsWithNoIdentity);
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
    
    NSError *error;
    block(error);
}

- (void)editIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block {
	if ([newIdentity.identityId isEqualToString:MST_NO_IDENTITY]) {
		NSError *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:9999 userInfo:@{}];
		block(error);
		return;
	}
    [self getAllRealIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        __weak __typeof__(self) weakSelf = self;
        NSMutableArray *newIdentityArray = [[NSMutableArray arrayWithArray:items] mutableCopy];
        for (int i = 0; i < [newIdentityArray count]; i++) {
            if ([[newIdentityArray[i] valueForKey:@"identityId"] isEqualToString:newIdentity.identityId]) {
                [newIdentityArray replaceObjectAtIndex:i withObject:newIdentity];
                [weakSelf saveObject:newIdentityArray forKey:MST_IDENTITIES];
                break;
            }
        }
		NSError *error;
		block(error);
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
                if ([[newIdentityArray[i] valueForKey:@"identityId"] isEqualToString:newIdentity.identityId]) {
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

- (void)saveObject:(id)object forKey:(NSString *)defaultsKey {
    [MSTKeychainHelper archiveObject:object forKey:defaultsKey];
}



@end
