using Gee; 

public class LocalFlatFileStore : Object, IIdentityCardStore {
    private LinkedList<IdCard> id_card_list;
    private const string FILE_NAME = "identities.txt";

    public void add_card(IdCard card) {
        id_card_list.add(card);
        store_id_cards ();
    }

    public void update_card(IdCard card) {
        id_card_list.remove(card);
        id_card_list.add(card);
        store_id_cards ();
     }

     public void remove_card(IdCard card) {
        id_card_list.remove(card);
        store_id_cards ();
    }

     public LinkedList<IdCard> get_card_list() {
          return id_card_list; 
     }

     public IIdentityCardStore.StoreType get_store_type() {
          return IIdentityCardStore.StoreType.FLAT_FILE;
     }
     
     private void load_id_cards() {
        id_card_list.clear();
        var key_file = new KeyFile ();
        var path = get_data_dir ();
        var filename = Path.build_filename (path, FILE_NAME);
        
        try {
            key_file.load_from_file (filename, KeyFileFlags.NONE);
        }
        catch (Error e) {
            stdout.printf("Error: %s\n", e.message);
            return;
        }

        var identities_uris = key_file.get_groups ();
        foreach (string identity in identities_uris) {
            try {
                IdCard id_card = new IdCard ();

                id_card.issuer = key_file.get_string (identity, "Issuer");
                id_card.username = key_file.get_string (identity, "Username");
                id_card.password = key_file.get_string (identity, "Password");
                id_card.services = key_file.get_string_list (identity, "Services");
                id_card.display_name = key_file.get_string (identity, "DisplayName");
                id_card.set_data ("pixbuf", find_icon ("avatar-default", 48));
                
                
                if (key_file.has_key (identity, "Rules-Patterns") &&
                    key_file.has_key (identity, "Rules-AlwaysConfirm")) {
                    string [] rules_patterns =    key_file.get_string_list (identity, "Rules-Patterns");
                    string [] rules_always_conf = key_file.get_string_list (identity, "Rules-AlwaysConfirm");
                    
                    if (rules_patterns.length == rules_always_conf.length) {
                      Rule[] rules = new Rule[rules_patterns.length];
                      for (int i = 0; i < rules_patterns.length; i++) {
                        rules[i] = {rules_patterns[i], rules_always_conf[i]};
                      }
                      id_card.rules = rules;
                    }
                }
                
                // Trust anchor 
                id_card.trust_anchor.ca_cert = key_file.get_string (identity, "CA-Cert");
                id_card.trust_anchor.subject = key_file.get_string (identity, "Subject");
                id_card.trust_anchor.subject_alt = key_file.get_string (identity, "SubjectAlt");
                id_card.trust_anchor.server_cert = key_file.get_string (identity, "ServerCert");

                id_card_list.add (id_card);
            }
            catch (Error e) {
                stdout.printf ("Error:  %s\n", e.message);
            }
        }
     }

    private string get_data_dir() {
        string path;
        path = Path.build_filename (Environment.get_user_data_dir (),
                                    Config.PACKAGE_TARNAME);
                                    
        if (!FileUtils.test (path, FileTest.EXISTS)) {
            DirUtils.create_with_parents (path, 0700);
        }
        return path;
    }
    
    public void store_id_cards () {
        var key_file = new KeyFile ();
        foreach (IdCard id_card in this.id_card_list) {
            string[] rules_patterns = new string[id_card.rules.length];
            string[] rules_always_conf = new string[id_card.rules.length];
            
            for (int i=0; i<id_card.rules.length; i++) {
              rules_patterns[i] = id_card.rules[i].pattern;
              rules_always_conf[i] = id_card.rules[i].always_confirm;
            }

            key_file.set_string (id_card.display_name, "Issuer", id_card.issuer ?? "");
            key_file.set_string (id_card.display_name, "DisplayName", id_card.display_name ?? "");
            key_file.set_string (id_card.display_name, "Username", id_card.username ?? "");
            key_file.set_string (id_card.display_name, "Password", id_card.password ?? "");
            key_file.set_string_list (id_card.display_name, "Services", id_card.services ?? {});

            if (id_card.rules.length > 0) {
              key_file.set_string_list (id_card.display_name, "Rules-Patterns", rules_patterns);
              key_file.set_string_list (id_card.display_name, "Rules-AlwaysConfirm", rules_always_conf);
            }
            
            // Trust anchor 
            key_file.set_string (id_card.display_name, "CA-Cert", id_card.trust_anchor.ca_cert ?? "");
            key_file.set_string (id_card.display_name, "Subject", id_card.trust_anchor.subject ?? "");
            key_file.set_string (id_card.display_name, "SubjectAlt", id_card.trust_anchor.subject_alt ?? "");
            key_file.set_string (id_card.display_name, "ServerCert", id_card.trust_anchor.server_cert ?? "");
        }

        var text = key_file.to_data (null);

        try {
            var path = get_data_dir ();
            var filename = Path.build_filename (path, FILE_NAME);
            FileUtils.set_contents (filename, text, -1);
        } 
        catch (Error e) {
            stdout.printf ("Error:  %s\n", e.message);
        }

        load_id_cards();
    }

     public LocalFlatFileStore () {
        id_card_list = new LinkedList<IdCard>();
        load_id_cards();
     }
 }

