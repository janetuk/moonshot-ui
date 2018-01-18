//
//  GetIdentityAction.m
//  Moonshot
//
//  Created by Ivan on 9/8/17.
//  Copyright © 2017 Devsy. All rights reserved.
//

#import "MSTGetIdentityAction.h"
#import "Identity.h"
#import "MSTConstants.h"
#import "AppDelegate.h"

@interface MSTGetIdentityAction () {
    DBusConnection *_connection;
    DBusMessage *_reply;
}

@end

@implementation MSTGetIdentityAction
- (instancetype)initFetchIdentityFor:(NSString *)nai service:(NSString *)service password:(NSString *)password connection:(DBusConnection *)connection reply:(DBusMessage *)reply {
    self = [super init];
    if (self) {
        _connection = connection;
        _reply = reply;
        _nai = nai;
        _service = service;
        _password = password;
    }
    return self;
}

- (void)selectedIdentity:(Identity *)identity {
	NSString *combinedNaiOut = @"";
	if (identity.username.length && identity.realm.length) {
		combinedNaiOut = [NSString stringWithFormat:@"%@@%@",identity.username,identity.realm];
	}
    const char *nai_out = [combinedNaiOut UTF8String];
	const char *password_out = identity.password == nil ? "" : [identity.password UTF8String];
    const char *server_certificate_hash_out = [@"" UTF8String];
    const char *ca_certificate_out = [@"" UTF8String];
    const char *subject_name_constraint_out = [@"" UTF8String];
    const char *subject_alt_name_constraint_out = [@"" UTF8String];
	const int  success = [identity.identityId isEqualToString:MST_NO_IDENTITY] ? 0 : 1;

    dbus_message_append_args(_reply,
                             DBUS_TYPE_STRING, &nai_out,
                             DBUS_TYPE_STRING, &password_out,
                             DBUS_TYPE_STRING, &server_certificate_hash_out,
                             DBUS_TYPE_STRING, &ca_certificate_out,
                             DBUS_TYPE_STRING, &subject_name_constraint_out,
                             DBUS_TYPE_STRING, &subject_alt_name_constraint_out,
                             DBUS_TYPE_BOOLEAN, &success,
                             DBUS_TYPE_INVALID);
    
    dbus_connection_send(_connection, _reply, NULL);
    dbus_message_unref(_reply);
}

@end
