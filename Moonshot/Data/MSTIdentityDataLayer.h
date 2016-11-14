//
//  MSTIdentityDataLayer.h
//  Moonshot
//
//  Created by Ivan Aleksovski on 11/11/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Identity.h"

static const NSString  *MSTIdentityNoIndentityID = @"MSTIdentityNoIndentityID";

@interface MSTIdentityDataLayer : NSObject

+ (MSTIdentityDataLayer *)sharedInstance;

- (void)getAllIdentitiesWithBlock:(void (^)(NSArray <Identity *> *items))block;
- (void)addNewIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block;
- (void)editIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block;
- (void)removeIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block;

@end
