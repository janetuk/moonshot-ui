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

- (void)setTrustAnchorControllerForIdentity:(Identity *)identity hashStr:(NSString *)hashStr withReply:(DBusMessage *)reply andConnection:(DBusConnection *)connection {
    NSStoryboard *storyBoard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    _viewController = [storyBoard instantiateControllerWithIdentifier:@"TrustAnchor"];
    ((TrustAnchorWindow *)_viewController).delegate = self;
    ((TrustAnchorWindow *)_viewController).identity = identity;
    ((TrustAnchorWindow *)_viewController).reply = reply;
    ((TrustAnchorWindow *)_viewController).connection = connection;
	((TrustAnchorWindow *)_viewController).hashStr = hashStr;

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

	// hex -> bytes
	unsigned long i = 0, cert_len = certData.length / 2;
	const char *hash_string = [certData UTF8String];
	unsigned char *cert_data_buffer = malloc(cert_len);
	NSString *hash;
	for (i = 0; i < cert_len; i++)
		sscanf(&hash_string[i*2], "%02X", &cert_data_buffer[i]);

	NSData *certByteBuffer = [NSData dataWithBytes:cert_data_buffer length:i];
	SecCertificateRef thisCert = SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)certByteBuffer);
	free(cert_data_buffer);
	if (thisCert != NULL) {
		CFStringRef certSubjectSummary = SecCertificateCopySubjectSummary(thisCert);
		NSString* subjectSummaryString = [[NSString alloc] initWithString:(__bridge NSString*)certSubjectSummary];
		NSLog(@"Hash contained certificate: %@", subjectSummaryString);
		CFRelease(certSubjectSummary);
		CFDataRef certificateDataRef = SecCertificateCopyData(thisCert);
		NSData *certificateData = CFBridgingRelease(certificateDataRef);
		if (certificateDataRef != NULL) {
			NSLog(@"Got certificate data: %@", subjectSummaryString);
			NSMutableString *hexString = [NSMutableString stringWithCapacity:(CC_SHA256_DIGEST_LENGTH * 2)];
			unsigned char *sha256_hash_buffer = malloc(CC_SHA256_DIGEST_LENGTH);
			CC_SHA256(certificateData.bytes, (CC_LONG)certificateData.length, sha256_hash_buffer);
			for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i)
				[hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)sha256_hash_buffer[i]]];
			free(sha256_hash_buffer);
			NSLog(@"Certificate %@ SHA-256 fingerprint %@", subjectSummaryString, hexString);
			hash = [hexString uppercaseString];
		}
	} else {
		NSLog(@"Hash contained: %@", certData);
		hash = certData;
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
			[self setTrustAnchorControllerForIdentity:identity hashStr:hash withReply:reply andConnection:connection];
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
	[NSTimer scheduledTimerWithTimeInterval:2.0
									 target:self
								   selector:@selector(terminateApp:)
								   userInfo:nil
									repeats:NO];
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
