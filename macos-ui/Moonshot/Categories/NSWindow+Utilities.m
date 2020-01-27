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

- (void)showErrorParsingAlert {
    [self addAlertWithButtonTitle:NSLocalizedString(@"Read_More_Button", @"") secondButtonTitle:NSLocalizedString(@"Cancel_Button", @"") messageText:NSLocalizedString(@"Alert_Error_Parsing_XML_Message", @"") informativeText:NSLocalizedString(@"Alert_Error_Parsing_XML_Info", @"") alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Wiki_URL", @"")]];
                break;
            case NSAlertSecondButtonReturn:
                break;
            default:
                break;
        }
    }];
}

- (void)showSuccessParsingAlert:(int)importedItemsCount skippedIds:(NSArray*)skippedIds {
    NSMutableString *informativeText = (importedItemsCount != 1) ? [NSMutableString stringWithFormat:NSLocalizedString(@"Alert_Success_Parsing_XML_Info", @""), importedItemsCount] : [NSMutableString stringWithFormat:NSLocalizedString(@"Alert_Success_Parsing_XML_Info_One", @""), importedItemsCount];
    
    if ([skippedIds count] > 0) {
        [informativeText appendFormat:@"\n\nThe following identities were skipped since they already exist:"];
        for (NSString* skipped in skippedIds)
            [informativeText appendFormat:@"\n * %@", skipped];
        [informativeText appendFormat:@"\n\nIf you want to add them, please remove the existing ones first."];
    }
    
    [self addAlertWithButtonTitle:NSLocalizedString(@"OK_Button", @"") secondButtonTitle:@"" messageText:NSLocalizedString(@"Alert_Success_Parsing_XML_Message", @"") informativeText:informativeText alertStyle:NSWarningAlertStyle completionHandler:^(NSModalResponse returnCode) {
        switch (returnCode) {
            case NSAlertFirstButtonReturn:
                break;
            default:
                break;
        }
    }];
}

@end
