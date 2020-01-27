//
//  ConnectIdentityWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 11/25/16.
//

#import "ConnectIdentityWindow.h"
#import "Identity+Utilities.h"
#import "NSWindow+Utilities.h"

@interface ConnectIdentityWindow ()
@property (weak) IBOutlet NSTextField *connectIdentityTitleTextField;
@property (weak) IBOutlet NSTextField *connectIdentityUserTitleTextField;
@property (weak) IBOutlet NSTextField *connectIdentityUserValueTextField;
@property (weak) IBOutlet NSTextField *connectIdentityPasswordTitleTextField;
@property (weak) IBOutlet NSTextField *connectIdentitySecondFactorTitleTextField;
@property (weak) IBOutlet NSSecureTextField *connectIdentityPasswordValueTextField;
@property (weak) IBOutlet NSSecureTextField *connectIdentitySecondFactorValueTextField;
@property (weak) IBOutlet NSButton *connectIdentityRememberPasswordButton;
@property (weak) IBOutlet NSButton *connectIdentityHas2FAButton;
@property (weak) IBOutlet NSButton *connectIdentityCancelButton;
@property (weak) IBOutlet NSButton *connectIdentityConnectButton;
@end

@implementation ConnectIdentityWindow

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupWindow];
}

#pragma mark - Setup Window

- (void)setupWindow {
    [self setupTextFields];
    [self setupButtons];
}

- (void)setupTextFields {
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Enter_Password", @""),self.identityObject.displayName];
    [self.connectIdentityTitleTextField setStringValue:title];
    [self.connectIdentityUserTitleTextField setStringValue:NSLocalizedString(@"User_Nai", @"")];
    [self.connectIdentityUserValueTextField setStringValue:[NSString stringWithFormat:@"%@@%@",self.identityObject.username,self.identityObject.realm]];
    [self.connectIdentityPasswordTitleTextField setStringValue:NSLocalizedString(@"Password_Add",@"")];
    [self.connectIdentitySecondFactorTitleTextField setStringValue:NSLocalizedString(@"Second_Factor",@"")];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self.connectIdentityConnectButton setTitle:NSLocalizedString(@"Connect_Identity_Button", @"")];
    [self.connectIdentityConnectButton setEnabled:[self isRequiredDataFilled]];
    [self.connectIdentityCancelButton setTitle:NSLocalizedString(@"Cancel_Button", @"")];
    [self.connectIdentityRememberPasswordButton setTitle:NSLocalizedString(@"Remember_Password", @"")];
    [self.connectIdentityHas2FAButton setTitle:NSLocalizedString(@"Has_2FA", @"")];
	self.identityObject.passwordRemembered ? [self.connectIdentityRememberPasswordButton setState:NSControlStateValueOn] : [self.connectIdentityRememberPasswordButton setState:NSControlStateValueOff];
    self.identityObject.has2fa ? [self.connectIdentityHas2FAButton setState:NSControlStateValueOn] : [self.connectIdentityHas2FAButton setState:NSControlStateValueOff];
    [self.connectIdentitySecondFactorValueTextField setEnabled:[self is2FAEnabled]];
    if (self.identityObject.password.length > 0) {
        [self.connectIdentityPasswordValueTextField setStringValue:self.identityObject.password];
        [self.connectIdentityPasswordValueTextField setEnabled:[self hasNoPassword]];
    }
}

#pragma mark - Button Actions

- (IBAction)connectIdentityCancelButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(connectIdentityWindowCanceled:)]) {
        [self.delegate connectIdentityWindowCanceled:self.window];
    }
}

- (IBAction)connectIdentityConnectButtonPressed:(id)sender {
	NSLog(@"(IBAction)connectIdentityConnectButtonPressed:(id)sender");
	BOOL userAlreadyHadPassword = (self.identityObject.password.length > 0);
	BOOL oldPasswordMatchesNew = [self.identityObject.password isEqualToString:self.connectIdentityPasswordValueTextField.stringValue];
	
	if (userAlreadyHadPassword && oldPasswordMatchesNew) {
		if ([self.delegate respondsToSelector:@selector(connectIdentityWindow:wantsToConnectIdentity:)]) {
			self.identityObject.passwordRemembered = self.connectIdentityRememberPasswordButton.state;
			self.identityObject.has2fa = self.connectIdentityHas2FAButton.state;
			self.identityObject.secondFactor = self.connectIdentitySecondFactorValueTextField.stringValue;
			[self.delegate connectIdentityWindow:self.window wantsToConnectIdentity:self.identityObject];
		}
	} else if (!userAlreadyHadPassword) {
		if ([self.delegate respondsToSelector:@selector(connectIdentityWindow:wantsToConnectIdentity:)]) {
			self.identityObject.passwordRemembered = self.connectIdentityRememberPasswordButton.state;
			self.identityObject.has2fa = self.connectIdentityHas2FAButton.state;
			self.identityObject.secondFactor = self.connectIdentitySecondFactorValueTextField.stringValue;
			self.identityObject.password = self.connectIdentityPasswordValueTextField.stringValue;
			[self.delegate connectIdentityWindow:self.window wantsToConnectIdentity:self.identityObject];
		}
	} else {
		[self.window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:NSLocalizedString(@"Alert_Incorrect_User_Pass_Messsage", @"") informativeText:NSLocalizedString(@"Alert_Incorrect_User_Pass_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
			switch (returnCode) {
				case NSAlertFirstButtonReturn:
					break;
				default:
					break;
			}
		}];
	}

}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    [self.connectIdentityConnectButton setEnabled:[self isRequiredDataFilled]];
}

- (IBAction)connectIdentity2FAButtonPressed:(id)sender {
    [self.connectIdentitySecondFactorValueTextField setEnabled:[self is2FAEnabled]];
}

- (BOOL)isRequiredDataFilled {
    return self.connectIdentityPasswordValueTextField.stringValue.length > 0;
}

- (BOOL)is2FAEnabled {
    return self.connectIdentityHas2FAButton.state;
}

- (BOOL)hasNoPassword {
    return !((self.identityObject.password.length > 0) && (self.identityObject.passwordRemembered));
}


@end
