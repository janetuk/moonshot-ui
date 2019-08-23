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

#if GNOME_KEYRING

using Gee;

public class KeyringStore : KeyringStoreBase {
    private const GnomeKeyring.ItemType item_type = GnomeKeyring.ItemType.GENERIC_SECRET;

    /* Used to keep track of the association between IdCards and the item_id */
    private Gee.HashMap<IdCard,uint> item_map = new Gee.HashMap<IdCard,uint>();

    protected override Gee.List<IdCard> load_id_cards() {
        Gee.List<IdCard> id_card_list = new LinkedList<IdCard>();
        GnomeKeyring.AttributeList match = new GnomeKeyring.AttributeList();
        match.append_string(keyring_store_attribute, keyring_store_version);
        GLib.List<GnomeKeyring.Found> items;
        GnomeKeyring.find_items_sync(item_type, match, out items);
        foreach (unowned GnomeKeyring.Found entry in items) {
            KeyringStoreBase.Attributes new_attrs = new KeyringStoreBase.Attributes();
            for (int i = 0; i < entry.attributes.len; i++) {
                var attribute = ((GnomeKeyring.Attribute *) entry.attributes.data)[i];
                if (attribute.type == GnomeKeyring.AttributeType.STRING) {
                    unowned string value = attribute.string_value;
                    new_attrs.insert(attribute.name, value);
                }
            }

            var id_card = deserialize(new_attrs, entry.secret);
            id_card_list.add(id_card);
            item_map.set(id_card, entry.item_id);
        }
        return id_card_list;
    }

    protected override bool store_id_card(IdCard id_card)
    {
        GnomeKeyring.AttributeList attributes = new GnomeKeyring.AttributeList();
        var hash_attrs = serialize(id_card);
        uint item_id;
        hash_attrs.foreach((k, v) => {
            attributes.append_string((string) k, (string) v);
        });

        attributes.append_string(keyring_store_attribute, keyring_store_version);
        GnomeKeyring.Result result = GnomeKeyring.item_create_sync(null,
                                                                   item_type, id_card.display_name, attributes,
                                                                   id_card.store_password ? id_card.password : "",
                                                                   true, out item_id);
        item_map.set(id_card, item_id);
        logger.trace("Adding id_card %s: %u (size=%d)".printf(id_card.display_name, item_id, item_map.size));
        if (result != GnomeKeyring.Result.OK) {
            stdout.printf("GnomeKeyring.item_create_sync() failed. result: %d", result);
            return false;
        }
        return true;
    }

    protected override bool remove_id_card(IdCard id_card)
    {
        uint item_id = 0;
        if (!item_map.unset(id_card, out item_id)) {
            logger.error("IdCard does not seem to have an item_map on GNOME KEYRING!!");
            return false;
        }
        logger.trace("Deleting id_card %s: %u".printf(id_card.display_name, item_id));
        GnomeKeyring.Result result = GnomeKeyring.item_delete_sync(null, item_id);
        if (result != GnomeKeyring.Result.OK) {
            stdout.printf("GnomeKeyring.item_delete_sync() failed. result: %d", result);
            return false;
        }
        return true;
    }

    public static bool is_available() {
        return GnomeKeyring.is_available();
    }

    public override bool is_locked() {
        unowned GnomeKeyring.Info info;
        GnomeKeyring.Result rv = GnomeKeyring.get_info_sync(null, out info);
        if (rv != GnomeKeyring.Result.OK)
            return true;
        return info.get_is_locked();
    }
}

#endif
