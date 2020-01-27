//
//  MSTIdentityDataLayer.h
//  Moonshot
//
//  Created by Ivan Aleksovski on 11/11/16.
//

#import <Foundation/Foundation.h>
#import "Identity.h"

static const NSString  *MSTIdentityNoIndentityID = @"MSTIdentityNoIndentityID";

@interface MSTIdentityDataLayer : NSObject

+ (MSTIdentityDataLayer *)sharedInstance;

- (void)getAllIdentitiesWithBlock:(void (^)(NSArray <Identity *> *items))block;
- (BOOL)addNewIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block;
- (void)editIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block;
- (void)removeIdentity:(Identity *)newIdentity withBlock:(void (^)(NSError *error))block;
- (Identity *)getExistingIdentitySelectionFor:(NSString *)nai service:(NSString *)service password:(NSString *)password;
- (Identity *)getExistingIdentitySelectionFor:(NSString *)nai realm:(NSString *)realm;
@end
