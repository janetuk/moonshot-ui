//
//  ViewController.m
//  Moonshot
//
//  Created by Elena Jakjoska on 10/13/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import "ViewController.h"
#import "AddIdentityWindow.h"
#import "EditIdentityWindow.h"
#import "Identity.h"

@interface ViewController()<NSTableViewDataSource, NSTableViewDelegate, AddIdentityWindowDelegate, EditIdentityWindowDelegate>

@property (weak) IBOutlet NSView *detailsView;
@property (weak) IBOutlet NSTextField *displayNameTextField;
@property (weak) IBOutlet NSTextField *usernameValueTextField;
@property (weak) IBOutlet NSTextField *realmValueTextField;
@property (weak) IBOutlet NSTextField *servicesValueTextField;
@property (weak) IBOutlet NSTableView *identitiesTableView;
@property (strong) IBOutlet NSArrayController *identitiesArrayController;
@property (weak) IBOutlet NSButton *deleteIdentityButton;
@property (nonatomic) BOOL runAgain;
@property (nonatomic, strong) NSWindow *sheetWindow;
@property (nonatomic, retain) NSMutableArray *identitiesArray;
@property (nonatomic, strong) AddIdentityWindow *addIdentityWindow;
@property (nonatomic, strong) EditIdentityWindow *editIdentityWindow;

@end

@implementation ViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.identitiesArray = [[NSMutableArray alloc] init];
    [self retrieveSavedIdentitiesFromNSUserDefaults];
    self.runAgain = YES;
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Identities_Array"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark - Reload Data

- (void)reloadDetailsViewWithIdentityData {
    
    Identity *identityObject = [self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow];
    if ([self.identitiesArray count] > 0) {
        self.displayNameTextField.stringValue = identityObject.displayName;
        self.usernameValueTextField.stringValue = identityObject.username;
        self.realmValueTextField.stringValue = identityObject.realm;
        self.servicesValueTextField.stringValue = @"";
    }
    else {
        self.displayNameTextField.stringValue = @"No identity";
        self.usernameValueTextField.stringValue = @"/";
        self.realmValueTextField.stringValue = @"/";
        self.servicesValueTextField.stringValue = @"/";
    }
}

#pragma mark - NSTableViewDataSource & NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.identitiesArray count] ?: 1;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"cellIdentifier" owner:self];
    if ([self.identitiesArray count] > 0) {
        cellView.textField.stringValue = [[self.identitiesArray objectAtIndex:row] valueForKey:@"displayName"];
    } else {
        cellView.textField.stringValue = @"No identity";
    }
    return cellView;
}

- (void)cancel:(id) sender
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
    if (self.runAgain == NO) {
        [self deleteFromNSUserDefaults];
        [self.deleteIdentityButton setEnabled:NO];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText: [NSString stringWithFormat:@"Are you sure you want to delete %@ from identity selector ?",[[self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow]valueForKey:@"displayName"]]];
        [alert setInformativeText:@"This item will be deleted immediately. You can’t undo this action."];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert setShowsSuppressionButton:YES];
        [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
            switch (returnCode) {
                case 1000:
                    self.runAgain = (BOOL)![[alert suppressionButton] state];
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

#pragma mark - AddIdentityWindowDelegate

- (void)didPressCancelAddButton {
    [[self.view window] endSheet:[self.addIdentityWindow window]];
}

- (void)didPressAddIdentityButton {
    Identity *newIdentity = [[Identity alloc] init];
    newIdentity.displayName = self.addIdentityWindow.displayNameTextField.stringValue;
    newIdentity.username = self.addIdentityWindow.usernameTextField.stringValue;
    newIdentity.realm = self.addIdentityWindow.reamTextField.stringValue;
    newIdentity.password = self.addIdentityWindow.passwordTextField.stringValue;
    newIdentity.passwordRemembered = self.addIdentityWindow.rememberPasswordButton.state;
    newIdentity.dateAdded = [NSDate date];
    [self.identitiesArray addObject: newIdentity];
    [self saveIdentityInNSUserDefaults:self.identitiesArray];
    [[self.view window] endSheet:[self.addIdentityWindow window]];
}

- (void)didPressRememberPasswordButton {
}

#pragma mark - EditIdentityWindowDelegate

- (void)didPressSaveEditButton {
    Identity *editedIdentity = [[Identity alloc] init];
    editedIdentity.displayName = [[self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow] valueForKey:@"displayName"];
    editedIdentity.username = self.editIdentityWindow.editUsernameTextField.stringValue;
    editedIdentity.realm = self.editIdentityWindow.editRealmTextField.stringValue;
    editedIdentity.password = self.editIdentityWindow.editPasswordTextField.stringValue;
    editedIdentity.passwordRemembered = self.editIdentityWindow.editRememberPasswordButton.state;
    editedIdentity.dateAdded = [[self.identitiesArray objectAtIndex:self.identitiesTableView.selectedRow] valueForKey:@"dateAdded"];
    [self.identitiesArray replaceObjectAtIndex:self.identitiesTableView.selectedRow withObject:editedIdentity];
    [self saveIdentityInNSUserDefaults:self.identitiesArray];
    [[self.view window] endSheet:[self.editIdentityWindow window]];
}

- (void)didPressCancelEditButton {
    [[self.view window] endSheet:[self.editIdentityWindow window]];
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
