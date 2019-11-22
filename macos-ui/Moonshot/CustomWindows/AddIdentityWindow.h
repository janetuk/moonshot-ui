//
//  AddIdentityWindow.h
//  Moonshot
//
//  Created by Elena Jakjoska on 10/21/16.
//

#import <Cocoa/Cocoa.h>
#import "Identity.h"

@protocol AddIdentityWindowDelegate <NSObject>
- (void)addIdentityWindow:(NSWindow *)window wantsToAddIdentity:(Identity *)identity rememberPassword:(BOOL)rememberPassword;
- (void)addIdentityWindowCanceled:(NSWindow *)window;
@end

@interface AddIdentityWindow : NSWindowController
@property (nonatomic, weak) id <AddIdentityWindowDelegate>delegate;
@end
