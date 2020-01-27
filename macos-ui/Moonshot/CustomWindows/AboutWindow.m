//
//  AboutWindow.m
//  Moonshot
//
//  Created by Elena Jakjoska on 11/1/16.
//

#import "AboutWindow.h"

@interface AboutWindow () <NSTextViewDelegate>
@property (weak) IBOutlet NSSegmentedControl *aboutWindowSegmentedControl;
@property (weak) IBOutlet NSTextField *productNameTextField;
@property (weak) IBOutlet NSTextField *productVersionTextField;
@property (weak) IBOutlet NSButton *urlButton;
@property (weak) IBOutlet NSScrollView *creditsView;
@property (weak) IBOutlet NSView *overviewView;
@property (weak) IBOutlet NSScrollView *licenseView;
@property (unsafe_unretained) IBOutlet NSTextView *licenseTextView;
@property (unsafe_unretained) IBOutlet NSTextView *creditsTextView;

@property (nonatomic, strong) NSString *productName;
@end

@implementation AboutWindow

#define LICENSE_FILES_DIR @"/usr/local/moonshot/LICENSES/"
#define COMBINED_LICENCE_FILE @"Moonshot-Combined-Licences-Text.rtf"

typedef enum {
    OverviewSegmentType = 0,
    CreditsSegmentType = 1,
    LicenseSegmentType = 2
} SegmentType;

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
    if (self = [super initWithWindowNibName: NSStringFromClass([AboutWindow class]) owner:self]) {
        // (nothing yet...)
    }
    return self;
}

#pragma mark - Window Lifecycle

- (void)windowDidLoad {
    [super windowDidLoad];
    [self setupView];
}

#pragma mark - Setup View

- (void)setupView {
    self.productName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    [self.productNameTextField setStringValue:self.productName];
    [self.productVersionTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Version", @""), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
    [self.creditsTextView setTextContainerInset:CGSizeMake(10.0, 15.0)];
    [self.licenseTextView setTextContainerInset:CGSizeMake(8.0, 12.0)];
    
    [self setupURLButton];
    [self setupLicenseViewLinks];
}

- (void)setupURLButton {
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.urlButton.bounds
                                                                options: (NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInKeyWindow )
                                                                  owner:self userInfo:nil];
    [self.urlButton addTrackingArea:trackingArea];
    [self.urlButton.layer setCornerRadius:10.0];
    [self.urlButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Product_Website", @""), self.productName]];
}

- (void)setupLicenseViewLinks
{
    NSMutableAttributedString *licenseString = [self.licenseTextView textStorage];
    
    NSUInteger length = [licenseString length];
    NSRange range = NSMakeRange(0, length);
    
    NSRange rangeLicenseFiles = [licenseString.string rangeOfString: @"here" options:0 range:range];
    range = NSMakeRange(rangeLicenseFiles.location + rangeLicenseFiles.length, length - (rangeLicenseFiles.location + rangeLicenseFiles.length));
    NSRange rangeCombinedLicenseFile = [licenseString.string rangeOfString: @"here" options:0 range:range];
    
    NSURL *urlLicenseFiles = [NSURL fileURLWithPath:LICENSE_FILES_DIR];
    NSURL *urlCombinedLicenseFile = [NSURL fileURLWithPath:[LICENSE_FILES_DIR stringByAppendingString:COMBINED_LICENCE_FILE]];
    
    [licenseString addAttribute:NSLinkAttributeName value:urlLicenseFiles range:rangeLicenseFiles];
    [licenseString addAttribute:NSLinkAttributeName value:urlCombinedLicenseFile range:rangeCombinedLicenseFile];
}

#pragma mark NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex
{
    NSString *combinedLicenceFileLoc = [(NSURL *)link absoluteString];
    if ([combinedLicenceFileLoc containsString:COMBINED_LICENCE_FILE]) {
        [self openCombinedLicenseFile];
        
        return YES;
    }
    
    return NO;
}

- (void)openCombinedLicenseFile
{
    [[NSWorkspace sharedWorkspace] openFile:[LICENSE_FILES_DIR stringByAppendingString:COMBINED_LICENCE_FILE]];
}

#pragma mark - NSSegmentedControl

- (IBAction)aboutWindowSegmentedControlValueChanged:(id)sender
{
    NSSegmentedControl *segmentedControl = (NSSegmentedControl *)sender;
    SegmentType segmentType = (SegmentType)segmentedControl.selectedSegment;
    
    switch (segmentType) {
        case OverviewSegmentType:
            self.overviewView.hidden = NO;
            self.creditsView.hidden = YES;
            self.licenseView.hidden = YES;
            break;
        case CreditsSegmentType:
            self.overviewView.hidden = YES;
            self.creditsView.hidden = NO;
            self.licenseView.hidden = YES;
            break;
        case LicenseSegmentType:
            self.overviewView.hidden = YES;
            self.creditsView.hidden = YES;
            self.licenseView.hidden = NO;
            break;
            
        default:
            break;
    }
}

#pragma mark - Button Actions

- (IBAction)urlButtonPressed:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"Website_URL", @"")]];
}

#pragma mark - Mouse events

- (void)mouseEntered:(NSEvent *)event {
    [self.urlButton.layer setBackgroundColor:[NSColor lightGrayColor].CGColor];
    [self setURLButtonTitleColor:[NSColor whiteColor]];
    [self.urlButton setImage:[NSImage imageNamed:@"selected_button"]];
}

- (void)mouseExited:(NSEvent *)event {
    [self.urlButton.layer setBackgroundColor:self.window.backgroundColor.CGColor];
    [self setURLButtonTitleColor:[NSColor blackColor]];
    [self.urlButton setImage:[NSImage imageNamed:@"default_button"]];
}

- (void)setURLButtonTitleColor:(NSColor *)titleColor {
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[self.urlButton attributedTitle]];
    NSRange titleRange = NSMakeRange(0, [colorTitle length]);
    [colorTitle addAttribute:NSForegroundColorAttributeName value:titleColor range:titleRange];
    [self.urlButton setAttributedTitle:colorTitle];
}

@end
