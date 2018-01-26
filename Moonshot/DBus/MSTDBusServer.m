//
//  MSTDBusServer.c
//  Moonshot
//
//  Created by Ivan on 11/21/17.
//

#include "MSTDBusServer.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <dbus/dbus.h>
#include <dbus/dbus-glib-lowlevel.h>
#include <glib/gspawn.h>
#include <dbus/dbus-glib.h>
#include <stdbool.h>
#import "AppDelegate.h"
#import "MSTIdentityDataLayer.h"

void dbusStartListening()
{
    DBusError error;
    dbus_error_init(&error);
    
    DBusConnection *connection = dbus_bus_get(DBUS_BUS_SESSION, &error);
    if (!connection || dbus_error_is_set(&error)) {
        perror("Moonshot.IdentitySelector Connection error.");
		return;
    }
    
    const int ret = dbus_bus_request_name(connection, "org.janet.Moonshot", DBUS_NAME_FLAG_REPLACE_EXISTING, &error);
    if (ret != DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER || dbus_error_is_set(&error)) {
        perror(" Moonshot.IdentitySelector Dbus Error.");
		return;
    }

	while (1 == 1) {
        dbus_connection_read_write(connection, 0);
        DBusMessage *const msg = dbus_connection_pop_message(connection);
        if (!msg) {
            continue;
        }
        if (dbus_message_is_method_call(msg, "org.janet.Moonshot", "GetIdentity")) {
			NSLog(@"GetIdentity");

            const char *nai;
            const char *password;
            const char *service;
            
            DBusError err;
            dbus_error_init(&err);
            DBusMessage *reply = NULL;
            if (!dbus_message_get_args(msg, &err,
                                       DBUS_TYPE_STRING, &nai,
                                       DBUS_TYPE_STRING, &password,
                                       DBUS_TYPE_STRING, &service,
                                       DBUS_TYPE_INVALID)) {
                
                perror("Moonshot.IdentitySelector Bad Input Params");
            } else {
                if (!(reply = dbus_message_new_method_return(msg))) {
                    perror("Moonshot.IdentitySelector Bad Output Type");
                } else {
                    NSString *strNai = [NSString stringWithUTF8String:nai];
                    NSString *strService = [NSString stringWithUTF8String:service];
                    NSString *strPassword = [NSString stringWithUTF8String:password];
                    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
                    [delegate initiateIdentitySelectionFor:strNai service:strService password:strPassword connection:connection reply:reply];
                }
            }
        } else if (dbus_message_is_method_call(msg, "org.janet.Moonshot", "GetDefaultIdentity")) {
			NSLog(@"Moonshot.IdentitySelector GetDefaultIdentity");
        } else if (dbus_message_is_method_call(msg, "org.janet.Moonshot", "InstallIdCard")) {
			NSLog(@"Moonshot.IdentitySelector InstallIdCard");
        } else if (dbus_message_is_method_call(msg, "org.janet.Moonshot", "ConfirmCaCertificate")) {
			NSLog(@"Moonshot.IdentitySelector ConfirmCaCertificate");
			
			const char *identity_name;
			const char *realm;
			const char *hash_str;
			
			DBusError err;
			dbus_error_init(&err);
			DBusMessage *reply = NULL;
			if (!dbus_message_get_args(msg, &err,
									   DBUS_TYPE_STRING, &identity_name,
									   DBUS_TYPE_STRING, &realm,
									   DBUS_TYPE_STRING, &hash_str,
									   DBUS_TYPE_INVALID)) {
				
				perror("Moonshot.IdentitySelector Bad Input Params");
			} else {
				if (!(reply = dbus_message_new_method_return(msg))) {
					perror("Moonshot.IdentitySelector Bad Output Type");
				} else {
				}

				Identity *identity = [[MSTIdentityDataLayer sharedInstance] getExistingIdentitySelectionFor:[NSString stringWithUTF8String:identity_name] realm:[NSString stringWithUTF8String:realm]];
				int  success = 1;

				if (identity.trustAnchor.serverCertificate.length > 0) {
					if ([identity.trustAnchor.serverCertificate isEqualToString:[NSString stringWithUTF8String:hash_str]]) {
						success = 1;
					} else {
						success = 0;
					}
				} else {
#warning todo
					if (identity.trustAnchor == nil) {
						identity.trustAnchor = [[TrustAnchor alloc] init];
					}
					identity.trustAnchor.serverCertificate = [NSString stringWithUTF8String:hash_str];
					[[MSTIdentityDataLayer sharedInstance] editIdentity:identity withBlock:nil];
					success = 1;
				}
				
				dbus_message_append_args(reply,
										 DBUS_TYPE_INT32, &success,
										 DBUS_TYPE_BOOLEAN, &success,
										 DBUS_TYPE_INVALID);
				
				dbus_connection_send(connection, reply, NULL);
				dbus_message_unref(reply);
				AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
				[NSApp terminate:delegate];
			}
		} else {
			NSLog(@"Moonshot.IdentitySelector None");
		}
        dbus_message_unref(msg);
    }
}

