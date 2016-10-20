//
//  AboutWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 11/1/16.
//  Copyright © 2016 Devsy. All rights reserved.
//

#import "AboutWindow.h"

@interface AboutWindow ()
@property (weak) IBOutlet NSSegmentedControl *aboutWindowSegmentedControl;
@property (weak) IBOutlet NSTextField *productNameTextField;
@property (weak) IBOutlet NSTextField *productVersionTextField;
@property (nonatomic, strong) NSString *productName;
@property (weak) IBOutlet NSButton *urlButton;
@end

@implementation AboutWindow

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
    if (self = [super initWithWindowNibName:@"AboutWindow" owner:self]) {
        // (nothing yet...)
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupView];
}

#pragma mark - Setup View

- (void)setupView {
    self.productName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    [self.productNameTextField setStringValue:self.productName];
    [self.productVersionTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Version", @""), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
    [self setupURLButton];
}

- (void)setupURLButton {
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.urlButton.bounds
                                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                                  owner:self userInfo:nil];
    [self.urlButton addTrackingArea:trackingArea];
    [self.urlButton.layer setCornerRadius:10.0];
    [self.urlButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Product_Website", @""), self.productName]];
}

#pragma mark - NSSegmentedControl

- (IBAction)aboutWindowSegmentedControlValueChanged:(id)sender {
}

#pragma mark - Button Actions

- (IBAction)urlButtonPressed:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Website_URL", @"")]];
}

#pragma mark - Mouse events

- (void)mouseEntered:(NSEvent *)event {
    [self.urlButton.layer setBackgroundColor:[NSColor lightGrayColor].CGColor];
    [self setURLButtonTitleColor:[NSColor whiteColor]];
}

- (void)mouseExited:(NSEvent *)event {
    [self.urlButton.layer setBackgroundColor:self.window.backgroundColor.CGColor];
    [self setURLButtonTitleColor:[NSColor blackColor]];
}

- (void)setURLButtonTitleColor:(NSColor *)titleColor {
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.urlButton attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:titleColor range:titleRange];
    [self.urlButton setAttributedTitle:colorTitle];
}

@end
