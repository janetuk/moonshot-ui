//
//  AppDelegate.m
//  Moonshot Uninstaller
//
//  Copyright © 2018 JISC. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.window.contentView.layer.backgroundColor = [NSColor colorWithRed:242.0/255.0 green:241.0/255.0 blue:241.0/255.0 alpha:1.0].CGColor;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
