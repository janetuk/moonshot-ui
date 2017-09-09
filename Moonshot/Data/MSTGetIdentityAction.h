//
//  GetIdentityAction.h
//  Moonshot
//
//  Created by Ivan on 9/8/17.
//  Copyright © 2017 Devsy. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Identity;

@interface MSTGetIdentityAction : NSString
@property (nonatomic, strong) Identity *selectedIdentity;

- (void)initiateFetchIdentityFor:(NSString *)nai service:(NSString *)service password:(NSString *)password;

@end
