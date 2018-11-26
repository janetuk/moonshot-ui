/*
* Copyright (C) 2018   Sam Hartman
* Copyright (c) 2011-2016, JANET(UK)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of JANET(UK) nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
*/

#if LIBSECRET_KEYRING

using Secret;

public class KeyringStore : KeyringStoreBase {
    /*
    * We choose to remain compatible with the way we stored secrets
    * using libgnomekeyring.  As a result, we cannot use our own schema
    * identifier.  Using our own schema might get us a nice icon in
    * seahorse, but would not save much code. 
    */
    private static Schema schema = new Schema("org.freedesktop.Secret.Generic", SchemaFlags.NONE);
    private static Collection secret_collection;
    

    /* clear all keyring-stored ids (in preparation to store current list) */
    protected override void clear_keyring() {
	GLib.List<Item> items;
	try {
	    items = secret_collection.search_sync(schema, match_attributes,
						  SearchFlags.NONE);
	} catch (GLib.Error e) {
	    stdout.printf("Failed to find items to delete: %s\n", e.message);
	    return;
	}
        foreach(unowned Item  entry in items) {
	    try {
	        bool res = entry.delete_sync();
		if (!res) {
		    stdout.printf("Failed to delete item: %s\n", entry.get_label());
		}
	    } catch (GLib.Error e) {
		stdout.printf("Error deleting item: %s\n", e.message);
	    }
	}
    }

    protected override void load_id_cards()  throws GLib.Error {
        id_card_list.clear();

	GLib.List<Item> items = secret_collection.search_sync(
							      schema, match_attributes,
							      SearchFlags.UNLOCK|SearchFlags.LOAD_SECRETS);
        foreach(unowned Item entry in items) {
	    var secret = entry.get_secret();
	    string secret_text = null;
	    if (secret != null)
		secret_text = secret.get_text();
	    var id_card = deserialize(entry.attributes, secret_text);
            id_card_list.add(id_card);
        }
    }

    internal override void store_id_cards() {
        logger.trace("store_id_cards");
        clear_keyring();
        foreach (IdCard id_card in this.id_card_list) {
	    try {
		/* workaround for Centos vala array property bug: use temp array */
		var rules = id_card.rules;
		string[] rules_patterns = new string[rules.length];
		string[] rules_always_conf = new string[rules.length];
            
		for (int i = 0; i < rules.length; i++) {
		    rules_patterns[i] = rules[i].pattern;
		    rules_always_conf[i] = rules[i].always_confirm;
		}
		string patterns = string.joinv(";", rules_patterns);
		string always_conf = string.joinv(";", rules_always_conf);
		string services = id_card.get_services_string(";");
		KeyringStoreBase.Attributes attributes = new KeyringStoreBase.Attributes();
		attributes.insert(keyring_store_attribute, keyring_store_version);
		attributes.insert("Issuer", id_card.issuer);
		attributes.insert("Username", id_card.username);
		attributes.insert("DisplayName", id_card.display_name);
		attributes.insert("Services", services);
		attributes.insert("Rules-Pattern", patterns);
		attributes.insert("Rules-AlwaysConfirm", always_conf);
		attributes.insert("CA-Cert", id_card.trust_anchor.ca_cert);
		attributes.insert("Server-Cert", id_card.trust_anchor.server_cert);
		attributes.insert("Subject", id_card.trust_anchor.subject);
		attributes.insert("Subject-Alt", id_card.trust_anchor.subject_alt);
		attributes.insert("TA_DateTime_Added", id_card.trust_anchor.datetime_added);
		attributes.insert("StorePassword", id_card.store_password ? "yes" : "no");

		password_storev_sync(schema, attributes, null, id_card.display_name,
				     id_card.store_password?id_card.password: "");
	    } catch(GLib.Error e) {
		logger.error(@"Unable to store $(id_card.display_name): $(e.message)\n");
	}
	
        }
        try {
	    load_id_cards();
	} catch (GLib.Error e) {
	    logger.error(@"Unable to load ID Cards: $(e.message)\n");
	}
	
     }

}

#endif
