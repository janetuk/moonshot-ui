//
//  AppDelegate.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/13/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import "AppDelegate.h"
#import "AboutWindow.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)about:(id)sender
{
    // Show the window:
    [[AboutWindow defaultController] showWindow:self];
}

@end
