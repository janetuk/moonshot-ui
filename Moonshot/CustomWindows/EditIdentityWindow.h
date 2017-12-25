//
//  EditIdentityWindow.h
//  Moonshot
//
//  Created by Elena Jakjoska on 10/25/16.
//

#import <Cocoa/Cocoa.h>
#import "Identity.h"
#import "TrustAnchor.h"

@protocol EditIdentityWindowDelegate <NSObject>
- (void)editIdentityWindow:(NSWindow *)window wantsToEditIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword;
- (void)editIdentityWindowCanceled:(NSWindow *)window;
@end

@interface EditIdentityWindow : NSWindowController
@property (nonatomic, weak) id <EditIdentityWindowDelegate>delegate;
@property (nonatomic, strong) Identity *identityToEdit;
@property (nonatomic, strong) TrustAnchor *trustAnchorObject;
@end
