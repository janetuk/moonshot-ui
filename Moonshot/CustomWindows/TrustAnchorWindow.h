//
//  TrustAnchorWindow.h
//  Moonshot
//
//  Created by Elena Jakjoska on 4/17/18.
//

#import <Cocoa/Cocoa.h>
#import "Identity.h"
#include <dbus/dbus.h>

@protocol TrustAnchorWindowDelegate <NSObject>
- (void)didSaveWithSuccess:(int)success reply:(DBusMessage *)reply connection:(DBusConnection *)connection andCertificate:(NSString *)certificate forIdentity:(Identity *)identity;
@end

@interface TrustAnchorWindow : NSViewController
@property (nonatomic, weak) id <TrustAnchorWindowDelegate>delegate;
@property (nonatomic, strong) Identity *identity;
@property (nonatomic, strong) NSString *hashStr;
@property (nonatomic, assign) int success;
@property (nonatomic, assign) DBusConnection *connection;
@property (nonatomic, assign) DBusMessage *reply;

@end
