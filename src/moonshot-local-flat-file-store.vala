/*
 * Copyright (c) 2011-2014, JANET(UK)
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

public class LocalFlatFileStore : Object, IIdentityCardStore {
    private LinkedList<IdCard> id_card_list;
    private const string FILE_NAME = "identities.txt";

    public void add_card(IdCard card) {
        id_card_list.add(card);
        store_id_cards();
    }

    public IdCard? update_card(IdCard card) {
        id_card_list.remove(card);
        id_card_list.add(card);
        store_id_cards();
        foreach(IdCard idcard in id_card_list)
        if (idcard.display_name == card.display_name)
            return idcard;
        return null;
    }

    public bool remove_card(IdCard card) {
        if (id_card_list.remove(card)) {
            store_id_cards();
            return true;
        }
        return false;
    }

    public LinkedList<IdCard> get_card_list() {
        return id_card_list; 
    }

    public IIdentityCardStore.StoreType get_store_type() {
        return IIdentityCardStore.StoreType.FLAT_FILE;
    }
     
    private void load_id_cards() {
        id_card_list.clear();
        var key_file = new KeyFile();
        var path = get_data_dir();
        var filename = Path.build_filename(path, FILE_NAME);
        
        try {
            key_file.load_from_file(filename, KeyFileFlags.NONE);
        }
        catch (Error e) {
            stdout.printf("Error: %s\n", e.message);
            return;
        }

        var identities_uris = key_file.get_groups();
        foreach (string identity in identities_uris) {
            try {
                IdCard id_card = new IdCard();

                id_card.issuer = key_file.get_string(identity, "Issuer");
                id_card.username = key_file.get_string(identity, "Username");
                id_card.password = key_file.get_string(identity, "Password");
                id_card.services = key_file.get_string_list(identity, "Services");
                id_card.display_name = key_file.get_string(identity, "DisplayName");
                if (key_file.has_key(identity, "StorePassword")) {
                    id_card.store_password = (key_file.get_string(identity, "StorePassword") == "yes");
                } else {
                    id_card.store_password = (id_card.password != null) && (id_card.password != "");
                }
                
                if (key_file.has_key(identity, "Rules-Patterns") &&
                    key_file.has_key(identity, "Rules-AlwaysConfirm")) {
                    string [] rules_patterns =    key_file.get_string_list(identity, "Rules-Patterns");
                    string [] rules_always_conf = key_file.get_string_list(identity, "Rules-AlwaysConfirm");
                    
                    if (rules_patterns.length == rules_always_conf.length) {
                        Rule[] rules = new Rule[rules_patterns.length];
                        for (int i = 0; i < rules_patterns.length; i++) {
                            rules[i] = {rules_patterns[i], rules_always_conf[i]};
                        }
                        id_card.rules = rules;
                    }
                }
                
                // Trust anchor 
                id_card.trust_anchor.ca_cert = key_file.get_string(identity, "CA-Cert").strip();
                id_card.trust_anchor.subject = key_file.get_string(identity, "Subject");
                id_card.trust_anchor.subject_alt = key_file.get_string(identity, "SubjectAlt");
                id_card.trust_anchor.server_cert = key_file.get_string(identity, "ServerCert");

                id_card_list.add(id_card);
            }
            catch (Error e) {
                stdout.printf("Error:  %s\n", e.message);
            }
        }
    }

    private string get_data_dir() {
        string path;
        path = Path.build_filename(Environment.get_user_data_dir(),
                                   Config.PACKAGE_TARNAME);
                                    
        if (!FileUtils.test(path, FileTest.EXISTS)) {
            DirUtils.create_with_parents(path, 0700);
        }
        return path;
    }
    
    public void store_id_cards() {
        var key_file = new KeyFile();
        foreach (IdCard id_card in this.id_card_list) {
            /* workaround for Centos vala array property bug: use temp arrays */
            var rules = id_card.rules;
            var services = id_card.services;
            string[] empty = {};
            string[] rules_patterns = new string[rules.length];
            string[] rules_always_conf = new string[rules.length];
            
            for (int i = 0; i < rules.length; i++) {
                rules_patterns[i] = rules[i].pattern;
                rules_always_conf[i] = rules[i].always_confirm;
            }

            key_file.set_string(id_card.display_name, "Issuer", id_card.issuer ?? "");
            key_file.set_string(id_card.display_name, "DisplayName", id_card.display_name ?? "");
            key_file.set_string(id_card.display_name, "Username", id_card.username ?? "");
            if (id_card.store_password && (id_card.password != null))
                key_file.set_string(id_card.display_name, "Password", id_card.password);
            else
                key_file.set_string(id_card.display_name, "Password", "");
            key_file.set_string_list(id_card.display_name, "Services", services ?? empty);

            if (rules.length > 0) {
                key_file.set_string_list(id_card.display_name, "Rules-Patterns", rules_patterns);
                key_file.set_string_list(id_card.display_name, "Rules-AlwaysConfirm", rules_always_conf);
            }
            key_file.set_string(id_card.display_name, "StorePassword", id_card.store_password ? "yes" : "no");
            
            // Trust anchor 
            key_file.set_string(id_card.display_name, "CA-Cert", id_card.trust_anchor.ca_cert ?? "");
            key_file.set_string(id_card.display_name, "Subject", id_card.trust_anchor.subject ?? "");
            key_file.set_string(id_card.display_name, "SubjectAlt", id_card.trust_anchor.subject_alt ?? "");
            key_file.set_string(id_card.display_name, "ServerCert", id_card.trust_anchor.server_cert ?? "");
        }

        var text = key_file.to_data(null);

        try {
            var path = get_data_dir();
            var filename = Path.build_filename(path, FILE_NAME);
            var file  = File.new_for_path(filename);
            var stream = file.replace(null, false, FileCreateFlags.PRIVATE);
            #if GIO_VAPI_USES_ARRAYS
            stream.write(text.data);
            #else
            var bits = text.data;
            stream.write(&bits[0], bits.length);
            #endif
                }
        catch (Error e) {
            stdout.printf("Error:  %s\n", e.message);
        }

        load_id_cards();
    }

    public LocalFlatFileStore() {
        id_card_list = new LinkedList<IdCard>();
        load_id_cards();
    }
}

