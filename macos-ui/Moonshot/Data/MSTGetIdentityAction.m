//
//  GetIdentityAction.m
//  Moonshot
//
//  Created by Ivan on 9/8/17.
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
	NSLog(@"(void)selectedIdentity:(Identity *)identity");
	NSString *combinedNaiOut = @"";
	if (identity.username.length && identity.realm.length) {
		combinedNaiOut = [NSString stringWithFormat:@"%@@%@",identity.username,identity.realm];
	}
    const char *nai_out = [combinedNaiOut UTF8String];
    const char *password_out;
    if (identity.has2fa) {
        NSString *combinedPasswordOut = @"";
        combinedPasswordOut = [NSString stringWithFormat:@"%@%@",identity.password,identity.secondFactor];
        password_out = [combinedPasswordOut UTF8String];
    }
    else {
        password_out = identity.password == nil ? "" : [identity.password UTF8String];
    }
    const char *server_certificate_hash_out = identity.trustAnchor.serverCertificate == nil ? [@"" UTF8String] : [identity.trustAnchor.serverCertificate UTF8String];
    const char *ca_certificate_out =  identity.trustAnchor.caCertificate == nil ? [@"" UTF8String] : [identity.trustAnchor.caCertificate UTF8String];
    const char *subject_name_constraint_out =  identity.trustAnchor.subject == nil ? [@"" UTF8String] : [identity.trustAnchor.subject UTF8String];
    const char *subject_alt_name_constraint_out =  identity.trustAnchor.subjectAlt == nil ? [@"" UTF8String] : [identity.trustAnchor.subjectAlt UTF8String];
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
