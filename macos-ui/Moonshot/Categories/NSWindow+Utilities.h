//
//  NSWindow+Utilities.h
//  Moonshot
//
//  Created by Elena Jakjoska on 11/30/16.
//

#import <Cocoa/Cocoa.h>

@interface NSWindow (Utilities)

- (void)addAlertWithButtonTitle:(nonnull NSString *)buttonTitle secondButtonTitle:(nonnull NSString *)secondButtonTitle messageText:(nonnull NSString *)message informativeText:(nonnull NSString *)informativeText alertStyle:(NSAlertStyle)alertStyle completionHandler:(void (^ __nullable)(NSModalResponse returnCode))handler;

@end
