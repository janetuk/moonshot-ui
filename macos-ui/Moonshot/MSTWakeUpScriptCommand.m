//
//  MSTWakeUpScriptCommand.m
//  Moonshot
//
//  Created by Ivan on 11/26/17.
//

#import "MSTWakeUpScriptCommand.h"
#import "AppDelegate.h"

@implementation MSTWakeUpScriptCommand

- (id)performDefaultImplementation {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        delegate.isLaunchedForIdentitySelection = YES;
        [delegate startListeningForDBusConnections];
    });
    return @(YES);
}
@end
