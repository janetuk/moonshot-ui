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

    /* Used to keep track of the association between IdCards and Items */
    private Gee.HashMap<IdCard,Item> item_map = new Gee.HashMap<IdCard,Item>();

    protected override bool remove_id_card(IdCard id_card) {
        Item item;
        if (!item_map.unset(id_card, out item)) {
            logger.error("IdCard does not seem to have an item_map on LIBSECRET!!");
            return false;
        }
        try {
            bool res = item.delete_sync();
            if (!res) {
                stdout.printf("Failed to delete item: %s\n", item.get_label());
                return false;
            }
        } catch (GLib.Error e) {
            stdout.printf("Error deleting item: %s\n", e.message);
            return false;
        }
        return true;
    }

    protected override Gee.List<IdCard> load_id_cards() throws GLib.Error {
        Gee.List<IdCard> id_card_list = new Gee.LinkedList<IdCard>();
        var match_attributes = new KeyringStoreBase.Attributes();
        match_attributes.insert(keyring_store_attribute, keyring_store_version);
        GLib.List<Item> items = secret_collection.search_sync(schema, match_attributes,
                                                              SearchFlags.UNLOCK|SearchFlags.LOAD_SECRETS|SearchFlags.ALL);
        foreach (unowned Item entry in items) {
            var secret = entry.get_secret();
            string secret_text = null;
            if (secret != null)
                secret_text = secret.get_text();
            var id_card = deserialize(entry.attributes, secret_text);
            id_card_list.add(id_card);
            item_map.set(id_card, entry);
        }
        return id_card_list;
    }

    protected override bool store_id_card(IdCard id_card) {
        try {
            var attributes = serialize(id_card);
            var secret_value = new Secret.Value(id_card.store_password ? id_card.password : "", -1, "password");
            Item item = Item.create_sync(secret_collection, schema, attributes, id_card.display_name, secret_value,
                                         ItemCreateFlags.REPLACE);
            item_map.set(id_card, item);
        } catch(GLib.Error e) {
            logger.error(@"Unable to store $(id_card.display_name): $(e.message)\n");
            return false;
        }
        return true;
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

}

#endif
