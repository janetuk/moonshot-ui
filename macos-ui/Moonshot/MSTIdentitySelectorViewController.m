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
#import "MSTIdentityImporter.h"

@interface MSTIdentitySelectorViewController ()<AddIdentityWindowDelegate, ConnectIdentityWindowDelegate, NSWindowDelegate>

//Content View
@property (weak) IBOutlet NSTableView *identitySelectorTableView;
@property (weak) IBOutlet NSTextField *identitySelectorTitleTextField;
@property (weak) IBOutlet NSTextField *identitySelectorServiceValueTextField;

//Button Actions
@property (weak) IBOutlet NSButton *identitySelectorRememberChoiceButton;
@property (weak) IBOutlet NSButton *identitySelectorHelpButton;
@property (weak) IBOutlet NSButton *identitySelectorCreateIdentityButton;
@property (weak) IBOutlet NSButton *identitySelectorConnectButton;
@property (weak) IBOutlet NSButton *identitySelectorImportButton;


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
    [self.identitySelectorServiceValueTextField setStringValue:self.getIdentityAction.service];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self.identitySelectorRememberChoiceButton setTitle:NSLocalizedString(@"Remember_Identity_Choice_Button", @"")];
    [self.identitySelectorCreateIdentityButton setTitle:NSLocalizedString(@"Create_Identity_Button", @"")];
    [self.identitySelectorConnectButton setTitle:NSLocalizedString(@"Connect_Identity_Button", @"")];
    [self.identitySelectorImportButton setTitle:NSLocalizedString(@"Import_Button", @"")];
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
//    if (self.identitySelectorTableView.selectedRow != -1) {
//        [self reloadDetailsViewWithIdentityData:YES];
//    } else {
//        [self reloadDetailsViewWithIdentityData:NO];
//    }
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

- (IBAction)identitySelectorImportButtonPressed:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setPrompt:@"Select"];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"xml"]];
    [panel setDirectoryURL:[NSURL fileURLWithPath:[@"~/Documents" stringByExpandingTildeInPath] isDirectory:YES]];
    NSInteger clicked = [panel runModal];
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            __block int actually_added = 0;
            NSMutableArray* skipped = [[NSMutableArray alloc] init];
            MSTIdentityImporter* identityImporter = [[MSTIdentityImporter alloc] init];
            __weak typeof (self) weakSelf = self;
            [identityImporter importIdentitiesFromFile:url withBlock:^(NSArray<Identity *> *items) {
                if (items.count > 0) {
                    for (Identity *identityObject in items) {
                        if ([weakSelf addIdentityWindow:self.view.window wantsToAddIdentity:identityObject rememberPassword:YES])
                            actually_added++;
                        else {
                            [skipped addObject:identityObject.displayName];
                            // Skipped identities
                        }
                    }
                    [weakSelf.view.window showSuccessParsingAlert:(int)actually_added skippedIds:skipped];
                } else {
                    [weakSelf.view.window showErrorParsingAlert];
                }
            }];
        }
    }
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
        if (![identityObject.displayName isEqualToString: NSLocalizedString(@"No_Identity", @"")]) {
            if (identityObject.password.length > 0 && identityObject.has2fa == NO) {
                if (self.getIdentityAction.service) {
                    [self appendUsedService:self.getIdentityAction.service toIdentity:identityObject];
                    [self applySelectedIdentity:identityObject];
                }
            } else {
                self.connectIdentityWindow = [[ConnectIdentityWindow alloc] initWithWindowNibName:NSStringFromClass([ConnectIdentityWindow class])];
                self.connectIdentityWindow.delegate = self;
                [self appendUsedService:self.getIdentityAction.service toIdentity:identityObject];
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
        } else {
            [self appendUsedService:self.getIdentityAction.service toIdentity:identityObject];
            [self applySelectedIdentity:identityObject];
            [NSApp terminate:[NSApplication sharedApplication]];
        }
    }
}

- (void)appendUsedService:(NSString *)newService toIdentity:(Identity *)identity {
	BOOL isServiceAlreadySaved = NO;
	for (NSString *existingService in identity.servicesArray) {
		if ([existingService isEqualToString:newService]) {
			isServiceAlreadySaved = YES;
			break;
		}
	}
	if (!isServiceAlreadySaved) {
		NSMutableArray *mutableServicesArray = [identity.servicesArray mutableCopy];

		if (!mutableServicesArray) {
			mutableServicesArray = [[NSMutableArray alloc] init];
		}
		[mutableServicesArray addObject:newService];
		identity.servicesArray = mutableServicesArray;
	}
}

#pragma mark - AddIdentity Delegate

- (void)addIdentityWindowCanceled:(NSWindow *)window {
    [[self.view window] endSheet:window];
}

- (BOOL)addIdentityWindow:(NSWindow *)window wantsToAddIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword {
    __weak __typeof__(self) weakSelf = self;
    return [[MSTIdentityDataLayer sharedInstance] addNewIdentity:identity withBlock:^(NSError *error) {
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

- (void)connectIdentityWindow:(NSWindow *)window wantsToConnectIdentity:(Identity *)identity {
    [self applySelectedIdentity:identity];
    [[self.view window] endSheet:window];
}

- (void)connectIdentityWindowCanceled:(NSWindow *)window {
    [[self.view window] endSheet:window];
}

#pragma mark - 

- (void)applySelectedIdentity:(Identity *)identity {
    [[MSTIdentityDataLayer sharedInstance] editIdentity:identity withBlock:^(NSError *error) {
        [self.getIdentityAction selectedIdentity:identity];
    }];
}

- (BOOL)windowShouldClose:(NSWindow *)sender {
    __weak __typeof__(self) weakSelf = self;
    [[self.view window] addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:NSLocalizedString(@"Cancel_Button", @"") messageText:NSLocalizedString(@"Alert_Exit_Message", @"") informativeText:NSLocalizedString(@"Alert_Exit_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                [NSApp terminate:weakSelf.view];
                break;
            default:
                break;
        }
    }];
    return NO;
}

@end
