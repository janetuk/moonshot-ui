//
//  TrustAnchorWindow.h
//  Moonshot
//
//  Created by Elena Jakjoska on 4/17/18.
//

#import <Cocoa/Cocoa.h>

@protocol TrustAnchorWindowDelegate <NSObject>
- (void)trustAnchorWindowCanceled:(NSWindow *)window;
@end

@interface TrustAnchorWindow : NSWindowController
+ (instancetype)defaultController;
@property (nonatomic, weak) id <TrustAnchorWindowDelegate>delegate;
+ (void)showWindow;
@end
