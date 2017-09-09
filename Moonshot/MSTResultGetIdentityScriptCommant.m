//
//  MSTResultGetIdentityScriptCommant.m
//  Moonshot
//
//  Created by Ivan on 9/8/17.
//  Copyright © 2017 Devsy. All rights reserved.
//

#import "MSTResultGetIdentityScriptCommant.h"
#import "AppDelegate.h"
#import "Identity.h"

@implementation MSTResultGetIdentityScriptCommant
- (id)performDefaultImplementation {
    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    Identity *ident = delegate.ongoingIdentitySelectAction.selectedIdentity;
    
    return [NSString stringWithFormat:@"{\"nai_out\":\"%@\", \"password_out\":\"%@\", \"server_certificate_hash_out\":\"%@\",  \"ca_certificate_out\":\"%@\",  \"subject_name_constraint_out\":\"%@\",  \"subject_alt_name_constraint_out\":\"%@\"}",ident.username, ident.password, @"", @"", @"", @""];
}
@end


//@property (nonatomic,strong) NSString *identityId;
//@property (nonatomic,strong) NSString *displayName;
//@property (nonatomic,strong) NSString *username;
//@property (nonatomic,strong) NSString *password;
//@property (nonatomic,strong) NSString *realm;
//@property (nonatomic, assign) BOOL passwordRemembered;
//@property (nonatomic, assign) BOOL caCertificate;
//@property (nonatomic, strong) NSDate *dateAdded;
//@property (nonatomic, strong) NSString *trustAnchor;
//@property (nonatomic, retain) NSArray *trustAnchorArray;
//@property (nonatomic, retain) NSMutableArray *servicesArray;


//char          **nai_out,
//char          **password_out,
//char          **server_certificate_hash_out,
//char          **ca_certificate_out,
//char          **subject_name_constraint_out,
//char          **subject_alt_name_constraint_out,
