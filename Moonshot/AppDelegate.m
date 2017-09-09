//
//  AppDelegate.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/13/16.
//

#import "AppDelegate.h"
#import "AboutWindow.h"
#import "MSTConstants.h"
#import "MainViewController.h"
#import "MSTIdentitySelectorViewController.h"

@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSViewController *viewController;
@property (nonatomic, strong) MSTGetIdentityAction *ongoingIdentitySelectAction;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    BOOL serviceStringExists = !self.serviceString;
//    BOOL serviceStringEmpty = [self.serviceString isEqualToString:@""];
//    
//    if (serviceStringExists || serviceStringEmpty) {
//        [self setIdentityManagerViewController];
//    } else {
//        [self setIdentitySelectorViewController];
//    }
    [self setIdentityManagerViewController];

}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // Register ourselves as a URL handler for this URL
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetURLEvent:withReplyEvent:)forEventClass:kInternetEventClass andEventID:kAEGetURL];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
//    NSURL *url = [NSURL URLWithString:[[event paramDescriptorForKeyword:keyDirectObject] stringValue]];
//    NSString *urlParameter = [[url host] stringByRemovingPercentEncoding];
//    self.serviceString = urlParameter;
//    if ([[NSRunningApplication runningApplicationsWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]] count] > 0) {
//        [self setIdentitySelectorViewController];
//    }
}

#pragma mark - Set Content ViewController

- (void)setIdentitySelectorViewController:(NSString *)serviceString {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    _viewController = [storyBoard instantiateControllerWithIdentifier:@"MSTIdentitySelectorViewController"];
    ((MSTIdentitySelectorViewController *)_viewController).service = serviceString;
    [[[NSApplication sharedApplication] windows][0] setContentViewController:_viewController];
    [[[NSApplication sharedApplication] windows][0]  setTitle:NSLocalizedString(@"Identity_Selector_Window_Title", @"")];
}

- (void)setIdentityManagerViewController {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    _viewController = [storyBoard instantiateControllerWithIdentifier:@"MainViewController"];
    [[[NSApplication sharedApplication] windows][0] setContentViewController:_viewController];
    [[[NSApplication sharedApplication] windows][0]  setTitle:NSLocalizedString(@"Identity_Manager_Window_Title", @"")];
}

#pragma mark - Button Actions

- (IBAction)about:(id)sender {
    [[AboutWindow defaultController] showWindow:self];
}

- (IBAction)addNewIdentity:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:MST_ADD_IDENTITY_NOTIFICATION object:nil];
}

- (IBAction)editIdentity:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:MST_EDIT_IDENTITY_NOTIFICATION object:nil];
}

- (IBAction)removeIdentity:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:MST_REMOVE_IDENTITY_NOTIFICATION object:nil];
}

#pragma mark - Get Identity Action
- (void)initiateIdentitySelectionFor:(NSString *)nai service:(NSString *)service password:(NSString *)password {
//    self.ongoingIdentitySelectAction = [[MSTGetIdentityAction alloc] init];
//    [self.ongoingIdentitySelectAction initiateFetchIdentityFor:nai service:service password:password];
    self.ongoingIdentitySelectAction = [[MSTGetIdentityAction alloc] init];
    [self setIdentitySelectorViewController:service];
}

@end
