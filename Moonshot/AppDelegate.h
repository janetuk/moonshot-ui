//
//  AppDelegate.h
//  Moonshot
//
//  Created by Elena Jakjoska on 10/13/16.
//

#import <Cocoa/Cocoa.h>
#import "MSTGetIdentityAction.h"
#include <dbus/dbus.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong, readonly) MSTGetIdentityAction *ongoingIdentitySelectAction;
- (void)initiateIdentitySelectionFor:(NSString *)nai service:(NSString *)service password:(NSString *)password connection:(DBusConnection *)connection reply:(DBusMessage *)reply;
- (void)startListeningForDBusConnections;
@end

