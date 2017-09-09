//
//  MSTRequestGetIdentityScriptCommand.m
//  Moonshot
//
//  Created by Ivan on 9/8/17.
//  Copyright © 2017 Devsy. All rights reserved.
//

#import "MSTRequestGetIdentityScriptCommand.h"
#import "AppDelegate.h"

@implementation MSTRequestGetIdentityScriptCommand
- (id)performDefaultImplementation {
    NSDictionary *inputArgs = [self evaluatedArguments];
    
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    NSString *nai = inputArgs[@"nai"] != nil ? inputArgs[@"nai"] : @"";
    NSString *service = inputArgs[@"service"] != nil ? inputArgs[@"service"] : @"";
    NSString *password = inputArgs[@"password"] != nil ? inputArgs[@"password"] : @"";

    [delegate initiateIdentitySelectionFor:nai service:service password:password];
    return nil;
}
@end
