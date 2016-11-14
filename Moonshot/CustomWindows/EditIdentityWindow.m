//
//  EditIdentityWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/25/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import "EditIdentityWindow.h"
#import "Identity.h"
#import "TrustAnchorHelpWindow.h"
#import "NSDate+NSDateFormatter.h"

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
@property (nonatomic, retain) NSMutableArray *identitiesArray;
@property (nonatomic, retain) NSMutableArray *servicesArray;
@property (nonatomic, strong) TrustAnchorHelpWindow *helpWindow;

@end

@implementation EditIdentityWindow

static BOOL runClearTrustAnchorAlertAgain;
static BOOL runDeleteServiceAlertAgain;

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    self.servicesArray = [NSMutableArray arrayWithObjects:@"google.com",@"developer.apple.com",@"dev.ja.net",@"devsy.com",nil];
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
    Identity *identityObject = [[Identity alloc] init];
    if (identityObject.caCertificate) {
        [self.shaFingerprintView setHidden:YES];
    } else if (identityObject.trustAnchor) {
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
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"Identities_Array"] != nil) {
        NSData *encodedObject = [userDefaults objectForKey:@"Identities_Array"];
        [self.identitiesArray removeAllObjects];
        self.identitiesArray = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
    }
    Identity *identityObject = [self.identitiesArray objectAtIndex:self.index];
    [self.editUsernameValueTextField setStringValue:identityObject.username];
    [self.editRealmValueTextField setStringValue:identityObject.realm];
    [self.editPasswordValueTextField setStringValue:identityObject.password];
    [self.editIdentityDateAddedTextField setObjectValue: [NSDate formatDate:identityObject.dateAdded withFormat:@"HH:mm - dd/MM/yyyy"]];
    
    [self.editRememberPasswordButton setState:identityObject.passwordRemembered];
}

#pragma mark - Delete Services

- (void)deleteService {
    [self.servicesArray removeObjectAtIndex:self.editIdentityServicesTableView.selectedRow];
    [self.editIdentityServicesTableView reloadData];
    [self.editIdentityDeleteServiceButton setEnabled:NO];
}

#pragma mark - Button Actions

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
        Identity *identityObject = [[Identity alloc] init];
        identityObject.identityId = [[self.identitiesArray objectAtIndex:self.index] valueForKey:@"identityId"];
        identityObject.displayName = [[self.identitiesArray objectAtIndex:self.index] valueForKey:@"displayName"];
        identityObject.username = self.editUsernameValueTextField.stringValue;
        identityObject.realm = self.editRealmValueTextField.stringValue;
        identityObject.password = self.editPasswordValueTextField.stringValue;
        identityObject.passwordRemembered = self.editRememberPasswordButton.state;
        identityObject.dateAdded = [[self.identitiesArray objectAtIndex:self.index] valueForKey:@"dateAdded"];
        [self.delegate editIdentityWindow:self.window wantsToEditIdentity:identityObject rememberPassword:self.editRememberPasswordButton.state];
    }
}

- (IBAction)cancelChangesButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(editIdentityWindowCanceled:)]) {
        [self.delegate editIdentityWindowCanceled:self.window];
    }
}

- (IBAction)helpButtonPressed:(id)sender {
    self.helpWindow = [[TrustAnchorHelpWindow alloc] initWithWindowNibName:@"TrustAnchorHelpWindow"];
    [self.helpWindow showWindow:self];;
}

- (IBAction)clearTrustAnchorPressed:(id)sender {
    if (runClearTrustAnchorAlertAgain == NO) {
        //TODO: clear TrustAnchor
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"OK_Button", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel_Button", @"")];
        [alert setMessageText: NSLocalizedString(@"Clear_Trust_Anchor_Alert_Message", @"")];
        [alert setInformativeText:NSLocalizedString(@"Alert_Info", @"")];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setShowsSuppressionButton:YES];
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

- (IBAction)singleAction:(id)sender {
    [self.editIdentityDeleteServiceButton setEnabled:YES];
}
@end
