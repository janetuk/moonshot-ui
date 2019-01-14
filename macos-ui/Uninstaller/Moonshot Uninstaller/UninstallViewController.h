//
//  UninstallViewController.h
//  Uninstall Moonshot
//
//  Copyright © 2018 JISC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface UninstallViewController : NSViewController

@property (unsafe_unretained) IBOutlet NSTextView *txtDescription;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSButton *btnUninstall;
@end

NS_ASSUME_NONNULL_END
