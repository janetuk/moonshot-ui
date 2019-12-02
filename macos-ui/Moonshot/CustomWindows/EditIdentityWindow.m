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
#import "MSTConstants.h"
#import "X509Cert.h"

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
@property (weak) IBOutlet NSButton *editHas2FAButton;
@property (weak) IBOutlet NSButton *clearTrustAnchorButton;
@property (weak) IBOutlet NSButton *editIdentityHelpButton;

//Certificate View
@property (weak) IBOutlet NSView *certificateView;
@property (weak) IBOutlet NSTextField *caCertificateTextField;
@property (weak) IBOutlet NSTextField *caCertificateValueTextField;
@property (weak) IBOutlet NSTextField *subjectTextField;
@property (weak) IBOutlet NSTextField *subjectValueTextField;
@property (weak) IBOutlet NSTextField *expirationDateTextField;
@property (weak) IBOutlet NSTextField *expirationDateValueTextField;
@property (weak) IBOutlet NSView *topSeparator;
@property (weak) IBOutlet NSView *bottomSeparator;
@property (weak) IBOutlet NSButton *exportCertificateButton;
@property (weak) IBOutlet NSButton *showCertificateButton;

//Fingerprint View
@property (strong) IBOutlet NSView *shaFingerprintView;
@property (weak) IBOutlet NSTextField *shaFingerprintTextField;
@property (weak) IBOutlet NSTextField *shaFingerprintValueTextField;
@property (weak) IBOutlet NSView *shaFingerprintTopSeparator;
@property (weak) IBOutlet NSView *shaFingerprintBottomSeparator;

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
    [self setupSeparators];
    [self loadSavedData];
    [self setupViewsVisibility];
    [self setupTextFields];
    [self setupButtons];
    [self setupTableViewHeaders];
}

#pragma mark - Setup Separators

- (void)setupSeparators {
    [self.topSeparator setWantsLayer:YES];
    self.topSeparator.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
    [self.bottomSeparator setWantsLayer:YES];
    self.bottomSeparator.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
    
    [self.shaFingerprintTopSeparator setWantsLayer:YES];
    self.shaFingerprintTopSeparator.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
    [self.shaFingerprintBottomSeparator setWantsLayer:YES];
    self.shaFingerprintBottomSeparator.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
}

#pragma mark - Load Saved Data

- (void)loadSavedData {
    __weak __typeof__(self) weakSelf = self;
    [[MSTIdentityDataLayer sharedInstance] getAllIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        if (items) {
            weakSelf.identitiesArray = [items mutableCopy];
            weakSelf.servicesArray = weakSelf.identityToEdit.servicesArray;
            NSLog(@"SLEECTION RULES: %d", [weakSelf.identityToEdit.selectionRules count]);
        }
    }];
    
    if ([self.identityToEdit.identityId isEqualToString:MST_NO_IDENTITY]) {
        [self loadNoIdentityData];
    } else {
        [self.editUsernameValueTextField setStringValue:self.identityToEdit.username];
        [self.editRealmValueTextField setStringValue:self.identityToEdit.realm];
        [self.editPasswordValueTextField setStringValue:self.identityToEdit.password];
        [self.editIdentityDateAddedTextField setObjectValue: [NSDate formatDate:self.identityToEdit.dateAdded withFormat:@"HH:mm - dd/MM/yyyy"]];
        [self.editRememberPasswordButton setState:self.identityToEdit.passwordRemembered];
        [self.editHas2FAButton setState:self.identityToEdit.has2fa];
        [self.trustAnchorValueTextField setStringValue:self.trustAnchorObject ? NSLocalizedString(@"Enterprise_provisioned", @"") : NSLocalizedString(@"None",@"")];
    }
}

#pragma mark - Load No Identity Data

- (void)loadNoIdentityData {
    [self.editUsernameValueTextField setStringValue:@"No Identity"];
    [self.editRealmValueTextField setStringValue:@""];
    [self.editPasswordValueTextField setStringValue:@""];
    [self.editIdentityDateAddedTextField setStringValue:@""];
    [self.editRememberPasswordButton setState:YES];
    [self.editHas2FAButton setState:NO];
    [self.trustAnchorValueTextField setStringValue:NSLocalizedString(@"None",@"")];
    
    [self.editUsernameValueTextField setEnabled:NO];
    [self.editRealmValueTextField setEnabled:NO];
    [self.editPasswordValueTextField setEnabled:NO];
    [self.editIdentityDateAddedTextField setEnabled:NO];
    [self.editRememberPasswordButton setEnabled:NO];
    [self.editHas2FAButton setEnabled:NO];
}

#pragma mark - Setup Views Visibility

- (void)setupViewsVisibility {
    if (self.identityToEdit.trustAnchor.caCertificate.length > 0) {
        [self.certificateView setHidden:NO];
        [self.shaFingerprintView setHidden:YES];
        [self.trustAnchorValueTextField setStringValue:NSLocalizedString(@"Enterprise_provisioned", @"")];
        [self.caCertificateValueTextField setStringValue:NSLocalizedString(@"Yes", @"")];
        [self.subjectValueTextField setStringValue:self.identityToEdit.trustAnchor.subject];
        X509Cert* cert = [[X509Cert alloc] initWithB64String:self.trustAnchorObject.caCertificate];
        [self.expirationDateValueTextField setStringValue:cert.expirationDate];
    } else if (self.identityToEdit.trustAnchor.serverCertificate.length > 0) {
        [self.certificateView setHidden:YES];
        [self.shaFingerprintView setHidden:NO];
        [self.trustAnchorValueTextField setStringValue:NSLocalizedString(@"Enterprise_provisioned", @"")];
		[self.shaFingerprintValueTextField setStringValue:[TrustAnchor stringByAddingDots:self.trustAnchorObject.serverCertificate]];
	} else {
        [self.certificateView setHidden:YES];
        [self.shaFingerprintView setHidden:YES];
        [self.dateAddedTitleTextField setHidden:YES];
        [self.editIdentityDateAddedTextField setHidden:YES];
        [self.editIdentityHelpButton setHidden:YES];
        [self.clearTrustAnchorButton setHidden:YES];
        [self.trustAnchorValueTextField setStringValue:NSLocalizedString(@"None",@"")];
        [self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y, self.window.frame.size.width, self.window.frame.size.height - self.certificateView.frame.size.height) display:YES];
        [self.servicesView setFrame:NSMakeRect(self.servicesView.frame.origin.x, self.servicesView.frame.origin.y + self.certificateView.frame.size.height, self.servicesView.frame.size.width, self.servicesView.frame.size.height)];

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
    [self.shaFingerprintTextField setStringValue:NSLocalizedString(@"SHA_Fingerprint", @"")];
    [self.editRememberPasswordButton setTitle:NSLocalizedString(@"Remember_Password", @"")];
    [self.editHas2FAButton setTitle:NSLocalizedString(@"Has_2FA", @"")];
    [self.servicesTitleTextField setStringValue:NSLocalizedString(@"Services_Edit", @"")];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self.clearTrustAnchorButton setTitle:NSLocalizedString(@"Clear_Trust_Anchor_Button", @"")];
    [self.editIdentityCancelButton setTitle:NSLocalizedString(@"Cancel_Button", @"")];
    [self.editIdentitySaveButton setTitle:NSLocalizedString(@"Save_Changes_Button", @"")];
    [self.exportCertificateButton setTitle:NSLocalizedString(@"Export_Certificate", @"")];
    [self.showCertificateButton setTitle:NSLocalizedString(@"Show_Certificate", @"")];
}

#pragma mark - Setup TableView Header

- (void)setupTableViewHeaders {
    [self.editIdentityServicesTableView.tableColumns.firstObject.headerCell setStringValue:NSLocalizedString(@"Service", @"")];
}

#pragma mark - Delete Services
- (void)deleteService {
    [self.servicesArray removeObjectAtIndex:self.editIdentityServicesTableView.selectedRow];
    [self.editIdentityServicesTableView reloadData];
    [self.editIdentityDeleteServiceButton setEnabled:NO];
}

- (void)clearTrustAnchor {
	self.identityToEdit.trustAnchor = nil;
	[self loadSavedData];
	[self setupViewsVisibility];
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

- (IBAction)editIdentityRememberPasswordButtonPressed:(id)sender {
    if ([self isRequiredDataFilled]) {
        if ([self isPasswordMandatory])
            [self.editIdentitySaveButton setEnabled:NO];
        else
            [self.editIdentitySaveButton setEnabled:YES];
    } else
        [self.editIdentitySaveButton setEnabled:NO];
}

- (IBAction)saveChangesButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(editIdentityWindow:wantsToEditIdentity:rememberPassword:)]) {
        self.identityToEdit.identityId = self.identityToEdit.identityId;
        self.identityToEdit.displayName = self.identityToEdit.displayName;
        self.identityToEdit.username = self.editUsernameValueTextField.stringValue;
        self.identityToEdit.realm = self.editRealmValueTextField.stringValue;
        self.identityToEdit.has2fa = self.editHas2FAButton.state;
        self.identityToEdit.passwordRemembered = self.editRememberPasswordButton.state;
        if (self.identityToEdit.passwordRemembered) {
            self.identityToEdit.password = self.editPasswordValueTextField.stringValue;
        } else {
            self.identityToEdit.password = @"";
        }
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
	__weak __typeof__(self) weakSelf = self;
    [self.window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:NSLocalizedString(@"Cancel_Button", @"") messageText:NSLocalizedString(@"Alert_Clear_Trust_Anchor_Message", @"") informativeText:NSLocalizedString(@"Alert_Clear_Trust_Anchor_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
				[weakSelf clearTrustAnchor];
                break;
            default:
                break;
        }
    }];
}

- (IBAction)exportCertificateButtonPressed:(id)sender {
	NSString *fileName = [NSString stringWithFormat:@"%@.cert", self.identityToEdit.displayName];
	NSString *fileContent = self.identityToEdit.trustAnchor.caCertificate;

	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setPrompt:@"Export"];
	[savePanel setNameFieldStringValue:fileName];
	[savePanel beginWithCompletionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
			NSURL *saveURL = [savePanel URL];
			[[NSFileManager defaultManager] createFileAtPath:[saveURL path]
													contents:[fileContent dataUsingEncoding:NSUTF8StringEncoding]
												  attributes:nil];
		}
	}];
}

- (IBAction)showCertificateButtonPressed:(id)sender {
    X509Cert* cert = [[X509Cert alloc]initWithB64String:self.identityToEdit.trustAnchor.caCertificate];
    NSTextView *accessory = [[NSTextView alloc] initWithFrame:NSMakeRect(0,0,500,300)];
    [accessory setString:cert.textsummary];
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

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    if ([self isPasswordMandatory]) {
        [self.editIdentitySaveButton setEnabled:NO];
    } else {
        [self.editIdentitySaveButton setEnabled:[self isRequiredDataFilled]];
    }
}

#pragma mark - Required data

- (BOOL)isRequiredDataFilled {
    BOOL editIdentityButtonDisabled = [self.editUsernameValueTextField.stringValue isEqualToString:@""] ||
    [self.editRealmValueTextField.stringValue isEqualToString:@""];
    return !editIdentityButtonDisabled;
}

- (BOOL)isPasswordMandatory {
    BOOL isPasswordMandatory = self.editRememberPasswordButton.state == NSOnState &&
    [self.editPasswordValueTextField.stringValue isEqualToString:@""];
    return isPasswordMandatory;
}

#pragma mark - NSTableViewDelegate & NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.editIdentityServicesTableView) {
        return [self.servicesArray count] ?: 0;
    } else {
        return 0;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.editIdentityServicesTableView) {
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"editIdentityServicesIdentifier" owner:self];
        if ([self.servicesArray count] > 0) {
            cellView.textField.stringValue = [self.servicesArray objectAtIndex:row];
        }
        return cellView;
    } else {
        return nil;
    }
}

@end
