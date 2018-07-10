//
//  ConnectIdentityWindow.h
//  Moonshot
//
//  Created by Elena Jakjoska on 11/25/16.
//

#import <Cocoa/Cocoa.h>
#import "Identity.h"

@protocol ConnectIdentityWindowDelegate <NSObject>
- (void)connectIdentityWindow:(NSWindow *)window wantsToConnectIdentity:(Identity *)identity;
- (void)connectIdentityWindowCanceled:(NSWindow *)window;
@end

@interface ConnectIdentityWindow : NSWindowController
@property (nonatomic, weak) id <ConnectIdentityWindowDelegate>delegate;
@property (nonatomic, strong) Identity *identityObject;
@end
