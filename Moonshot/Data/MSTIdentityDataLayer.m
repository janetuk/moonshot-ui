//
//  MSTIdentityDataLayer.m
//  Moonshot
//
//  Created by Ivan Aleksovski on 11/11/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import "MSTIdentityDataLayer.h"

@implementation MSTIdentityDataLayer

#pragma mark - Singletone management

static MSTIdentityDataLayer *sharedInstance;

+ (MSTIdentityDataLayer *)sharedInstance
{
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
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"Identities_Array"] != nil) {
        NSData *encodedObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"Identities_Array"];
        NSArray *items = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        block(items);
    }
}

- (void)addNewIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block {
    __block NSMutableArray *newIdentityArray = [[NSMutableArray alloc] init];
    [self getAllIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        newIdentityArray = [items mutableCopy];
    }];
    [newIdentityArray addObject:newIdentity];
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:newIdentityArray];
    [[NSUserDefaults standardUserDefaults] setObject:encodedObject forKey:@"Identities_Array"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSError *error;
    block(error);
}

- (void)editIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block {
    [self getAllIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        NSMutableArray *newIdentityArray = [[NSMutableArray arrayWithArray:items] mutableCopy];
        for (int i = 0; i < [newIdentityArray count]; i++) {
            if ([[newIdentityArray[i] valueForKey:@"identityId"] isEqualToString:newIdentity.identityId]) {
                [newIdentityArray replaceObjectAtIndex:i withObject:newIdentity];
                NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:newIdentityArray];
                [[NSUserDefaults standardUserDefaults] setObject:encodedObject forKey:@"Identities_Array"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                return;
            }
        }
    }];
    NSError *error;
    block(error);
}

- (void)removeIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block {
    [self getAllIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        NSMutableArray *newIdentityArray = [[NSMutableArray arrayWithArray:items] mutableCopy];
        if ([newIdentityArray count] > 0) {
            for (int i = 0; i < [newIdentityArray count]; i++) {
                if ([[newIdentityArray[i] valueForKey:@"identityId"] isEqualToString:newIdentity.identityId]) {
                    [newIdentityArray removeObjectAtIndex:i];
                    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:newIdentityArray];
                    [[NSUserDefaults standardUserDefaults] setObject:encodedObject forKey:@"Identities_Array"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    return;
                }
            }
        }
    }];
    NSError *error;
    block(error);
}
@end
