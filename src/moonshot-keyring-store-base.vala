/*
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
using Gee;

#if GNOME_KEYRING || LIBSECRET_KEYRING

public abstract class KeyringStoreBase : Object, IIdentityCardStore {
    protected static MoonshotLogger logger = get_logger("KeyringStore");

    internal const string keyring_store_attribute = "Moonshot";
    internal const string keyring_store_version = "1.0";

    /*
     * This class is directly useful for the libsecret implementation.
     * However, we convert the gnome keyring attributes into a HashTable
     * so we can share the serialization code between the two
     * implementations.  This ends up decreasing complexity even of the
     * gnome keyring code
    */
    protected class Attributes: GLib.HashTable<string, string> {
        public Attributes() {
            base.full(GLib.str_hash, GLib.str_equal, GLib.g_free, GLib.g_free);
        }
    }

    protected static IdCard deserialize(GLib.HashTable<string,string> attrs, string? secret)
    {
        IdCard id_card = new IdCard();
        unowned string store_password = attrs.lookup("StorePassword");
        unowned string ca_cert = attrs.lookup("CA-Cert") ?? "";
        unowned string server_cert = attrs.lookup("Server-Cert") ?? "";
        unowned string subject = attrs.lookup("Subject") ?? "";
        unowned string subject_alt = attrs.lookup("Subject-Alt") ?? "";
        unowned string ta_datetime_added = attrs.lookup("TA_DateTime_Added");

        id_card.issuer = attrs.lookup("Issuer");
        id_card.username = attrs.lookup("Username");
        id_card.display_name = attrs.lookup("DisplayName");
        id_card.has_2fa = (attrs.lookup("Has2FA") == "yes");

        unowned string services = attrs.lookup("Services");
        if ((services != null) && services != "") {
            id_card.update_services(services.split(";"));
        }
        var ta = new TrustAnchor(ca_cert, server_cert, subject, subject_alt);
        if (ta_datetime_added != null) {
            ta.set_datetime_added(ta_datetime_added);
        }
        id_card.set_trust_anchor_from_store(ta);

        unowned string rules_pattern_all = attrs.lookup("Rules-Pattern");
        unowned string rules_always_confirm_all = attrs.lookup("Rules-AlwaysConfirm");
        if ((rules_pattern_all != null) && (rules_always_confirm_all != null)) {
            string[] rules_patterns = rules_pattern_all.split(";");
            string[] rules_always_confirm = rules_always_confirm_all.split(";");
            if (rules_patterns.length == rules_always_confirm.length) {
                Rule[] rules = new Rule[rules_patterns.length];
                for (int i = 0; i < rules_patterns.length; i++) {
                    rules[i].pattern = (owned) rules_patterns[i];
                    rules[i].always_confirm = (owned) rules_always_confirm[i];
                }
                id_card.rules = rules;
            }
        }

        if (store_password != null)
            id_card.store_password = (store_password == "yes");
        else
            id_card.store_password = ((secret != null) && (secret != ""));

        if (id_card.store_password)
            id_card.password = secret;
        else
            id_card.password = null;

        return id_card;
    }

    internal static Attributes serialize(IdCard id_card)
    {
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
        Attributes attributes = new Attributes();
        attributes.insert(keyring_store_attribute, keyring_store_version);
        attributes.insert("Issuer", id_card.issuer);
        attributes.insert("Username", id_card.username);
        attributes.insert("DisplayName", id_card.display_name);
        attributes.insert("Has2FA", id_card.has_2fa ? "yes" : "no");
        attributes.insert("Services", services);
        attributes.insert("Rules-Pattern", patterns);
        attributes.insert("Rules-AlwaysConfirm", always_conf);
        attributes.insert("CA-Cert", id_card.trust_anchor.ca_cert);
        attributes.insert("Server-Cert", id_card.trust_anchor.server_cert);
        attributes.insert("Subject", id_card.trust_anchor.subject);
        attributes.insert("Subject-Alt", id_card.trust_anchor.subject_alt);
        attributes.insert("TA_DateTime_Added", id_card.trust_anchor.datetime_added);
        attributes.insert("StorePassword", id_card.store_password ? "yes" : "no");
        return attributes;
    }

    public void add_card(IdCard card) {
        logger.trace("add_card: Adding card '%s' with services: '%s'"
                     .printf(card.display_name, card.get_services_string("; ")));
        if (!store_id_card(card))
            logger.error("Could not add card %s!".printf(card.display_name));
    }

    public IdCard? update_card(IdCard card) {
        logger.trace("add_card: Updating card '%s' with services: '%s'"
                     .printf(card.display_name, card.get_services_string("; ")));
        if (!remove_id_card(card)) {
            logger.error("Could not update card %s!".printf(card.display_name));
            return null;
        }
        if (!store_id_card(card)) {
            logger.error("Could not update card %s!".printf(card.display_name));
            return null;
        }
        return card;
    }

    public bool remove_card(IdCard card) {
        logger.trace("remove_card: Removing card '%s' with services: '%s'"
                     .printf(card.display_name, card.get_services_string("; ")));
        return remove_id_card(card);
    }

    public IIdentityCardStore.StoreType get_store_type() {
        return IIdentityCardStore.StoreType.KEYRING;
    }

    public abstract string get_store_name();

    public Gee.List<IdCard> get_card_list() {
        try {
            return load_id_cards();
        } catch (GLib.Error e) {
            logger.error(@"Unable to load ID Cards: $(e.message)\n");
            return new LinkedList<IdCard>();
        }
    }

    protected abstract Gee.List<IdCard> load_id_cards() throws GLib.Error;
    protected abstract bool store_id_card(IdCard id_card);
    protected abstract bool remove_id_card(IdCard id_card);

    protected KeyringStoreBase() {}
}

#endif
