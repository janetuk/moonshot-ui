//
//  MSTStatusGetIdentityScriptComment.m
//  Moonshot
//
//  Created by Ivan on 9/8/17.
//  Copyright © 2017 Devsy. All rights reserved.
//

#import "MSTStatusGetIdentityScriptComment.h"
#import "AppDelegate.h"

@implementation MSTStatusGetIdentityScriptComment
- (id)performDefaultImplementation {
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    BOOL status = delegate.ongoingIdentitySelectAction.selectedIdentity != nil;
    return [NSNumber numberWithBool:status];
}
@end
