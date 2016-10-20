//
//  AddIdentityWindow.h
//  Moonshot
//
//  Created by Elena Jakjoska on 10/21/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Identity.h"

@protocol AddIdentityWindowDelegate <NSObject>
- (void)addIdentityWindow:(NSWindow *)window wantsToAddIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword;
- (void)addIdentityWindowCanceled:(NSWindow *)window;
@end

@interface AddIdentityWindow : NSWindowController

@property (nonatomic, weak) id <AddIdentityWindowDelegate>delegate;
@property (weak) IBOutlet NSTextField *displayNameValueTextField;
@property (weak) IBOutlet NSTextField *realmValueTextField;
@property (weak) IBOutlet NSTextField *usernameValueTextField;
@property (weak) IBOutlet NSSecureTextField *passwordValueTextField;
@property (weak) IBOutlet NSButton *rememberPasswordButton;

@end
