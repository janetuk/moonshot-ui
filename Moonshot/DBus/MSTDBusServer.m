//
//  MSTDBusServer.c
//  Moonshot
//
//  Created by Ivan on 11/21/17.
//  Copyright © 2017 Devsy. All rights reserved.
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

void dbusStartListening()
{
    DBusError error;
    dbus_error_init(&error);
    
    DBusConnection *connection = dbus_bus_get(DBUS_BUS_SESSION, &error);
    if (!connection || dbus_error_is_set(&error)) {
        perror("Connection error.");
        exit(1);
    }
    
    const int ret = dbus_bus_request_name(connection, "org.janet.Moonshot", DBUS_NAME_FLAG_REPLACE_EXISTING, &error);
    if (ret != DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER || dbus_error_is_set(&error)) {
        perror("Ouch.");
        exit(1);
    }

    while (1 == 1) {
        dbus_connection_read_write(connection, 0);
        DBusMessage *const msg = dbus_connection_pop_message(connection);
        if (!msg) {
            continue;
        }
        if (dbus_message_is_method_call(msg, "org.janet.Moonshot", "GetIdentity")) {
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
                
                perror("Bad Input Params");
            } else {
                if (!(reply = dbus_message_new_method_return(msg))) {
                    perror("Bad Output Type");
                } else {
                    NSString *strNai = [NSString stringWithUTF8String:nai];
                    NSString *strService = [NSString stringWithUTF8String:service];
                    NSString *strPassword = [NSString stringWithUTF8String:password];
                    AppDelegate *delegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
                    [delegate initiateIdentitySelectionFor:strNai service:strService password:strPassword connection:connection reply:reply];
                }
            }
        } else if (dbus_message_is_method_call(msg, "org.janet.Moonshot", "GetDefaultIdentity")) {
            
        } else if (dbus_message_is_method_call(msg, "org.janet.Moonshot", "InstallIdCard")) {
            
        } else if (dbus_message_is_method_call(msg, "org.janet.Moonshot", "ConfirmCaCertificate")) {
            
        }
        dbus_message_unref(msg);
    }
}

