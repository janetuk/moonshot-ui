using Gee;

#if GNOME_KEYRING
public class KeyringStore : Object, IIdentityCardStore {
    private LinkedList<IdCard> id_card_list;
    private const string keyring_store_attribute = "Moonshot";
    private const string keyring_store_version = "1.0";
    private const GnomeKeyring.ItemType item_type = GnomeKeyring.ItemType.GENERIC_SECRET;

    public void add_card(IdCard card) {
        id_card_list.add(card);
        store_id_cards ();
    }

    public IdCard? update_card(IdCard card) {
        id_card_list.remove(card);
        id_card_list.add(card);
        store_id_cards ();
        foreach (IdCard idcard in id_card_list)
            if (idcard.display_name == card.display_name)
                return idcard;
        return null;
    }

    public bool remove_card(IdCard card) {
        bool retval = id_card_list.remove(card);
        if (retval)
            store_id_cards ();
        return retval;
    }

    public IIdentityCardStore.StoreType get_store_type() {
        return IIdentityCardStore.StoreType.KEYRING;
    }

    public LinkedList<IdCard> get_card_list() {
        return id_card_list;
    }

    /* clear all keyring-stored ids (in preparation to store current list) */
    private void clear_keyring() {
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
     
    private void load_id_cards() {
        id_card_list.clear();

	GnomeKeyring.AttributeList match = new GnomeKeyring.AttributeList();
	match.append_string(keyring_store_attribute, keyring_store_version);
	GLib.List<GnomeKeyring.Found> items;
        GnomeKeyring.find_items_sync(item_type, match, out items);
        foreach(unowned GnomeKeyring.Found entry in items) {
            IdCard id_card = new IdCard ();
            int i;
            int rules_patterns_index = -1;
            int rules_always_confirm_index = -1;
            string store_password = null;
            for (i=0; i<entry.attributes.len; i++) {
                var attribute = ((GnomeKeyring.Attribute *) entry.attributes.data)[i];
		string value = attribute.string_value;
            	if (attribute.name == "Issuer") {
                    id_card.issuer = value;
		} else if (attribute.name == "Username") {
                    id_card.username = value;
		} else if (attribute.name == "DisplayName") {
                    id_card.display_name = value;
		} else if (attribute.name == "Services") {
                    id_card.services = value.split(";");
                } else if (attribute.name == "Rules-Pattern") {
                    rules_patterns_index = i;
                } else if (attribute.name == "Rules-AlwaysConfirm") {
                    rules_always_confirm_index = i;
                } else if (attribute.name == "CA-Cert") {
                    id_card.trust_anchor.ca_cert = value;
                } else if (attribute.name == "Server-Cert") {
                    id_card.trust_anchor.server_cert = value;
                } else if (attribute.name == "Subject") {
                    id_card.trust_anchor.subject = value;
                } else if (attribute.name == "Subject-Alt") {
                    id_card.trust_anchor.subject_alt = value;
                } else if (attribute.name == "StorePassword") {
                    store_password = value;
                }
            }
            if ((rules_always_confirm_index != -1) && (rules_patterns_index != -1)) {
                string rules_patterns_all = ((GnomeKeyring.Attribute *) entry.attributes.data)[rules_patterns_index].string_value;
                string rules_always_confirm_all = ((GnomeKeyring.Attribute *) entry.attributes.data)[rules_always_confirm_index].string_value;
                string [] rules_always_confirm = rules_always_confirm_all.split(";");
                string [] rules_patterns = rules_patterns_all.split(";");
                if (rules_patterns.length == rules_always_confirm.length) {
                   Rule[] rules = new Rule[rules_patterns.length];
                   for (int j=0; j<rules_patterns.length; j++) {
                       rules[j].pattern = rules_patterns[j];
                       rules[j].always_confirm = rules_always_confirm[j];
                   }
                   id_card.rules = rules;
                }
            }

            if (store_password != null)
                id_card.store_password = (store_password == "yes");
            else
                id_card.store_password = ((entry.secret != null) && (entry.secret != ""));

            if (id_card.store_password)
                id_card.password = entry.secret;
            else
                id_card.password = null;
            id_card_list.add(id_card);
        }
    }

    public void store_id_cards () {
        clear_keyring();
        foreach (IdCard id_card in this.id_card_list) {
            string[] rules_patterns = new string[id_card.rules.length];
            string[] rules_always_conf = new string[id_card.rules.length];
            
            for (int i=0; i<id_card.rules.length; i++) {
                rules_patterns[i] = id_card.rules[i].pattern;
                rules_always_conf[i] = id_card.rules[i].always_confirm;
            }
            string patterns = string.joinv(";", rules_patterns);
            string always_conf = string.joinv(";", rules_always_conf);
            string services = string.joinv(";", id_card.services);
            GnomeKeyring.AttributeList attributes = new GnomeKeyring.AttributeList();
            uint32 item_id;
            attributes.append_string(keyring_store_attribute, keyring_store_version);
            attributes.append_string("Issuer", id_card.issuer);
            attributes.append_string("Username", id_card.username);
            attributes.append_string("DisplayName", id_card.display_name);
            attributes.append_string("Services", services);
            attributes.append_string("Rules-Pattern", patterns);
            attributes.append_string("Rules-AlwaysConfirm", always_conf);
            attributes.append_string("CA-Cert", id_card.trust_anchor.ca_cert);
            attributes.append_string("Server-Cert", id_card.trust_anchor.server_cert);
            attributes.append_string("Subject", id_card.trust_anchor.subject);
            attributes.append_string("Subject-Alt", id_card.trust_anchor.subject_alt);
            attributes.append_string("StorePassword", id_card.store_password ? "yes" : "no");

            GnomeKeyring.Result result = GnomeKeyring.item_create_sync(null,
                item_type, id_card.display_name, attributes,
                id_card.store_password ? id_card.password : "",
                true, out item_id);
            if (result != GnomeKeyring.Result.OK) {
                stdout.printf("GnomeKeyring.item_create_sync() failed. result: %d", result);
            }
        }
        load_id_cards();
    }

    public KeyringStore () {
        id_card_list = new LinkedList<IdCard>();
        load_id_cards();
    }
}

#endif
