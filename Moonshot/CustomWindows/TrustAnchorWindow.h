//
//  TrustAnchorWindow.h
//  Moonshot
//
//  Created by Elena Jakjoska on 4/17/18.
//

#import <Cocoa/Cocoa.h>
#import "Identity.h"

@protocol TrustAnchorWindowDelegate <NSObject>
- (void)didSaveWithSuccess:(int)success andCertificate:(NSString *)certificate;
@end

@interface TrustAnchorWindow : NSViewController
@property (nonatomic, weak) id <TrustAnchorWindowDelegate>delegate;
@property (nonatomic, strong) Identity *identity;
@end
