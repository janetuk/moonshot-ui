/*
 * This file is part of the Ideal Library
 * Copyright (C) 2010 Rafael Fernández López <ereslibre@ereslibre.es>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <dbus/dbus.h>
#include <dbus/dbus-glib-lowlevel.h>
#include <glib/gspawn.h>
#include <dbus/dbus-glib.h>
#include <stdbool.h>

int main(int argc, char ** argv)
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
            const char *nai_out = "nainai";
            const char *password_out = "passpass";
            const char *server_certificate_hash_out = "sercert";
            const char *ca_certificate_out = "ca_cert";
            const char *subject_name_constraint_out = "sub_cert";
            const char *subject_alt_name_constraint_out = "sub_alt";
    		const int  success = 1;

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
        		printf ("Got params: %s %s %s\n", nai, password, service);
        		if (!(reply = dbus_message_new_method_return(msg))) {
        			perror("Bad Output Type");
        		} else {
                    printf ("HERE %s \n",service);
					dbus_message_append_args(reply, 
						DBUS_TYPE_STRING, &nai_out,
						DBUS_TYPE_STRING, &password_out,
						DBUS_TYPE_STRING, &server_certificate_hash_out,
						DBUS_TYPE_STRING, &ca_certificate_out,
						DBUS_TYPE_STRING, &subject_name_constraint_out,
						DBUS_TYPE_STRING, &subject_alt_name_constraint_out,
						DBUS_TYPE_BOOLEAN, &success, 
						DBUS_TYPE_INVALID);

						if (!dbus_connection_send(connection, reply, NULL)) {
							return DBUS_HANDLER_RESULT_NEED_MEMORY;
						}

						DBusHandlerResult result = DBUS_HANDLER_RESULT_HANDLED;

					dbus_message_unref(reply);
					return 1;
        		}
			}

			// if (!(reply = dbus_message_new_method_return(message)))
			// 	goto fail;

			// result = server_get_properties_handler(property, conn, reply);
			// dbus_message_unref(reply);
			// return result;
        }
        dbus_message_unref(msg);
    }

    exit(0);
}

// DBusHandlerResult server_get_properties_handler(const char *property, DBusConnection *conn, DBusMessage *reply)
// {
// 	if (!strcmp(property, "Version")) {
// 		dbus_message_append_args(reply,
// 					 DBUS_TYPE_STRING, &version,
// 					 DBUS_TYPE_INVALID);
// 	} else
// 		/* Unknown property */
// 		return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;

// 	if (!dbus_connection_send(conn, reply, NULL))
// 		return DBUS_HANDLER_RESULT_NEED_MEMORY;
// 	return DBUS_HANDLER_RESULT_HANDLED;
// }
