//
//  MSTIdentitySelectorViewController.m
//  Moonshot
//
//  Created by Elena Jakjoska on 11/25/16.
//

#import "MSTIdentitySelectorViewController.h"
#import "AddIdentityWindow.h"
#import "ConnectIdentityWindow.h"
#import "MSTIdentityDataLayer.h"
#import "Identity.h"
#import "NSWindow+Utilities.h"
#import "AppDelegate.h"
#import "Identity+Utilities.h"
#import "MSTConstants.h"

@interface MSTIdentitySelectorViewController ()<AddIdentityWindowDelegate, ConnectIdentityWindowDelegate>

//Content View
@property (weak) IBOutlet NSTableView *identitySelectorTableView;
@property (weak) IBOutlet NSTextField *identitySelectorTitleTextField;
@property (weak) IBOutlet NSTextField *identitySelectorServiceTitleTextField;
@property (weak) IBOutlet NSTextField *identitySelectorServiceValueTextField;

//Button Actions
@property (weak) IBOutlet NSButton *identitySelectorRememberChoiceButton;
@property (weak) IBOutlet NSButton *identitySelectorHelpButton;
@property (weak) IBOutlet NSButton *identitySelectorCreateIdentityButton;
@property (weak) IBOutlet NSButton *identitySelectorConnectButton;

@property (nonatomic, strong) AddIdentityWindow *addIdentityWindow;
@property (nonatomic, strong) ConnectIdentityWindow *connectIdentityWindow;
@property (nonatomic, retain) NSMutableArray *identitiesArray;

@end

@implementation MSTIdentitySelectorViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getSavedIdentities];
    [self setupView];
}

#pragma mark - Setup View

- (void)setupView {
    [self setupTextFields];
    [self setupButtons];
    [self setupTableViewHeader];
}

#pragma mark - Setup TextFields

- (void)setupTextFields {
    [self.identitySelectorTitleTextField setStringValue:NSLocalizedString(@"Select_Identity_Title", @"")];
    [self.identitySelectorServiceTitleTextField setStringValue:NSLocalizedString(@"Requested_Identity_Title", @"")];
    [self.identitySelectorServiceValueTextField setStringValue:self.service];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self.identitySelectorRememberChoiceButton setTitle:NSLocalizedString(@"Remember_Identity_Choice_Button", @"")];
    [self.identitySelectorCreateIdentityButton setTitle:NSLocalizedString(@"Create_Identity_Button", @"")];
    [self.identitySelectorConnectButton setTitle:NSLocalizedString(@"Connect_Identity_Button", @"")];
}

#pragma mark - Setup TableView Header

- (void)setupTableViewHeader {
    [self.identitySelectorTableView.tableColumns.firstObject.headerCell setStringValue:NSLocalizedString(@"Name", @"")];
    [self.identitySelectorTableView.tableColumns.lastObject.headerCell setStringValue:NSLocalizedString(@"Service", @"")];
}

#pragma mark - Get Saved Identities

- (void)getSavedIdentities {
    __weak __typeof__(self) weakSelf = self;
    [[MSTIdentityDataLayer sharedInstance] getAllIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        if (items) {
            weakSelf.identitiesArray = [NSMutableArray arrayWithArray:items];
            [weakSelf.identitySelectorTableView reloadData];
        }
    }];
}

#pragma mark - Reload Data

- (void)reloadDetailsViewWithIdentityData:(BOOL)data {
    if (!data) {
        [self.identitySelectorServiceValueTextField setStringValue:@""];
    } else {
        Identity *identityObject = [self.identitiesArray objectAtIndex:self.identitySelectorTableView.selectedRow];
        if ([self.identitiesArray count] > 0) {
            [self.identitySelectorServiceValueTextField setStringValue:[Identity getServicesStringForIdentity:identityObject]];
        }
    }
}

#pragma mark - NSTableViewDataSource & NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.identitiesArray count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"nameCellIdentifier" owner:self];
    Identity *identityObject = [self.identitiesArray objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"nameIdentifier"]) {
        cellView.textField.stringValue = identityObject.displayName;
        cellView.imageView.image = [NSImage imageNamed:@"user_info_thumbnail"];
    } else {
        [cellView.textField setStringValue:[Identity getServicesStringForIdentity:identityObject]];
        cellView.imageView.image = [NSImage imageNamed:@"service"];
    }
    return cellView;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors {
    NSArray *newDescriptors = [tableView sortDescriptors];
    [self.identitiesArray sortUsingDescriptors:newDescriptors];
    [tableView reloadData];
}

- (IBAction)singleAction:(id)sender {
    if (self.identitySelectorTableView.selectedRow != -1) {
        [self reloadDetailsViewWithIdentityData:YES];
    } else {
        [self reloadDetailsViewWithIdentityData:NO];
    }
}

#pragma mark - Buttons Actions

- (IBAction)identitySelectorHelpButtonPressed:(id)sender {
}

- (IBAction)identitySelectorCreateIdentityButtonPressed:(id)sender {
    self.addIdentityWindow = [[AddIdentityWindow alloc] initWithWindowNibName:NSStringFromClass([AddIdentityWindow class])];
    self.addIdentityWindow.delegate = self;
    [self.view.window beginSheet:self.addIdentityWindow.window  completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSModalResponseOK:
                break;
            case NSModalResponseCancel:
                break;
            default:
                break;
        }
    }];
}

- (IBAction)identitySelectorConnectButtonPressed:(id)sender {
    if (self.identitySelectorTableView.selectedRow == -1) {
        [self.view.window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:NSLocalizedString(@"Alert_No_Identity_Selected_Message", @"") informativeText:NSLocalizedString(@"Alert_No_Identity_Selected_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn:
                    break;
                default:
                    break;
            }
        }];
    } else {
        Identity *identityObject = [self.identitiesArray objectAtIndex:self.identitySelectorTableView.selectedRow];
        if (identityObject.passwordRemembered) {
            if (self.service) {
                [identityObject.servicesArray addObject:self.service];
                [self showAlertForIdentitysEditingStatusForIdentity:identityObject];
            }
        } else {
            self.connectIdentityWindow = [[ConnectIdentityWindow alloc] initWithWindowNibName:NSStringFromClass([ConnectIdentityWindow class])];
            self.connectIdentityWindow.delegate = self;
            [identityObject.servicesArray addObject:self.service];
            self.connectIdentityWindow.identityObject = identityObject;
            [self.view.window beginSheet:self.connectIdentityWindow.window  completionHandler:^(NSModalResponse returnCode) {
                switch (returnCode) {
                    case NSModalResponseOK:
                        break;
                    case NSModalResponseCancel:
                        break;
                    default:
                        break;
                }
            }];
        }
    }
}

#pragma mark - AddIdentity Delegate

- (void)addIdentityWindowCanceled:(NSWindow *)window {
    [[self.view window] endSheet:window];
}

- (void)addIdentityWindow:(NSWindow *)window wantsToAddIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword {
    __weak __typeof__(self) weakSelf = self;
    [[MSTIdentityDataLayer sharedInstance] addNewIdentity:identity withBlock:^(NSError *error) {
        if (!error) {
            [weakSelf getSavedIdentities];
            [[weakSelf.view window] endSheet:window];
        } else {
            [window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:NSLocalizedString(@"Alert_Add_Identity_Error_Message", @"") informativeText:NSLocalizedString(@"Alert_Error_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
                switch (returnCode) {
                    case NSAlertFirstButtonReturn:
                        break;
                    default:
                        break;
                }
            }];
        }
    }];
}

#pragma mark - ConnectIdentity Delegate

- (void)connectIdentityWindow:(NSWindow *)window wantsToConnectIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword {
    BOOL *isPasswordCorrect = NO;//added for now
    if (isPasswordCorrect) {
        [self showAlertForIdentitysEditingStatusForIdentity:identity];
    } else {
        [window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@""  messageText:NSLocalizedString(@"Alert_Incorrect_User_Pass_Messsage", @"")  informativeText:NSLocalizedString(@"Alert_Incorrect_User_Pass_Info", @"")  alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn:
                    break;
                default:
                    break;
            }
        }];
    }
}

- (void)connectIdentityWindowCanceled:(NSWindow *)window {
    [[self.view window] endSheet:window];
}

#pragma mark - 

- (void)showAlertForIdentitysEditingStatusForIdentity:(Identity *)identity {
    [[MSTIdentityDataLayer sharedInstance] editIdentity:identity withBlock:^(NSError *error) {
        AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        delegate.ongoingIdentitySelectAction.selectedIdentity = identity;
    }];
}
@end
