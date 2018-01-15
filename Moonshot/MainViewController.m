//
//  ViewController.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/13/16.
//

#import "MainViewController.h"
#import "AddIdentityWindow.h"
#import "EditIdentityWindow.h"
#import "Identity.h"
#import "MSTIdentityDataLayer.h"
#import "MSTConstants.h"
#import "NSWindow+Utilities.h"
#import "Identity+Utilities.h"
#import "NSString+GUID.h"
#import "SelectionRules.h"
#import "TrustAnchor.h"
#import "MSTIdentityImporter.h"

@interface MainViewController()<NSTableViewDataSource, NSTableViewDelegate, AddIdentityWindowDelegate, EditIdentityWindowDelegate>

//Menu
@property (strong) IBOutlet NSMenu *optionsMenu;
@property (weak) IBOutlet NSMenuItem *editIdentityMenuItem;
@property (weak) IBOutlet NSMenuItem *removeIdentityMenuItem;

//View
@property (weak) IBOutlet NSSearchField *searchField;

//Content View
@property (weak) IBOutlet NSView *contentView;
@property (weak) IBOutlet NSImageView *contentViewBackgroundImage;
@property (weak) IBOutlet NSTableView *identitiesTableView;

//Buttons Actions
@property (weak) IBOutlet NSButton *addIdentityButton;
@property (weak) IBOutlet NSButton *deleteIdentityButton;
@property (weak) IBOutlet NSButton *importButton;
@property (weak) IBOutlet NSButton *infoButton;

//Details View
@property (weak) IBOutlet NSView *detailsView;
@property (weak) IBOutlet NSTextField *displayNameTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSTextField *usernameValueTextField;
@property (weak) IBOutlet NSTextField *realmTextField;
@property (weak) IBOutlet NSTextField *realmValueTextField;
@property (weak) IBOutlet NSTextField *trustAnchorTextField;
@property (weak) IBOutlet NSTextField *trustAnchorValueTextField;
@property (weak) IBOutlet NSTextField *servicesTextField;
@property (weak) IBOutlet NSTextField *servicesValueTextField;
@property (weak) IBOutlet NSImageView *backgroundImageView;
@property (weak) IBOutlet NSImageView *userImageView;

@property (nonatomic, retain) NSMutableArray *identitiesArray;
@property (nonatomic, strong) AddIdentityWindow *addIdentityWindow;
@property (nonatomic, strong) EditIdentityWindow *editIdentityWindow;
@property (nonatomic, strong) MSTIdentityImporter *identityImporter;

@end

@implementation MainViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self getSavedIdentities];
    [self setupView];
    [self registerForNSNotifications];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)viewWillDisappear {
    [self deregisterForNSNotifications];
}

- (void)dealloc {
    [self deregisterForNSNotifications];
}

#pragma mark - Setup Views

- (void)setupView {
    [self setupMenu];
    [self setupContentView];
    [self setupDetailsView];
    [self setupImportButton];
    [self setupTableViewHeader];
    [self setupUserImageView];
    [self setupBackgroundImageView];
}

- (void)setupMenu {
    [self.optionsMenu setAutoenablesItems:NO];
    [self setupMenuItems];
}

- (void)setupMenuItems {
    [self.editIdentityMenuItem setTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Menu_Edit", @""), NSLocalizedString(@"Menu_Identity", @"")]];
    [self.removeIdentityMenuItem setTitle: [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Menu_Remove", @""), NSLocalizedString(@"Menu_Identity", @"")]];
}

- (void)setupContentView {
    [self.contentView.layer setBackgroundColor:[NSColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1].CGColor];
    self.contentView.layer.cornerRadius = 5.0;
}

- (void)setupDetailsView {
    [self.usernameTextField setStringValue:NSLocalizedString(@"Username", @"")];
    [self.realmTextField setStringValue:NSLocalizedString(@"Realm", @"")];
    [self.trustAnchorTextField setStringValue:NSLocalizedString(@"Trust_Anchor", @"")];
    [self.servicesTextField setStringValue:NSLocalizedString(@"Services", @"")];
}

- (void)setupBackgroundImageView {
    [self.backgroundImageView setWantsLayer:YES];
    self.backgroundImageView.layer.borderWidth = 1.0;
    self.backgroundImageView.layer.masksToBounds = YES;
    [self.backgroundImageView.layer setBorderColor:[NSColor lightGrayColor].CGColor];
}

#pragma mark - Setup Import Button

- (void)setupImportButton {
    [self.importButton setTitle:NSLocalizedString(@"Import_Button", @"")];
}

#pragma mark - Setup User ImageView

- (void)setupUserImageView {
    self.userImageView.image = [NSImage imageNamed:@"user_info_large"];
}

#pragma mark - Setup TableView Header

- (void)setupTableViewHeader {
    [self.identitiesTableView.tableColumns.firstObject.headerCell setStringValue:NSLocalizedString(@"Name", @"")];
}

#pragma mark - Get Saved Identities

- (void)getSavedIdentities {
    __weak __typeof__(self) weakSelf = self;
    [[MSTIdentityDataLayer sharedInstance] getAllIdentitiesWithBlock:^(NSArray<Identity *> *items) {
        if (items) {
            weakSelf.identitiesArray = [NSMutableArray arrayWithArray:items];
            [weakSelf.identitiesTableView reloadData];
        }
    }];
}

#pragma mark - Reload Data

- (void)reloadDetailsViewWithIdentityData:(BOOL)data {
    if (!data) {
        [self.displayNameTextField setStringValue: @""];
        [self.usernameValueTextField setStringValue: @""];
        [self.realmValueTextField setStringValue: @""];
        [self.trustAnchorValueTextField setStringValue:@""];
        [self.servicesValueTextField setStringValue:@""];
    } else {
        Identity *identityObject = [self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow];
        if ([self.identitiesArray count] > 0) {
            [self.displayNameTextField setStringValue: identityObject.displayName];
            [self.usernameValueTextField setStringValue: identityObject.username];
            [self.realmValueTextField setStringValue: identityObject.realm];
            [self.trustAnchorValueTextField setStringValue:identityObject.trustAnchor ? NSLocalizedString(@"Enterprise_provisioned", @"") : NSLocalizedString(@"None", @"")];
            [self.servicesValueTextField setStringValue:[Identity getServicesStringForIdentity:identityObject]];
        }
    }
}

#pragma mark - NSNotification center

- (void)registerForNSNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(addIdentityButtonPressed:)
                               name:MST_ADD_IDENTITY_NOTIFICATION object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(doubleAction:)
                               name:MST_EDIT_IDENTITY_NOTIFICATION object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(deleteIdentityButtonPressed:)
                               name:MST_REMOVE_IDENTITY_NOTIFICATION object:nil];
}

- (void)deregisterForNSNotifications {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:MST_ADD_IDENTITY_NOTIFICATION];
    [notificationCenter removeObserver:MST_EDIT_IDENTITY_NOTIFICATION];
    [notificationCenter removeObserver:MST_REMOVE_IDENTITY_NOTIFICATION];
}

#pragma mark - NSTableViewDataSource & NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.identitiesArray count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"cellIdentifier" owner:self];
    cellView.imageView.image = [NSImage imageNamed:@"user_info_thumbnail"];
    Identity *identityObject = [self.identitiesArray objectAtIndex:row];
    if ([self.identitiesArray count] > 0) {
        cellView.textField.stringValue = identityObject.displayName;
    } else {
        cellView.textField.stringValue = NSLocalizedString(@"No_Identity", @"");
    }
    return cellView;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    NSArray *newDescriptors = [tableView sortDescriptors];
    [self.identitiesArray sortUsingDescriptors:newDescriptors];
    [tableView reloadData];
}

- (IBAction)doubleAction:(id)sender {
    self.editIdentityWindow = [[EditIdentityWindow alloc] initWithWindowNibName: NSStringFromClass([EditIdentityWindow class])];
    self.editIdentityWindow.delegate = self;
    Identity *identityToEdit = [self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow];
    self.editIdentityWindow.identityToEdit = identityToEdit;
    self.editIdentityWindow.trustAnchorObject = identityToEdit.trustAnchor;
    [self.view.window beginSheet:self.editIdentityWindow.window  completionHandler:^(NSModalResponse returnCode) {
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

- (IBAction)singleAction:(id)sender {
    if (self.identitiesTableView.selectedRow != -1) {
        Identity *identityObject = [self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow];
        BOOL isNoIdentityObjectSelected = [identityObject.identityId isEqualToString:@"NOIDENTITY"];
        if (isNoIdentityObjectSelected) {
            [self setEditMenuItemStatus:YES andRemoveMenuItemStatus:NO];
            [self.deleteIdentityButton setEnabled:NO];
            [self reloadDetailsViewWithIdentityData:YES];
        } else {
            [self setEditMenuItemStatus:YES andRemoveMenuItemStatus:YES];
            [self.deleteIdentityButton setEnabled:YES];
            [self reloadDetailsViewWithIdentityData:YES];
        }
    } else {
        [self setEditMenuItemStatus:NO andRemoveMenuItemStatus:NO];
        [self.deleteIdentityButton setEnabled:NO];
        [self reloadDetailsViewWithIdentityData:NO];
    }
}

#pragma mark - Button Actions

- (IBAction)addIdentityButtonPressed:(id)sender {
    self.addIdentityWindow = [[AddIdentityWindow alloc] initWithWindowNibName: NSStringFromClass([AddIdentityWindow class])];
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

- (IBAction)deleteIdentityButtonPressed:(id)sender {
    __weak __typeof__(self) weakSelf = self;
    Identity *identityToDelete = self.identitiesArray[self.identitiesTableView.selectedRow];
    [[self.view window] addAlertWithButtonTitle:NSLocalizedString(@"Delete_Button", @"") secondButtonTitle:NSLocalizedString(@"Cancel_Button", @"") messageText:[NSString stringWithFormat:NSLocalizedString(@"Delete_Identity_Alert_Message", @""),identityToDelete.displayName] informativeText:NSLocalizedString(@"Alert_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                [weakSelf deleteSelectedIdentity:identityToDelete];
                break;
            default:
                break;
        }
    }];
}

- (IBAction)infoButtonPressed:(id)sender {
    [self showInfoAlert];
}

- (IBAction)importButtonPressed:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt:@"Select"];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"xml"]];
    [panel setDirectoryURL:[NSURL fileURLWithPath:[@"~/Documents" stringByExpandingTildeInPath] isDirectory:YES]];
    NSInteger clicked = [panel runModal];
	

    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
			self.identityImporter = [[MSTIdentityImporter alloc] init];
			__weak typeof (self) weakSelf = self;
			[self.identityImporter importIdentitiesFromFile:url withBlock:^(NSArray<Identity *> *items) {
				if (items.count > 0) {
					for (Identity *identityObject in items) {
						[weakSelf addIdentity:identityObject forWindow:self.view.window];
					}
					[weakSelf showSuccessParsingAlert:items.count];
				} else {
					[weakSelf showErrorParsingAlert];
				}
			}];
        }
    }
}
#pragma mark - Keyboard events

- (void)keyUp:(NSEvent *)event {
    const NSString * character = [event charactersIgnoringModifiers];
    const unichar code = [character characterAtIndex:0];
    switch(code) {
        case NSUpArrowFunctionKey: 
            [self.deleteIdentityButton setEnabled:YES];
            [self reloadDetailsViewWithIdentityData:YES];
            break;
        case NSDownArrowFunctionKey:
            [self.deleteIdentityButton setEnabled:YES];
            [self reloadDetailsViewWithIdentityData:YES];
            break;
        default:
            [self.identitiesTableView deselectRow:self.identitiesTableView.selectedRow];
            break;
    }
}

#pragma mark - AddIdentityWindowDelegate

- (void)addIdentityWindowCanceled:(NSWindow *)window {
    [[self.view window] endSheet:window];
}

- (void)addIdentityWindow:(NSWindow *)window wantsToAddIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword {
    [self addIdentity:identity forWindow:window];
}

#pragma mark - EditIdentityWindowDelegate

- (void)editIdentityWindow:(NSWindow *)window wantsToEditIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword {
    __weak __typeof__(self) weakSelf = self;
    [self.deleteIdentityButton setEnabled:NO];
    [self setEditMenuItemStatus:NO andRemoveMenuItemStatus:NO];
    [self reloadDetailsViewWithIdentityData:NO];
    [[MSTIdentityDataLayer sharedInstance] editIdentity:identity withBlock:^(NSError *error) {
        if (!error) {
            [weakSelf getSavedIdentities];
            [[weakSelf.view window] endSheet: window];
        } else {
            [window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:[NSString stringWithFormat: NSLocalizedString(@"Alert_Edit_Identity_Error_Message", @""),identity.displayName] informativeText:NSLocalizedString(@"Alert_Error_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
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

#pragma mark - Delete Identity

- (void)editIdentityWindowCanceled:(NSWindow *)window {
    [[self.view window] endSheet:window];
}

- (void)deleteSelectedIdentity:(Identity *)identity {
    __weak __typeof__(self) weakSelf = self;
    [[MSTIdentityDataLayer sharedInstance] removeIdentity:identity withBlock:^(NSError *error) {
        if (!error) {
            [weakSelf getSavedIdentities];
            [weakSelf.deleteIdentityButton setEnabled:NO];
            [weakSelf reloadDetailsViewWithIdentityData:NO];
            [weakSelf setEditMenuItemStatus:NO andRemoveMenuItemStatus:NO];
        } else {
            [[weakSelf.view window] addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:[NSString stringWithFormat: NSLocalizedString(@"Alert_Delete_Identity_Error_Message", @""),identity.displayName] informativeText:NSLocalizedString(@"Alert_Error_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
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

#pragma mark - NSTextFieldDelegate

- (void)controlTextDidChange:(NSNotification *)notification {
    if ([self.searchField.stringValue isEqualToString:@""]) {
        [self getSavedIdentities];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"displayName CONTAINS[cd] %@", self.searchField.stringValue];
        self.identitiesArray  = [[self.identitiesArray filteredArrayUsingPredicate:predicate] mutableCopy];
        [self.identitiesTableView reloadData];
    }
}

#pragma mark - Info Alert

- (void)showInfoAlert {
    [[self.view window] addAlertWithButtonTitle:NSLocalizedString(@"Read_More_Button", @"") secondButtonTitle:NSLocalizedString(@"Cancel_Button", @"") messageText: NSLocalizedString(@"Alert_Import_Message", @"")informativeText:NSLocalizedString(@"Alert_Import_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Wiki_URL", @"")]];
                break;
            default:
                break;
        }
    }];
}

#pragma mark - Menu Items Status

- (void)setEditMenuItemStatus:(BOOL)status {
    
}

- (void)setRemoveMenuItemStatus:(BOOL)status {
    
}

- (void)setEditMenuItemStatus:(BOOL)editStatus andRemoveMenuItemStatus:(BOOL)removeStatus {
    [self.editIdentityMenuItem setEnabled:editStatus];
    [self.removeIdentityMenuItem setEnabled:removeStatus];
}

#pragma mark - Add Identity

- (void)addIdentity:(Identity *)identity forWindow:(NSWindow *)window {
    __weak __typeof__(self) weakSelf = self;
    [[MSTIdentityDataLayer sharedInstance] addNewIdentity:identity withBlock:^(NSError *error) {
        if (!error) {
            [weakSelf getSavedIdentities];
            [weakSelf.deleteIdentityButton setEnabled:NO];
            [weakSelf reloadDetailsViewWithIdentityData:NO];
            [weakSelf setEditMenuItemStatus:NO andRemoveMenuItemStatus:NO];
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

#pragma mark - Edit Identity

- (void)editIdentity:(Identity *)identity forWindow:(NSWindow *)window {
    __weak __typeof__(self) weakSelf = self;
    [[MSTIdentityDataLayer sharedInstance] editIdentity:identity withBlock:^(NSError *error) {
        if (!error) {
            [weakSelf getSavedIdentities];
            [[weakSelf.view window] endSheet: window];
        } else {
            [window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:[NSString stringWithFormat: NSLocalizedString(@"Alert_Edit_Identity_Error_Message", @""),identity.displayName] informativeText:NSLocalizedString(@"Alert_Error_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
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


#pragma mark - Parsing Alerts
- (void)showErrorParsingAlert {
    [self.view.window addAlertWithButtonTitle:NSLocalizedString(@"Read_More_Button", @"") secondButtonTitle:NSLocalizedString(@"Cancel_Button", @"") messageText:NSLocalizedString(@"Alert_Error_Parsing_XML_Message", @"") informativeText:NSLocalizedString(@"Alert_Error_Parsing_XML_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Wiki_URL", @"")]];
                break;
            case NSAlertSecondButtonReturn:
                break;
            default:
                break;
        }
    }];
}

- (void)showSuccessParsingAlert:(int)importedItemsCount {
    NSString *informativeText = (importedItemsCount > 1) ? [NSString stringWithFormat:NSLocalizedString(@"Alert_Success_Parsing_XML_Info", @""), importedItemsCount] : [NSString stringWithFormat:NSLocalizedString(@"Alert_Success_Parsing_XML_Info_One", @""), importedItemsCount];
    [self.view.window addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:NSLocalizedString(@"Alert_Success_Parsing_XML_Message", @"") informativeText:informativeText alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                break;
            default:
                break;
        }
    }];
}
@end
