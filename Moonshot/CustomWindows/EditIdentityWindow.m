//
//  EditIdentityWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/25/16.
//

#import "EditIdentityWindow.h"
#import "Identity.h"
#import "TrustAnchorHelpWindow.h"
#import "NSDate+NSDateFormatter.h"
#import "MSTIdentityDataLayer.h"
#import "NSWindow+Utilities.h"

@interface EditIdentityWindow ()<NSTextFieldDelegate, NSTableViewDataSource, NSTabViewDelegate>

//Services View
@property (weak) IBOutlet NSView *servicesView;
@property (weak) IBOutlet NSTextField *servicesTitleTextField;
@property (weak) IBOutlet NSTableView *editIdentityServicesTableView;
@property (weak) IBOutlet NSButton *editIdentityDeleteServiceButton;
@property (weak) IBOutlet NSButton *editIdentityCancelButton;
@property (weak) IBOutlet NSButton *editIdentitySaveButton;

//Button Actions
@property (weak) IBOutlet NSButton *editRememberPasswordButton;
@property (weak) IBOutlet NSButton *clearTrustAnchorButton;
@property (weak) IBOutlet NSButton *editIdentityHelpButton;

//Certificate View
@property (weak) IBOutlet NSView *certificateView;
@property (weak) IBOutlet NSTextField *caCertificateTextField;
@property (weak) IBOutlet NSTextField *subjectTextField;
@property (weak) IBOutlet NSTextField *subjectValueTextField;
@property (weak) IBOutlet NSTextField *expirationDateTextField;
@property (weak) IBOutlet NSTextField *expirationDateValueTextField;
@property (weak) IBOutlet NSTextField *constraintTextField;
@property (weak) IBOutlet NSTextField *constraintValueTextField;

//Fingerprint View
@property (strong) IBOutlet NSView *shaFingerprintView;
@property (weak) IBOutlet NSTextField *shaFingerprintTextField;
@property (weak) IBOutlet NSTextField *shaFingerprintValueTextField;

//Identity Details
@property (weak) IBOutlet NSTextField *trustAnchorTextField;
@property (weak) IBOutlet NSTextField *trustAnchorValueTextField;
@property (weak) IBOutlet NSTextField *editIdentityDateAddedTextField;
@property (weak) IBOutlet NSTextField *dateAddedTitleTextField;
@property (weak) IBOutlet NSTextField *editUsernameTextField;
@property (weak) IBOutlet NSTextField *editUsernameValueTextField;
@property (weak) IBOutlet NSTextField *editRealmTextField;
@property (weak) IBOutlet NSTextField *editRealmValueTextField;
@property (weak) IBOutlet NSTextField *editPasswordTextField;
@property (weak) IBOutlet NSSecureTextField *editPasswordValueTextField;

@property (nonatomic, strong) TrustAnchorHelpWindow *helpWindow;
@property (nonatomic, retain) NSMutableArray *identitiesArray;
@property (nonatomic, retain) NSMutableArray *servicesArray;

@end

@implementation EditIdentityWindow

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupView];
}

#pragma mark - Setup View

- (void)setupView {
    [self loadSavedData];
    [self setupViewsVisibility];
    [self setupTextFields];
    [self setupButtons];
    [self setupTableViewHeader];
}

#pragma mark - Load Saved Data

- (void)loadSavedData {
    __weak __typeof__(self) weakSelf = self;
    [[MSTIdentityDataLayer sharedInstance] getAllIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        if (items) {
            weakSelf.identitiesArray = [items mutableCopy];
            weakSelf.servicesArray = weakSelf.identityToEdit.servicesArray;
        }
    }];
    
    if ([self.identityToEdit.username isEqualToString:@"No identity"]) {
        [self loadNoIdentityData];
    } else {
        [self.editUsernameValueTextField setStringValue:self.identityToEdit.username];
        [self.editRealmValueTextField setStringValue:self.identityToEdit.realm];
        [self.editPasswordValueTextField setStringValue:self.identityToEdit.password];
        [self.editIdentityDateAddedTextField setObjectValue: [NSDate formatDate:self.identityToEdit.dateAdded withFormat:@"HH:mm - dd/MM/yyyy"]];
        [self.editRememberPasswordButton setState:self.identityToEdit.passwordRemembered];
        [self.trustAnchorValueTextField setStringValue:self.identityToEdit.trustAnchor];
    }
}

#pragma mark - Load No Identity Data

- (void)loadNoIdentityData {
    [self.editUsernameValueTextField setStringValue:@"No Identity"];
    [self.editRealmValueTextField setStringValue:@"No Identity"];
    [self.editPasswordValueTextField setStringValue:@"No Identity"];
    [self.editIdentityDateAddedTextField setObjectValue:[NSDate date]];
    [self.editRememberPasswordButton setState:NO];
    [self.trustAnchorValueTextField setStringValue:@"None"];
    
    [self.editUsernameValueTextField setEnabled:NO];
    [self.editRealmValueTextField setEnabled:NO];
    [self.editPasswordValueTextField setEnabled:NO];
    [self.editIdentityDateAddedTextField setEnabled:NO];
    [self.editRememberPasswordButton setEnabled:NO];
//    [self.trustAnchorValueTextField setHidden:YES];
//    [self.trustAnchorTextField setHidden:YES];
}

#pragma mark - Setup Views Visibility

- (void)setupViewsVisibility {
    if (self.identityToEdit.caCertificate) {
        [self.shaFingerprintView setHidden:YES];
    } else if (![self.identityToEdit.trustAnchor isEqualToString:@"None"]) {
        [self.certificateView setHidden:YES];
    } else {
        [self.certificateView setHidden:YES];
        [self.shaFingerprintView setHidden:YES];
        [self.dateAddedTitleTextField setHidden:YES];
        [self.editIdentityDateAddedTextField setHidden:YES];
        [self.editIdentityHelpButton setHidden:YES];
        [self.clearTrustAnchorButton setHidden:YES];
        [self.trustAnchorValueTextField setStringValue:NSLocalizedString(@"None",@"")];
        [self.window setFrame:NSMakeRect(0, 0, self.window.frame.size.width, 465) display:YES];
        [self.servicesView setFrame:NSMakeRect(self.servicesView.frame.origin.x,10,self.servicesView.frame.size.width,self.servicesView.frame.size.height)];
    }
}

#pragma mark - Setup Text Fields

- (void)setupTextFields {
    [self.editUsernameTextField setStringValue:NSLocalizedString(@"Username_Add", @"")];
    [self.editRealmTextField setStringValue:NSLocalizedString(@"Realm_Add", @"")];
    [self.editPasswordTextField setStringValue:NSLocalizedString(@"Password_Add", @"")];
    [self.trustAnchorTextField setStringValue:NSLocalizedString(@"Trust_Anchor_Edit", @"")];
    [self.dateAddedTitleTextField setStringValue:NSLocalizedString(@"Date_Added", @"")];
    
    [self.caCertificateTextField setStringValue:NSLocalizedString(@"CA_Certificate", @"")];
    [self.subjectTextField setStringValue:NSLocalizedString(@"Subject", @"")];
    [self.expirationDateTextField setStringValue:NSLocalizedString(@"Expiration_Date", @"")];
    [self.constraintTextField setStringValue:NSLocalizedString(@"Constraint", @"")];
    [self.shaFingerprintTextField setStringValue:NSLocalizedString(@"SHA_Fingerprint", @"")];
    [self.editRememberPasswordButton setTitle:NSLocalizedString(@"Remember_Password", @"")];
    [self.servicesTitleTextField setStringValue:NSLocalizedString(@"Services_Edit", @"")];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self.clearTrustAnchorButton setTitle:NSLocalizedString(@"Clear_Trust_Anchor_Button", @"")];
    [self.editIdentityCancelButton setTitle:NSLocalizedString(@"Cancel_Button", @"")];
    [self.editIdentitySaveButton setTitle:NSLocalizedString(@"Save_Changes_Button", @"")];
}

#pragma mark - Setup TableView Header

- (void)setupTableViewHeader {
    [self.editIdentityServicesTableView.tableColumns.firstObject.headerCell setStringValue:NSLocalizedString(@"Service", @"")];
}

#pragma mark - Delete Services

- (void)deleteService {
    [self.servicesArray removeObjectAtIndex:self.editIdentityServicesTableView.selectedRow];
    [self.editIdentityServicesTableView reloadData];
    [self.editIdentityDeleteServiceButton setEnabled:NO];
}

#pragma mark - Button Actions


- (IBAction)singleAction:(id)sender {
    [self.editIdentityDeleteServiceButton setEnabled:YES];
}

- (IBAction)deleteServiceButtonPressed:(id)sender {
    __weak __typeof__(self) weakSelf = self;
    [self.window addAlertWithButtonTitle:NSLocalizedString(@"Delete_Button", @"") secondButtonTitle:NSLocalizedString(@"Cancel_Button", @"") messageText:[NSString stringWithFormat:NSLocalizedString(@"Delete_Service_Alert_Message", @""),self.servicesArray[self.editIdentityServicesTableView.selectedRow]] informativeText:NSLocalizedString(@"Alert_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                [weakSelf deleteService];
                break;
            default:
                break;
        }
    }];
}

- (IBAction)saveChangesButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(editIdentityWindow:wantsToEditIdentity:rememberPassword:)]) {
        self.identityToEdit.identityId = self.identityToEdit.identityId;
        self.identityToEdit.displayName = self.identityToEdit.displayName;
        self.identityToEdit.username = self.editUsernameValueTextField.stringValue;
        self.identityToEdit.realm = self.editRealmValueTextField.stringValue;
        self.identityToEdit.password = self.editPasswordValueTextField.stringValue;
        self.identityToEdit.passwordRemembered = self.editRememberPasswordButton.state;
        self.identityToEdit.dateAdded = self.identityToEdit.dateAdded;
        self.identityToEdit.servicesArray = self.servicesArray;
        self.identityToEdit.trustAnchor = self.identityToEdit.trustAnchor;
        [self.delegate editIdentityWindow:self.window wantsToEditIdentity:self.identityToEdit rememberPassword:self.editRememberPasswordButton.state];
    }
}

- (IBAction)cancelChangesButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(editIdentityWindowCanceled:)]) {
        [self.delegate editIdentityWindowCanceled:self.window];
    }
}

- (IBAction)helpButtonPressed:(id)sender {
    self.helpWindow = [[TrustAnchorHelpWindow alloc] initWithWindowNibName: NSStringFromClass([TrustAnchorHelpWindow class])];
    [self.helpWindow showWindow:self];;
}

- (IBAction)clearTrustAnchorPressed:(id)sender {
    [self.window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:NSLocalizedString(@"Alert_Import_Message", @"") informativeText:NSLocalizedString(@"Alert_Import_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                //TODO: clear TrustAnchor
                break;
            default:
                break;
        }
    }];
}

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    [self.editIdentitySaveButton setEnabled:[self isRequiredDataFilled]];
}

- (BOOL)isRequiredDataFilled {
    BOOL editIdentityButtonDisabled = [self.editUsernameValueTextField.stringValue isEqualToString:@""] ||
    [self.editRealmValueTextField.stringValue isEqualToString:@""] ||
    [self.editPasswordValueTextField.stringValue isEqualToString:@""];
    return !editIdentityButtonDisabled;
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.servicesArray count] ?: 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"editIdentityIdentifier" owner:self];
    if ([self.servicesArray count] > 0) {
        cellView.textField.stringValue = [self.servicesArray objectAtIndex:row];
    }
    return cellView;
}

@end
