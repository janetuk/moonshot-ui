//
//  EditIdentityWindow.h
//  Moonshot
//
//  Created by Elena Jakjoska on 10/25/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Identity.h"

@protocol EditIdentityWindowDelegate <NSObject>
- (void)editIdentityWindow:(NSWindow *)window wantsToEditIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword;
- (void)editIdentityWindowCanceled:(NSWindow *)window;
@end

@interface EditIdentityWindow : NSWindowController
@property (nonatomic, weak) id <EditIdentityWindowDelegate>delegate;
@property (weak) IBOutlet NSTextField *editUsernameValueTextField;
@property (weak) IBOutlet NSTextField *editRealmValueTextField;
@property (weak) IBOutlet NSSecureTextField *editPasswordValueTextField;
@property (weak) IBOutlet NSTextField *editUsernameTextField;
@property (weak) IBOutlet NSTextField *editRealmTextField;
@property (weak) IBOutlet NSTextField *editPasswordTextField;
@property (weak) IBOutlet NSTableView *editIdentityServicesTableView;
@property (weak) IBOutlet NSButton *editRememberPasswordButton;
@property (weak) IBOutlet NSButton *clearTrustAnchorButton;
@property (weak) IBOutlet NSButton *editIdentityDeleteServiceButton;
@property (weak) IBOutlet NSButton *editIdentityCancelButton;
@property (weak) IBOutlet NSButton *editIdentitySaveButton;
@property (weak) IBOutlet NSButton *editIdentityHelpButton;
@property (nonatomic, assign) NSInteger index;
@property (weak) IBOutlet NSTextField *editIdentityDateAddedTextField;
@property (weak) IBOutlet NSView *certificateView;
@property (strong) IBOutlet NSView *shaFingerprintView;
@property (weak) IBOutlet NSView *servicesView;
@property (weak) IBOutlet NSTextField *servicesTitleTextField;
@property (weak) IBOutlet NSTextField *trustAnchorTextField;
@property (weak) IBOutlet NSTextField *dateAddedTitleTextField;
@end
