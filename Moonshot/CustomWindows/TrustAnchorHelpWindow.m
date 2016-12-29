//
//  TrustAnchorHelpWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 11/1/16.
//

#import "TrustAnchorHelpWindow.h"

@interface TrustAnchorHelpWindow ()
@property (weak) IBOutlet NSTextField *trustAnchorTitleTextField;
@property (weak) IBOutlet NSTextField *trustAnchorInfoTextField;
@end

@implementation TrustAnchorHelpWindow

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupWindow];
}

#pragma mark - Window Setup

- (void)setupWindow {
    [self.trustAnchorTitleTextField setStringValue:NSLocalizedString(@"Trust_Anchor_Title", @"")];
    [self.trustAnchorInfoTextField setStringValue:NSLocalizedString(@"Trust_Anchor_Info", @"")];
}

@end
