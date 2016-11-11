//
//  MSTIdentityDataLayer.h
//  Moonshot
//
//  Created by Ivan Aleksovski on 11/11/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import <Foundation/Foundation.h>

static const NSString  *MSTIdentityNoIndentityID = @"MSTIdentityNoIndentityID";

@class Identity;
@interface MSTIdentityDataLayer : NSObject

- (void)getAllIdentitiesWithBlock:(void (^)(NSArray <Identity *> *items))block;
- (void)addNewIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *))block;
- (void)editIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *))block;
- (void)removeIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *))block;

@end
