//
//  TrustAnchorWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 4/17/18.
//

#import "TrustAnchorWindow.h"
#import "MSTIdentityDataLayer.h"
#import "AppDelegate.h"

@interface TrustAnchorWindow ()
@property (weak) IBOutlet NSTextField *trustAnchorShaFingerprintTextField;
@property (weak) IBOutlet NSButton *trustAnchorCancelButton;
@property (weak) IBOutlet NSButton *trustAnchorConfirmButton;
@property (weak) IBOutlet NSTextField *trustAnchorInfoTextField;
@property (weak) IBOutlet NSTextField *trustAnchorUsernameTextField;
@property (weak) IBOutlet NSTextField *trustAnchorRealmTextField;
@property (weak) IBOutlet NSTextField *trustAnchorShaFingerprintTitleTextField;
@property (weak) IBOutlet NSTextField *trustAnchorCheckInfoTextField;

@end

@implementation TrustAnchorWindow

#pragma mark - Window Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupWindow];
}

#pragma mark - Setup Window

- (void)setupWindow {
    [self setupButtons];
    [self setupTextFields];
}

#pragma mark - Setup TextFields

- (void)setupTextFields {
    [self setupInfoTextField];
    [self setupUsernameTextFieldWithUsername:self.identity.username];
    [self setupRealmTextFieldWithRealm:self.identity.realm];
    [self setupShaTitleTextField];
    [self setupShaTextFieldWithShaFingerprint:self.hashStr];
    [self setupCheckInfoTextField];
}

- (void)setupInfoTextField {
    [self.trustAnchorInfoTextField setStringValue:NSLocalizedString(@"Trust_Anchor_Info_Text", @"")];
}

- (void)setupUsernameTextFieldWithUsername:(NSString *)username {
    [self.trustAnchorUsernameTextField setStringValue:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Trust_Anchor_Username", @""), username]];
}

- (void)setupRealmTextFieldWithRealm:(NSString *)realm {
    [self.trustAnchorRealmTextField setStringValue:[NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Trust_Anchor_Realm", @""),realm]];
}

- (void)setupShaTitleTextField {
    [self.trustAnchorShaFingerprintTitleTextField setStringValue:NSLocalizedString(@"Trust_Anchor_Sha_Fingerprint_Title", @"")];
}

- (void)setupShaTextFieldWithShaFingerprint:(NSString *)fingerprint {
	if (fingerprint.length > 0) {
		[self.trustAnchorShaFingerprintTextField setStringValue:fingerprint];
		[self.trustAnchorShaFingerprintTextField setEnabled:NO];
	}
}

- (void)setupCheckInfoTextField {
    [self.trustAnchorCheckInfoTextField setStringValue:NSLocalizedString(@"Trust_Anchor_Check_Info", @"")];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self setupCancelButton];
    [self setupConfirmButton];
}

- (void)setupCancelButton {
    self.trustAnchorCancelButton.title = NSLocalizedString(@"Cancel", @"");
}

- (void)setupConfirmButton {
    self.trustAnchorConfirmButton.title = NSLocalizedString(@"Confirm", @"");
}

#pragma mark - Button Actions

- (IBAction)trustAnchorCancelButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didSaveWithSuccess:reply:connection:andCertificate:forIdentity:)]) {
        [self.delegate didSaveWithSuccess:0 reply:self.reply connection:self.connection andCertificate:self.trustAnchorShaFingerprintTextField.stringValue forIdentity:self.identity];
    }
}

- (IBAction)trustAnchorConfirmButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didSaveWithSuccess:reply:connection:andCertificate:forIdentity:)]) {
        [self.delegate didSaveWithSuccess:1 reply:self.reply connection:self.connection andCertificate:self.trustAnchorShaFingerprintTextField.stringValue forIdentity:self.identity];
    }
}

#pragma mark - Terminate Application

- (void)terminateApplication {
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [NSApp terminate:delegate];
}

@end
