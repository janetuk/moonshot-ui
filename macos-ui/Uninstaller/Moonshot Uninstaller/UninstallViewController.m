//
//  UninstallViewController.m
//  Uninstall Moonshot
//
//  Copyright © 2018 JISC. All rights reserved.
//

#import "UninstallViewController.h"
#import "BLAuthentication.h"
@interface UninstallViewController ()

@end

@implementation UninstallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.btnUninstall setTarget:self];
    [self.btnUninstall setAction:@selector(btnUninstallClicked)];
    self.txtDescription.textContainerInset = NSMakeSize(10.0, 10.0);
}

- (void)btnUninstallClicked {
    self.btnUninstall.hidden = YES;
    self.progressIndicator.hidden = NO;
    [self.progressIndicator startAnimation:@(1)];
#define RM @"/bin/rm"
    if (![[BLAuthentication sharedInstance] isAuthenticated:RM]) {
        [[BLAuthentication sharedInstance] authenticate:RM];
    }
    NSString *launchAgentConfPath = [NSString stringWithFormat:@"%@/Library/LaunchAgents/org.freedesktop.dbus-session.plist", [self homeDirectory]];
    if ([[BLAuthentication sharedInstance] isAuthenticated:RM]) {
        [[BLAuthentication sharedInstance] executeCommand:RM withArgs:@[@"/etc/gss/mech"]];
        [[BLAuthentication sharedInstance] executeCommand:RM withArgs:@[@"/usr/local/lib/gss/mech_eap.so"]];
        [[BLAuthentication sharedInstance] executeCommand:RM withArgs:@[@"-rf", @"/usr/local/moonshot/"]];
        [[BLAuthentication sharedInstance] executeCommand:RM withArgs:@[launchAgentConfPath]];
        [[BLAuthentication sharedInstance] executeCommand:RM withArgs:@[@"-rf", @"/Applications/Moonshot.app"]];
        [[BLAuthentication sharedInstance] executeCommand:RM withArgs:@[@"-rf", @"/Applications/Uninstall Moonshot.app"]];
        [self fireSuccessAlert];
    } else {
        [self fireFailAlert];
    }
}

- (NSString *)homeDirectory {
    return NSHomeDirectory();
}

- (void)fireSuccessAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Uninstall Complete"];
    [alert setInformativeText:@"Moonshot is now fully uninstalled from this computer."];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
        [NSApp terminate:self];
    }];
}

- (void)fireFailAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Uninstall Failed"];
    [alert setInformativeText:@"Moonshot is not fully uninstalled from this computer. Please try again."];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert beginSheetModalForWindow:[[self view] window] completionHandler:^(NSModalResponse returnCode) {
        [NSApp terminate:self];
    }];
}

@end
