//
//  TrustAnchorWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 4/17/18.
//

#import "TrustAnchorWindow.h"
#import "MSTIdentityDataLayer.h"

@interface TrustAnchorWindow ()
@property (weak) IBOutlet NSTextField *trustAnchorShaFingerprint;
@property (weak) IBOutlet NSButton *trustAnchorCancelButton;
@property (weak) IBOutlet NSButton *trustAnchorConfirmButton;

@end

@implementation TrustAnchorWindow

#pragma mark - Init

+ (instancetype)defaultController
{
    static id staticInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticInstance = [[self alloc] init];
    });
    return staticInstance;
}

- (instancetype)init
{
    if (self = [super initWithWindowNibName: NSStringFromClass([TrustAnchorWindow class]) owner:self]) {
        // (nothing yet...)
    }
    return self;
}

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupWindow];
}

#pragma mark - Setup Window

- (void)setupWindow {
    [self setupButtons];
}

#pragma mark - Setup Buttons

- (void)setupButtons {
    [self setupCancelButton];
    [self setupConfirmButton];
}

- (void)setupCancelButton {
    self.trustAnchorCancelButton.title = NSLocalizedString(@"Cancel", @"");
}

- (void)setupConfirmButton {
    self.trustAnchorConfirmButton.title = NSLocalizedString(@"Confirm", @"");
}

#pragma mark - Button Actions

- (IBAction)trustAnchorCancelButtonPressed:(id)sender {
    if ([self.delegate respondsToSelector:@selector(trustAnchorWindowCanceled:)]) {
        [self.delegate trustAnchorWindowCanceled:self.window];
    }
}

- (IBAction)trustAnchorConfirmButtonPressed:(id)sender {
}

+ (void)showWindow {
    [[TrustAnchorWindow defaultController] showWindow:self];
}

@end
