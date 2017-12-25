//
//  AddIdentityWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/21/16.
//

#import "AddIdentityWindow.h"
#import "NSString+GUID.h"
#import "MainViewController.h"

@interface AddIdentityWindow ()<NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *displayNameTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSTextField *realmTextField;
@property (weak) IBOutlet NSTextField *passwordTextField;
@property (weak) IBOutlet NSTextField *displayNameValueTextField;
@property (weak) IBOutlet NSTextField *realmValueTextField;
@property (weak) IBOutlet NSTextField *usernameValueTextField;
@property (weak) IBOutlet NSSecureTextField *passwordValueTextField;
@property (weak) IBOutlet NSButton *rememberPasswordButton;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *addIdentityButton;
@end

@implementation AddIdentityWindow

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

#pragma mark - Setup TextFields

- (void)setupTextFields {
    [self.displayNameTextField setStringValue:NSLocalizedString(@"Display_Name_Add", @"")];
    [self.usernameTextField setStringValue:NSLocalizedString(@"Username_Add", @"")];
    [self.realmTextField setStringValue:NSLocalizedString(@"Realm_Add", @"")];
    [self.passwordTextField setStringValue:NSLocalizedString(@"Password_Add", @"")];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self.rememberPasswordButton setTitle:NSLocalizedString(@"Remember_Password", @"")];
    [self.cancelButton setTitle:NSLocalizedString(@"Cancel_Button", @"")];
    
    if ([[[[NSApplication sharedApplication] keyWindow] contentViewController] isKindOfClass:[MainViewController class]]) {
        [self.addIdentityButton setTitle:NSLocalizedString(@"Add_Identity_Button", @"")];
    } else {
        [self.addIdentityButton setTitle:NSLocalizedString(@"Create_Identity_Button", @"")];
    }
}

#pragma mark - Button Actions

- (IBAction)rememberPasswordButtonPressed:(id)sender {
    if ([self isRequiredDataFilled]) {
        if ([self isPasswordMandatory])
            [self.addIdentityButton setEnabled:NO];
        else
            [self.addIdentityButton setEnabled:YES];
    } else
        [self.addIdentityButton setEnabled:NO];
}

- (IBAction)saveChangesButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(addIdentityWindow:wantsToAddIdentity:rememberPassword:)]) {
        Identity *identityObject = [[Identity alloc] init];
        identityObject.identityId = [NSString getUUID];
        identityObject.displayName = self.displayNameValueTextField.stringValue;
        identityObject.username = self.usernameValueTextField.stringValue;
        identityObject.realm = self.realmValueTextField.stringValue;
        identityObject.password = self.passwordValueTextField.stringValue;
        identityObject.passwordRemembered = self.rememberPasswordButton.state;
        identityObject.dateAdded = [NSDate date];
        identityObject.servicesArray = [NSMutableArray array];
        identityObject.trustAnchor = [self randomElementFromArray];
        [self.delegate addIdentityWindow:self.window wantsToAddIdentity:identityObject rememberPassword:self.rememberPasswordButton.state];
    }
}

- (IBAction)cancelButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(addIdentityWindowCanceled:)]) {
        [self.delegate addIdentityWindowCanceled:self.window];
    }
}

#pragma mark - Random element from Array

- (NSString *)randomElementFromArray {
    NSMutableArray *array = [NSMutableArray arrayWithObjects:NSLocalizedString(@"Enterprise_provisioned", @""),NSLocalizedString(@"None", @""),nil];
    uint32_t myCount = (uint32_t)[array count];
    uint32_t rnd = arc4random_uniform(myCount);
    NSString *randomObject = [array objectAtIndex:rnd];
    return randomObject;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    if ([self isPasswordMandatory]) {
        [self.addIdentityButton setEnabled:NO];
    } else {
        [self.addIdentityButton setEnabled:[self isRequiredDataFilled]];
    }
}

#pragma mark - Required data

- (BOOL)isRequiredDataFilled {
    BOOL addIdentityButtonDisabled = [self.displayNameValueTextField.stringValue isEqualToString:@""] ||
    [self.usernameValueTextField.stringValue isEqualToString:@""] ||
    [self.realmValueTextField.stringValue isEqualToString:@""];
    return !addIdentityButtonDisabled;
}

- (BOOL)isPasswordMandatory {
    BOOL isPasswordMandatory = self.rememberPasswordButton.state == NSOnState &&
    [self.passwordValueTextField.stringValue isEqualToString:@""];
    return isPasswordMandatory;
}

@end
