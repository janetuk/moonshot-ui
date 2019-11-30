//
//  AppDelegate.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/13/16.
//

#import <CommonCrypto/CommonHMAC.h>
#import "AppDelegate.h"
#import "AboutWindow.h"
#import "MSTConstants.h"
#import "MainViewController.h"
#import "MSTIdentitySelectorViewController.h"
#import "MSTDBusServer.h"
#import "Identity.h"
#import "MSTIdentityDataLayer.h"
#import "TrustAnchorWindow.h"
#import "X509Cert.h"

@interface AppDelegate ()<TrustAnchorWindowDelegate>

@property (strong) IBOutlet NSWindow *window;
@property (nonatomic, strong) IBOutlet NSViewController *viewController;
@property (nonatomic, strong) NSOperationQueue *dbusQueue;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSApplication sharedApplication] windows][0].restorable = YES;
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {

}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification {
    if (!self.isLaunchedForIdentitySelection) {
        if (!self.isIdentityManagerLaunched) {
            [self setIdentityManagerViewController];
        }
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {

}

#pragma mark - Set Content ViewController

- (void)setIdentitySelectorViewController:(MSTGetIdentityAction *)getIdentityAction {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    _viewController = [storyBoard instantiateControllerWithIdentifier:@"MSTIdentitySelectorViewController"];
    ((MSTIdentitySelectorViewController *)_viewController).getIdentityAction = getIdentityAction;
    [[[NSApplication sharedApplication] windows][0] setContentViewController:_viewController];
    [[[NSApplication sharedApplication] windows][0]  setTitle:NSLocalizedString(@"Identity_Selector_Window_Title", @"")];
}

- (void)setIdentityManagerViewController {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    _viewController = [storyBoard instantiateControllerWithIdentifier:@"MainViewController"];
    [[[NSApplication sharedApplication] windows][0] setContentViewController:_viewController];
    [[[NSApplication sharedApplication] windows][0]  setTitle:NSLocalizedString(@"Identity_Manager_Window_Title", @"")];
    self.isIdentityManagerLaunched = YES;
}

- (void)setTrustAnchorControllerForIdentity:(Identity *)identity hashStr:(NSString *)hashStr certInfo:(NSString*)certInfo withReply:(DBusMessage *)reply andConnection:(DBusConnection *)connection {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    _viewController = [storyBoard instantiateControllerWithIdentifier:@"TrustAnchor"];
    ((TrustAnchorWindow *)_viewController).delegate = self;
    ((TrustAnchorWindow *)_viewController).identity = identity;
    ((TrustAnchorWindow *)_viewController).reply = reply;
    ((TrustAnchorWindow *)_viewController).connection = connection;
	((TrustAnchorWindow *)_viewController).hashStr = hashStr;
    ((TrustAnchorWindow *)_viewController).certInfo = certInfo;

    [[[NSApplication sharedApplication] windows][0] setContentViewController:_viewController];
    [[[NSApplication sharedApplication] windows][0]  setTitle:NSLocalizedString(@"Trust Anchor", @"")];
}

#pragma mark - Set Trust Anchor
- (void)confirmCaCertForIdentityWithName:(NSString *)name realm:(NSString *)realm certData:(NSString *)certData connection:(DBusConnection *)connection reply:(DBusMessage *)reply {
	NSLog(@"confirmCaCertForIdentityWithName %@", name);

    Identity *identity = [[MSTIdentityDataLayer sharedInstance] getExistingIdentitySelectionFor:name realm:realm];

	// -----------
	int  success = 1;

	if (identity == nil) {
		success = 0;
		dbus_message_append_args(reply,
								 DBUS_TYPE_INT32, &success,
								 DBUS_TYPE_BOOLEAN, &success,
								 DBUS_TYPE_INVALID);

		dbus_connection_send(connection, reply, NULL);
		dbus_message_unref(reply);
		AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
		[NSApp terminate:delegate];
		return;
	}
    NSString* hash = certData;
    NSString* info = nil;
	if (certData.length != 32) {
        X509Cert* cert = [[X509Cert alloc]initWithHexString:certData];
        hash = cert.hexfingerprint;
        info = cert.textsummary;
	}

	if (identity.trustAnchor.serverCertificate.length > 0) {
		NSString *trimmedOldHash = [TrustAnchor stringBySanitazingDots:identity.trustAnchor.serverCertificate];
		NSString *trimmedNewHash = [TrustAnchor stringBySanitazingDots:hash];
		if ([trimmedOldHash isEqualToString:trimmedNewHash]) {
		NSLog(@"Certificate fingerprint matched stored trust anchor");
			success = 1;
		} else {
		NSLog(@"Certificate fingerprint did not match stored trust anchor");
			success = 0;
		}
		dbus_message_append_args(reply,
								 DBUS_TYPE_INT32, &success,
								 DBUS_TYPE_BOOLEAN, &success,
								 DBUS_TYPE_INVALID);

		dbus_connection_send(connection, reply, NULL);
		dbus_message_unref(reply);
		AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
		[NSApp terminate:delegate];

	} else {
		if (identity.trustAnchor == nil) {
			identity.trustAnchor = [[TrustAnchor alloc] init];
		}

		dispatch_async(dispatch_get_main_queue(), ^{
            [self setTrustAnchorControllerForIdentity:identity hashStr:hash certInfo:info withReply:reply andConnection:connection];
		});
	}
}

- (void)didSaveWithSuccess:(int)success reply:(DBusMessage *)reply connection:(DBusConnection *)connection andCertificate:(NSString *)certificate forIdentity:(Identity *)identity {
	if (success) {
		identity.trustAnchor.serverCertificate = certificate;
	}
    [[MSTIdentityDataLayer sharedInstance] editIdentity:identity withBlock:nil];
    dbus_message_append_args(reply,
                             DBUS_TYPE_INT32, &success,
                             DBUS_TYPE_BOOLEAN, &success,
                             DBUS_TYPE_INVALID);
    dbus_connection_send(connection, reply, NULL);
    dbus_message_unref(reply);

    /* There was a 2s delay to close this window. It seems we can do it immediately instead */
    [NSApp terminate:self];
	// [NSTimer scheduledTimerWithTimeInterval:2.0
	// 								 target:self
	// 							   selector:@selector(terminateApp:)
	// 							   userInfo:nil
	// 								repeats:NO];
}

- (void)terminateApp:(id)sender {
	[NSApp terminate:self];
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
- (void)initiateIdentitySelectionFor:(NSString *)nai service:(NSString *)service password:(NSString *)password connection:(DBusConnection *)connection reply:(DBusMessage *)reply {
    
	NSLog(@"(void)initiateIdentitySelectionFor:(NSString *)nai service:(NSString *)service password:(NSString *)password");
	Identity *existingIdentitySelection = [self getExistingIdentitySelectionFor:nai service:service password:password];
	if (([existingIdentitySelection.identityId isEqualToString:MST_NO_IDENTITY]) || (existingIdentitySelection && existingIdentitySelection.password.length > 0 && existingIdentitySelection.has2fa == NO)) {
		NSString *combinedNaiOut = @"";
		if (existingIdentitySelection.username.length && existingIdentitySelection.realm.length) {
			combinedNaiOut = [NSString stringWithFormat:@"%@@%@",existingIdentitySelection.username,existingIdentitySelection.realm];
		}
		const char *nai_out = [combinedNaiOut UTF8String];
		const char *password_out;
		if (existingIdentitySelection.has2fa) {
			NSString *combinedPasswordOut = @"";
			combinedPasswordOut = [NSString stringWithFormat:@"%@%@",existingIdentitySelection.password,existingIdentitySelection.secondFactor];
			password_out = [combinedPasswordOut UTF8String];
		}
		else {
			password_out = existingIdentitySelection.password == nil ? "" : [existingIdentitySelection.password UTF8String];
		}
		const char *server_certificate_hash_out = existingIdentitySelection.trustAnchor.serverCertificate == nil ? [@"" UTF8String] : [existingIdentitySelection.trustAnchor.serverCertificate UTF8String];
		const char *ca_certificate_out =  existingIdentitySelection.trustAnchor.caCertificate == nil ? [@"" UTF8String] : [existingIdentitySelection.trustAnchor.caCertificate UTF8String];
		const char *subject_name_constraint_out =  existingIdentitySelection.trustAnchor.subject == nil ? [@"" UTF8String] : [existingIdentitySelection.trustAnchor.subject UTF8String];
		const char *subject_alt_name_constraint_out =  existingIdentitySelection.trustAnchor.subjectAlt == nil ? [@"" UTF8String] : [existingIdentitySelection.trustAnchor.subjectAlt UTF8String];
		const int  success = [existingIdentitySelection.identityId isEqualToString:MST_NO_IDENTITY] ? 0 : 1;
		
		dbus_message_append_args(reply,
								 DBUS_TYPE_STRING, &nai_out,
								 DBUS_TYPE_STRING, &password_out,
								 DBUS_TYPE_STRING, &server_certificate_hash_out,
								 DBUS_TYPE_STRING, &ca_certificate_out,
								 DBUS_TYPE_STRING, &subject_name_constraint_out,
								 DBUS_TYPE_STRING, &subject_alt_name_constraint_out,
								 DBUS_TYPE_BOOLEAN, &success,
								 DBUS_TYPE_INVALID);
		
		dbus_connection_send(connection, reply, NULL);
		dbus_message_unref(reply);
        
        //clear cached password (needed for the second call of method "moonshot_get_identity" (http://sdlc.devsy.com/amsys/jisc/macos/issues/24)
        if (existingIdentitySelection.passwordRemembered == NO) {
            existingIdentitySelection.password = @"";
            [[MSTIdentityDataLayer sharedInstance] editIdentity:existingIdentitySelection withBlock:nil];
        }
        
		if (success == 0) {
			[NSApp terminate:self];
		}
	} else {
		MSTGetIdentityAction *getIdentity = [[MSTGetIdentityAction alloc] initFetchIdentityFor:nai service:service password:password connection:connection reply:reply];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self setIdentitySelectorViewController:getIdentity];
		});
	}
}

- (Identity *)getExistingIdentitySelectionFor:(NSString *)nai service:(NSString *)service password:(NSString *)password {
	return [[MSTIdentityDataLayer sharedInstance] getExistingIdentitySelectionFor:nai service:service password:password];
}

- (void)startListeningForDBusConnections {
	if (!self.dbusQueue) {
		self.dbusQueue = [[NSOperationQueue alloc] init];
		self.dbusQueue.maxConcurrentOperationCount = 1;
	}

	if (self.dbusQueue.operationCount == 0) {
		[self.dbusQueue addOperationWithBlock:^{
			dbusStartListening();
		}];
	}
}

@end
