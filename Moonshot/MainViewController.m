//
//  ViewController.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/13/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import "MainViewController.h"
#import "AddIdentityWindow.h"
#import "EditIdentityWindow.h"
#import "Identity.h"

@interface MainViewController()<NSTableViewDataSource, NSTableViewDelegate, AddIdentityWindowDelegate, EditIdentityWindowDelegate>

@property (weak) IBOutlet NSView *contentView;
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
@property (weak) IBOutlet NSTableView *identitiesTableView;
@property (weak) IBOutlet NSButton *addIdentityButton;
@property (weak) IBOutlet NSButton *deleteIdentityButton;
@property (weak) IBOutlet NSButton *importButton;
@property (weak) IBOutlet NSImageView *userImageView;
@property (nonatomic, strong) NSWindow *sheetWindow;
@property (nonatomic, retain) NSMutableArray *identitiesArray;
@property (nonatomic, strong) AddIdentityWindow *addIdentityWindow;
@property (nonatomic, strong) EditIdentityWindow *editIdentityWindow;

@end

@implementation MainViewController

static BOOL runDeleteIdentityAlertAgain;

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.identitiesArray = [[NSMutableArray alloc] init];
    [self retrieveSavedIdentitiesFromNSUserDefaults];
    runDeleteIdentityAlertAgain = YES;
    [self setupView];

//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Identities_Array"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - Setup Views

- (void)setupView {
    [self setupContentView];
    [self setupDetailsView];
    [self setupImportButton];
    [self setupTableViewHeader];
    [self setupUserImageView];
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

    [self.detailsView.layer setBorderWidth:1.0];
    [self.detailsView.layer setBorderColor:[NSColor lightGrayColor].CGColor];
    [self.detailsView.layer setBackgroundColor:[NSColor whiteColor].CGColor];
}

#pragma mark - Setup Import Button

- (void)setupImportButton {
    [self.importButton setTitle:NSLocalizedString(@"Import_Button", @"")];
}

#pragma mark - Setup User ImageView

- (void)setupUserImageView {
    self.userImageView.image = [NSImage imageNamed:@"Profile_icon"];
}

#pragma mark - Setup TableView Header

- (void)setupTableViewHeader {
    [self.identitiesTableView.tableColumns.firstObject.headerCell setStringValue:NSLocalizedString(@"Name", @"")];
}

#pragma mark - Reload Data

- (void)reloadDetailsViewWithIdentityData {
    Identity *identityObject = [self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow];
    if ([self.identitiesArray count] > 0) {
        [self.displayNameTextField setStringValue: identityObject.displayName];
        [self.usernameValueTextField setStringValue: identityObject.username];
        [self.realmValueTextField setStringValue: identityObject.realm];
        [self.servicesValueTextField setStringValue:@"" ];
        [self.trustAnchorValueTextField setStringValue:@""];
    }
    else {
        [self.displayNameTextField setStringValue: @"No identity"];
        [self.usernameValueTextField setStringValue: @"/"];
        [self.realmValueTextField setStringValue: @"/"];
        [self.servicesValueTextField setStringValue: @"/"];
    }
}

#pragma mark - NSTableViewDataSource & NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.identitiesArray count] ?: 1;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"cellIdentifier" owner:self];
    cellView.imageView.image = [NSImage imageNamed:@"Profile_icon"];
    if ([self.identitiesArray count] > 0) {
        cellView.textField.stringValue = [[self.identitiesArray objectAtIndex:row] valueForKey:@"displayName"];
    } else {
        cellView.textField.stringValue = @"No identity";
    }
    return cellView;
}

- (void)cancel:(id)sender
{
    [[self.view window] endSheet:self.sheetWindow];
}

- (IBAction)doubleAction:(id)sender {
    self.editIdentityWindow = [[EditIdentityWindow alloc] initWithWindowNibName:@"EditIdentityWindow"];
    self.editIdentityWindow.delegate = self;
    self.editIdentityWindow.index = self.identitiesTableView.selectedRow;
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
    [self.deleteIdentityButton setEnabled:YES];
    [self reloadDetailsViewWithIdentityData];
}

#pragma mark - Button Actions

- (IBAction)addIdentityButtonPressed:(id)sender {
    self.addIdentityWindow = [[AddIdentityWindow alloc] initWithWindowNibName:@"AddIdentityWindow"];
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
    if (runDeleteIdentityAlertAgain == NO) {
        [self deleteFromNSUserDefaults];
        [self.deleteIdentityButton setEnabled:NO];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:NSLocalizedString(@"Delete_Button", @"")];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel_Button", @"")];
        [alert setMessageText: [NSString stringWithFormat:NSLocalizedString(@"Delete_Identity_Alert_Message", @""),[[self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow]valueForKey:@"displayName"]]];
        [alert setInformativeText:NSLocalizedString(@"Alert_Info", @"")];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setShowsSuppressionButton:YES];
        [[alert suppressionButton] setTitle:NSLocalizedString(@"Alert_Suppression_Message", @"")];
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case NSAlertFirstButtonReturn:
                    runDeleteIdentityAlertAgain = (BOOL)![[alert suppressionButton] state];
                    [self deleteFromNSUserDefaults];
                    [self.deleteIdentityButton setEnabled:NO];
                    break;
                default:
                    break;
            }
        }];
    }
}

- (IBAction)importIdentityButtonPressed:(id)sender {
}

#pragma mark - Keyboard events

- (void)keyUp:(NSEvent *)event {
    
    const NSString * character = [event charactersIgnoringModifiers];
    const unichar code = [character characterAtIndex:0];
    
    switch(code) {
        case NSUpArrowFunctionKey: //up arrow
            [self.deleteIdentityButton setEnabled:YES];
            [self reloadDetailsViewWithIdentityData];
            break;
        case NSDownArrowFunctionKey: // down arrow
            [self.deleteIdentityButton setEnabled:YES];
            [self reloadDetailsViewWithIdentityData];
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
    [self.identitiesArray addObject: identity];
    [self saveIdentityInNSUserDefaults:self.identitiesArray];
    [[self.view window] endSheet:window];
}

#pragma mark - EditIdentityWindowDelegate

- (void)editIdentityWindow:(NSWindow *)window wantsToEditIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword {
    [self.identitiesArray replaceObjectAtIndex:self.identitiesTableView.selectedRow withObject:identity];
    [self saveIdentityInNSUserDefaults:self.identitiesArray];
    [[self.view window] endSheet: window];
}

- (void)editIdentityWindowCanceled:(NSWindow *)window {
    [[self.view window] endSheet:window];
}

#pragma mark - Save in NSUserDefaults

- (void)saveIdentityInNSUserDefaults:(NSMutableArray *)identitiesArray {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:identitiesArray];
    [userDefaults setObject:encodedObject forKey:@"Identities_Array"];
    [userDefaults synchronize];
    [self retrieveSavedIdentitiesFromNSUserDefaults];
}

- (void)retrieveSavedIdentitiesFromNSUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"Identities_Array"] != nil) {
        NSData *encodedObject = [userDefaults objectForKey:@"Identities_Array"];
        [self.identitiesArray removeAllObjects];
        self.identitiesArray = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        [self.identitiesTableView reloadData];
    }
}

- (void)deleteFromNSUserDefaults {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"Identities_Array"] != nil) {
        NSData *encodedObject = [userDefaults objectForKey:@"Identities_Array"];
        [self.identitiesArray removeAllObjects];
        self.identitiesArray = [NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        if ([self.identitiesArray count] > 0) {
            [self.identitiesArray removeObjectAtIndex:self.identitiesTableView.selectedRow];
        }
        [self saveIdentityInNSUserDefaults:self.identitiesArray];
        [self.identitiesTableView reloadData];
    }
}
@end
