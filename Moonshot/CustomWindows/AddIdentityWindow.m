//
//  AddIdentityWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/21/16.
//

#import "AddIdentityWindow.h"
#import "NSString+GUID.h"

@interface AddIdentityWindow ()<NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *displayNameTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSTextField *realmTextField;
@property (weak) IBOutlet NSTextField *passwordTextField;
@property (weak) IBOutlet NSTextField *rememberPasswordTextField;
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
    [self.displayNameTextField setStringValue:NSLocalizedString(@"Display_Name_Add", @"")];
    [self.usernameTextField setStringValue:NSLocalizedString(@"Username_Add", @"")];
    [self.realmTextField setStringValue:NSLocalizedString(@"Realm_Add", @"")];
    [self.passwordTextField setStringValue:NSLocalizedString(@"Password_Add", @"")];
    [self.rememberPasswordTextField setStringValue:NSLocalizedString(@"Remember_Password", @"")];
    [self.cancelButton setTitle:NSLocalizedString(@"Cancel_Button", @"")];
    [self.addIdentityButton setTitle:NSLocalizedString(@"Save_Changes_Button", @"")];
}

#pragma mark - Button Actions

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
        identityObject.servicesArray = [NSMutableArray arrayWithObjects:@"google.com",@"developer.apple.com",@"dev.ja.net",@"amsys.com",nil];
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
    NSMutableArray *array = [NSMutableArray arrayWithObjects:@"Enterprise provisioned",@"None",nil];
    uint32_t myCount = (uint32_t)[array count];
    uint32_t rnd = arc4random_uniform(myCount);
    NSString *randomObject = [array objectAtIndex:rnd];
    return randomObject;
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    [self.addIdentityButton setEnabled:[self isRequiredDataFilled]];
}

- (BOOL)isRequiredDataFilled {
    BOOL addIdentityButtonDisabled = [self.displayNameValueTextField.stringValue isEqualToString:@""] ||
    [self.usernameValueTextField.stringValue isEqualToString:@""] ||
    [self.realmValueTextField.stringValue isEqualToString:@""] ||
    [self.passwordValueTextField.stringValue isEqualToString:@""];
    return !addIdentityButtonDisabled;
}
@end
