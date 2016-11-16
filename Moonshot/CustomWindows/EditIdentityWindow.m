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

@interface EditIdentityWindow ()<NSTextFieldDelegate, NSTableViewDataSource, NSTabViewDelegate>
@property (weak) IBOutlet NSTextField *rememberPasswordTextField;
@property (weak) IBOutlet NSTextField *shaFingerprintTextField;
@property (weak) IBOutlet NSTextField *trustAnchorValueTextField;
@property (weak) IBOutlet NSTextField *constraintValueTextField;
@property (weak) IBOutlet NSTextField *constraintTextField;
@property (weak) IBOutlet NSTextField *expirationDateValueTextField;
@property (weak) IBOutlet NSTextField *expirationDateTextField;
@property (weak) IBOutlet NSTextField *subjectValueTextField;
@property (weak) IBOutlet NSTextField *subjectTextField;
@property (weak) IBOutlet NSTextField *caCertificateTextField;
@property (weak) IBOutlet NSTextField *editIdentityDateAddedTextField;
@property (weak) IBOutlet NSTextField *servicesTitleTextField;
@property (weak) IBOutlet NSTextField *trustAnchorTextField;
@property (weak) IBOutlet NSTextField *dateAddedTitleTextField;
@property (weak) IBOutlet NSTextField *editUsernameValueTextField;
@property (weak) IBOutlet NSTextField *editRealmValueTextField;
@property (weak) IBOutlet NSTextField *editUsernameTextField;
@property (weak) IBOutlet NSTextField *editRealmTextField;
@property (weak) IBOutlet NSTextField *editPasswordTextField;
@property (weak) IBOutlet NSSecureTextField *editPasswordValueTextField;
@property (weak) IBOutlet NSButton *editRememberPasswordButton;
@property (weak) IBOutlet NSButton *clearTrustAnchorButton;
@property (weak) IBOutlet NSButton *editIdentityDeleteServiceButton;
@property (weak) IBOutlet NSButton *editIdentityCancelButton;
@property (weak) IBOutlet NSButton *editIdentitySaveButton;
@property (weak) IBOutlet NSButton *editIdentityHelpButton;
@property (weak) IBOutlet NSTableView *editIdentityServicesTableView;
@property (weak) IBOutlet NSView *servicesView;
@property (weak) IBOutlet NSView *certificateView;
@property (strong) IBOutlet NSView *shaFingerprintView;
@property (nonatomic, strong) TrustAnchorHelpWindow *helpWindow;
@property (nonatomic, retain) NSMutableArray *identitiesArray;
@property (nonatomic, retain) NSMutableArray *servicesArray;

@end

@implementation EditIdentityWindow

static BOOL runClearTrustAnchorAlertAgain;
static BOOL runDeleteServiceAlertAgain;

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupView];
    runClearTrustAnchorAlertAgain = YES;
    runDeleteServiceAlertAgain = YES;
}

#pragma mark - Setup View

- (void)setupView {
    [self loadSavedData];
    [self setupViewsVisibility];
    [self setupTextFields];
    [self setupButtons];
    [self setupTableViewHeader];
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
    [self.rememberPasswordTextField setStringValue:NSLocalizedString(@"Remember_Password", @"")];
    [self.servicesTitleTextField setStringValue:NSLocalizedString(@"Services_Edit", @"")];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self.clearTrustAnchorButton setTitle:NSLocalizedString(@"Clear_Trust_Anchor_Button", @"")];
    [self.editIdentityCancelButton setTitle:NSLocalizedString(@"Cancel_Button", @"")];
    [self.editIdentitySaveButton setTitle:NSLocalizedString(@"Save_Changes_Button", @"")];
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

#pragma mark - Setup TableView Header

- (void)setupTableViewHeader {
    [self.editIdentityServicesTableView.tableColumns.firstObject.headerCell setStringValue:NSLocalizedString(@"Service", @"")];
}

#pragma mark - Load Saved Data

- (void)loadSavedData {
    [[MSTIdentityDataLayer sharedInstance] getAllIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        if (items) {
            self.identitiesArray = [items mutableCopy];
            self.servicesArray = self.identityToEdit.servicesArray;
        }
    }];
    [self.editUsernameValueTextField setStringValue:self.identityToEdit.username];
    [self.editRealmValueTextField setStringValue:self.identityToEdit.realm];
    [self.editPasswordValueTextField setStringValue:self.identityToEdit.password];
    [self.editIdentityDateAddedTextField setObjectValue: [NSDate formatDate:self.identityToEdit.dateAdded withFormat:@"HH:mm - dd/MM/yyyy"]];
    [self.editRememberPasswordButton setState:self.identityToEdit.passwordRemembered];
    [self.trustAnchorValueTextField setStringValue:self.identityToEdit.trustAnchor];
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
    if (runDeleteServiceAlertAgain == NO) {
        [self deleteService];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Delete_Button", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel_Button", @"")];
        [alert setMessageText:[NSString stringWithFormat:NSLocalizedString(@"Delete_Service_Alert_Message", @""),self.servicesArray[self.editIdentityServicesTableView.selectedRow]]];
        [alert setInformativeText:NSLocalizedString(@"Alert_Info", @"")];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setShowsSuppressionButton:YES];
        [[alert suppressionButton] setTitle:NSLocalizedString(@"Alert_Suppression_Message", @"")];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn:
                    runDeleteServiceAlertAgain = (BOOL)![[alert suppressionButton] state];
                    [self deleteService];
                    break;
                default:
                    break;
            }
        }];
    }
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
    if (runClearTrustAnchorAlertAgain == NO) {
        //TODO: clear TrustAnchor
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"OK_Button", @"")];
        //[alert addButtonWithTitle:NSLocalizedString(@"Cancel_Button", @"")];
        [alert setMessageText: NSLocalizedString(@"Alert_Import_Message", @"")];
        [alert setInformativeText:NSLocalizedString(@"Alert_Import_Info", @"")];
        [alert setAlertStyle:NSWarningAlertStyle];
        //[alert setShowsSuppressionButton:YES];
        [[alert suppressionButton] setTitle:NSLocalizedString(@"Alert_Suppression_Message", @"")];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn:
                    runDeleteServiceAlertAgain = (BOOL)![[alert suppressionButton] state];
                    //TODO: clear TrustAnchor
                    break;
                default:
                    break;
            }
        }];
    }
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
    return [self.servicesArray count] ?: 1;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"editIdentityIdentifier" owner:self];
    if ([self.servicesArray count] > 0) {
        cellView.textField.stringValue = [self.servicesArray objectAtIndex:row];
    } else {
        cellView.textField.stringValue = @"No services";
    }
    return cellView;
}

@end
