//
//  GetIdentityAction.h
//  Moonshot
//
//  Created by Ivan on 9/8/17.
//  Copyright © 2017 Devsy. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <dbus/dbus.h>

@class Identity;

@interface MSTGetIdentityAction : NSString
@property (nonatomic, strong) NSString *nai;
@property (nonatomic, strong) NSString *service;
@property (nonatomic, strong) NSString *password;

- (instancetype)initFetchIdentityFor:(NSString *)nai service:(NSString *)service password:(NSString *)password connection:(DBusConnection *)connection reply:(DBusMessage *)reply;
- (void)selectedIdentity:(Identity *)identity;
@end

