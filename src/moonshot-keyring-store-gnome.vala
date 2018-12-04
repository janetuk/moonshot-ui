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

    /* clear all keyring-stored ids (in preparation to store current list) */
    protected override void clear_keyring() {
      GnomeKeyring.AttributeList match = new GnomeKeyring.AttributeList();
      match.append_string(keyring_store_attribute, keyring_store_version);
      GLib.List<GnomeKeyring.Found> items;
      GnomeKeyring.find_items_sync(item_type, match, out items);
      foreach(unowned GnomeKeyring.Found entry in items) {
	GnomeKeyring.Result result = GnomeKeyring.item_delete_sync(null, entry.item_id);
	if (result != GnomeKeyring.Result.OK) {
	  stdout.printf("GnomeKeyring.item_delete_sync() failed. result: %d", result);
	}
      }
    }

    protected override void load_id_cards() {
        id_card_list.clear();

        GnomeKeyring.AttributeList match = new GnomeKeyring.AttributeList();
        match.append_string(keyring_store_attribute, keyring_store_version);
        GLib.List<GnomeKeyring.Found> items;
        GnomeKeyring.find_items_sync(item_type, match, out items);
        foreach(unowned GnomeKeyring.Found entry in items) {
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
        }
    }

    internal override void store_id_cards() {
        logger.trace("store_id_cards");
        clear_keyring();
        foreach (IdCard id_card in this.id_card_list) {
            /* workaround for Centos vala array property bug: use temp array */
            GnomeKeyring.AttributeList attributes = new GnomeKeyring.AttributeList();
            uint32 item_id;
            var hash_attrs = serialize(id_card);
	        hash_attrs.foreach((k, v) => {
                attributes.append_string((string) k, (string) v);
            });

            attributes.append_string(keyring_store_attribute, keyring_store_version);

            GnomeKeyring.Result result = GnomeKeyring.item_create_sync(null,
                                                                       item_type, id_card.display_name, attributes,
                                                                       id_card.store_password ? id_card.password : "",
                                                                       true, out item_id);
            if (result != GnomeKeyring.Result.OK) {
                stdout.printf("GnomeKeyring.item_create_sync() failed. result: %d", result);
            }
        }
	try {
	    load_id_cards();
	} catch(GLib.Error e) {
	    logger.error(@"Unable to load ID cards: $(e.message)\n");
	}

    }

    public static bool is_available()
    {
	return GnomeKeyring.is_available();
    }

    public override bool is_locked() {
        unowned GnomeKeyring.Info info;
        GnomeKeyring.Result rv = GnomeKeyring.get_info_sync(null, out info);
        if (rv != GnomeKeyring.Result.OK)
            return true;
        return info.get_is_locked();
    }

    public override bool unlock(string password) {
        GnomeKeyring.Result rv = GnomeKeyring.unlock_sync(null, password);
        if (rv != GnomeKeyring.Result.OK)
            return false;
        load_id_cards();
        return true;
    }

}

#endif
