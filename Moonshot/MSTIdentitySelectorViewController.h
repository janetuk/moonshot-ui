//
//  MSTIdentitySelectorViewController.h
//  Moonshot
//
//  Created by Elena Jakjoska on 11/25/16.
//

#import <Cocoa/Cocoa.h>
#import "MSTGetIdentityAction.h"

@interface MSTIdentitySelectorViewController : NSViewController
@property (nonatomic, strong) MSTGetIdentityAction *getIdentityAction;
@end
