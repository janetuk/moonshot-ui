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
@property (weak) IBOutlet NSButton *trustAnchorViewButton;
@property (weak) IBOutlet NSTextField *trustAnchorInfoTextField;
@property (weak) IBOutlet NSTextField *trustAnchorUsernameTextField;
@property (weak) IBOutlet NSTextField *trustAnchorRealmTextField;
@property (weak) IBOutlet NSTextField *trustAnchorShaFingerprintTitleTextField;
@property (weak) IBOutlet NSTextField *trustAnchorCheckInfoTextField;

@end

@implementation TrustAnchorWindow
{
    NSString* _certInfo;
}

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
        [self.trustAnchorShaFingerprintTextField setStringValue:[TrustAnchor stringByAddingDots:fingerprint]];
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
    [self setupCertButton];
}

- (void)setupCancelButton {
    self.trustAnchorCancelButton.title = NSLocalizedString(@"Cancel", @"");
}

- (void)setupConfirmButton {
    self.trustAnchorConfirmButton.title = NSLocalizedString(@"Confirm", @"");
}

- (void)setupCertButton {
    self.trustAnchorViewButton.title = @"View server certificate";
}
#pragma mark - Button Actions

- (IBAction)trustAnchorCancelButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didSaveWithSuccess:reply:connection:andCertificate:forIdentity:)]) {
        [self.delegate didSaveWithSuccess:0 reply:self.reply connection:self.connection andCertificate:[TrustAnchor stringBySanitazingDots:self.trustAnchorShaFingerprintTextField.stringValue] forIdentity:self.identity];
    }
}

- (IBAction)trustAnchorConfirmButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didSaveWithSuccess:reply:connection:andCertificate:forIdentity:)]) {
        [self.delegate didSaveWithSuccess:1 reply:self.reply connection:self.connection andCertificate:[TrustAnchor stringBySanitazingDots:self.trustAnchorShaFingerprintTextField.stringValue] forIdentity:self.identity];
    }
}

- (IBAction)trustAnchorViewButtonPressed:(id)sender {
    NSTextView *accessory = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    [accessory setString:self.certInfo];
    [accessory setFont:[NSFont userFixedPitchFontOfSize:0]];
    [accessory setEditable:NO];
    NSScrollView *scroll = [[NSScrollView alloc]initWithFrame:NSMakeRect(0,0,500,300)];
    [scroll setDocumentView:accessory];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Server's certificate text";
    [alert setInformativeText:@"Please, note that the information shown here could be easily forged. Always check the fingerprint!"];
    alert.accessoryView = scroll;
    [alert runModal];
}

#pragma mark - Terminate Application

- (void)terminateApplication {
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    [NSApp terminate:delegate];
}

@end
