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

private Collection? find_secret_collection()
{
    Collection secret_collection = null;
    try {
        Service service = Service.get_sync(ServiceFlags.OPEN_SESSION);
        secret_collection = Collection.for_alias_sync(service, COLLECTION_DEFAULT,
                                                      CollectionFlags.NONE);
    } catch(GLib.Error e) {
        stdout.printf("Unable to load secret service: %s\n", e.message);
    }
    return secret_collection;
}

public class KeyringStore : KeyringStoreBase {
    /*
    * We choose to remain compatible with the way we stored secrets
    * using libgnomekeyring.  As a result, we cannot use our own schema
    * identifier.  Using our own schema might get us a nice icon in
    * seahorse, but would not save much code.
    */
    private const SchemaAttributeType sstring = SchemaAttributeType.STRING;
    private static Schema schema = new Schema("org.freedesktop.Secret.Generic", SchemaFlags.NONE,
                                              "Moonshot", sstring,
                                              "Issuer", sstring,
                                              "Username", sstring,
                                              "DisplayName", sstring,
                                              "Has2FA", sstring,
                                              "Services", sstring,
                                              "Rules-Pattern", sstring,
                                              "Rules-AlwaysConfirm", sstring,
                                              "CA-Cert", sstring,
                                              "Server-Cert", sstring,
                                              "Subject", sstring,
                                              "Subject-Alt", sstring,
                                              "TA_DateTime_Added", sstring,
                                              "StorePassword", sstring);
    private static Collection? secret_collection = find_secret_collection();

    /* clear all keyring-stored ids (in preparation to store current list) */
    protected override void clear_keyring() {
        GLib.List<Item> items;
        try {
            items = secret_collection.search_sync(schema, match_attributes, SearchFlags.ALL);
        } catch (GLib.Error e) {
            stdout.printf("Failed to find items to delete: %s\n", e.message);
            return;
        }
        foreach(unowned Item entry in items) {
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

        GLib.List<Item> items = secret_collection.search_sync(schema, match_attributes,
                                                              SearchFlags.UNLOCK|SearchFlags.LOAD_SECRETS|SearchFlags.ALL);
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
                var attributes = serialize(id_card);
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

    public static bool is_available()
    {
        if (secret_collection == null) {
            secret_collection = find_secret_collection();
        }

        return secret_collection != null;
    }

    public override bool is_locked() {
        return secret_collection.get_locked();
    }

    public override bool unlock(string password) {
        return false;
    }

}

#endif
