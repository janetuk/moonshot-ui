//
//  NSWindow+Utilities.m
//  Moonshot
//
//  Created by Elena Jakjoska on 11/30/16.
//

#import "NSWindow+Utilities.h"

@implementation NSWindow (Utilities)

- (void)addAlertWithButtonTitle:(nonnull NSString *)buttonTitle secondButtonTitle:(nonnull NSString *)secondButtonTitle messageText:(nonnull NSString *)message informativeText:(nonnull NSString *)informativeText alertStyle:(NSAlertStyle)alertStyle completionHandler:(void (^ __nullable)(NSModalResponse returnCode))handler {
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:buttonTitle];
    [alert addButtonWithTitle:secondButtonTitle];
    [alert setMessageText: message];
    [alert setInformativeText:informativeText];
    [alert setAlertStyle:alertStyle];
    [alert beginSheetModalForWindow:self completionHandler:handler];
}

@end
