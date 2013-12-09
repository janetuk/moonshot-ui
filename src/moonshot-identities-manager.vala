using Gee;

public class Password {
#if GNOME_KEYRING
    private unowned string _password;
    public string password {
        get {
            return _password;
        }
        set {
            if (_password != null) {
                GnomeKeyring.memory_free((void *)_password);
                _password = null;
            }
            if (value != null)
                _password = GnomeKeyring.memory_strdup(value); 
        }
    }
#else
    public string password { get; set; default = null; }
#endif

    public Password(string in_password) {
        password = in_password;
    }

    ~Password() {
        password = null;
    }
}

public class PasswordHashTable : Object {
    private HashTable<string, Password> password_table;

    private static string ComputeHashKey(IdCard card, IIdentityCardStore store) {
        return "%s_store_%d".printf( card.display_name, store.get_store_type() );
    }

    public void CachePassword(IdCard card, IIdentityCardStore store) {
        password_table.replace(ComputeHashKey(card, store), new Password(card.password));
    }

    public void RemovePassword(IdCard card, IIdentityCardStore store) {
        password_table.remove(ComputeHashKey(card, store));
    }
    public void RetrievePassword(IdCard card, IIdentityCardStore store) {
        weak Password password = password_table.lookup(ComputeHashKey(card, store));
        if (password != null) {
            card.password = password.password;
        }
    }
    public PasswordHashTable() {
        password_table = new HashTable<string, Password>(GLib.str_hash, GLib.str_equal);
    }
}

public class IdentityManagerModel : Object {
    private const string FILE_NAME = "identities.txt";
    private PasswordHashTable password_table;
    private IIdentityCardStore store;
    public LinkedList<IdCard>  get_card_list() {
         var identities = store.get_card_list();
         identities.sort( (a, b) => {
             IdCard id_a = (IdCard )a;
             IdCard id_b = (IdCard )b;
             if (id_a.IsNoIdentity() && !id_b.IsNoIdentity()) {
                return -1;
             } else if (id_b.IsNoIdentity() && !id_a.IsNoIdentity()) {
                return 1;
             }
             return strcmp(id_a.display_name, id_b.display_name);
         });
         if (identities.is_empty || !identities[0].IsNoIdentity())
             identities.insert(0, IdCard.NewNoIdentity());
         foreach (IdCard id_card in identities) {
             if (!id_card.store_password) {
                 password_table.RetrievePassword(id_card, store);
             }
         }
         return identities;
    }
    public signal void card_list_changed();

    /* This method finds a valid display name */
    public bool display_name_is_valid (string name,
                                       out string? candidate)
    {
        if (&candidate != null)
          candidate = null;
        foreach (IdCard id_card in this.get_card_list())
        {
          if (id_card.display_name == name)
          {
            if (&candidate != null)
            {
              for (int i=0; i<1000; i++)
              {
                string tmp = "%s %d".printf (name, i);
                if (display_name_is_valid (tmp, null))
                {
                  candidate = tmp;
                  break;
                }
              }
            }
            return false;
          }
        }
        return true;
    }

    public void add_card(IdCard card, bool force_flat_file_store) {
        if (card.temporary)
            return;

        string candidate;
        IIdentityCardStore.StoreType saved_store_type = get_store_type();

        if (force_flat_file_store)
            set_store_type(IIdentityCardStore.StoreType.FLAT_FILE);

        if (!display_name_is_valid (card.display_name, out candidate))
        {
          card.display_name = candidate;
        }

        if (!card.store_password)
            password_table.CachePassword(card, store);
        store.add_card(card);
        set_store_type(saved_store_type);
        card_list_changed();
     }

     public IdCard update_card(IdCard card) {
        IdCard retval;
        if (card.temporary) {
            retval = card;
            return retval;
        }
            
        if (!card.store_password)
            password_table.CachePassword(card, store);
        else
            password_table.RemovePassword(card, store);
        retval = store.update_card(card);
        card_list_changed();
        return retval;
     }

     public void remove_card(IdCard card) {
        password_table.RemovePassword(card, store);
        store.remove_card(card);
        card_list_changed();
     }

     public void set_store_type(IIdentityCardStore.StoreType type) {
         if ((store != null) && (store.get_store_type() == type))
             return;
         switch (type) {
#if GNOME_KEYRING
             case IIdentityCardStore.StoreType.KEYRING:
                 store = new KeyringStore();
                 break;
#endif
             case IIdentityCardStore.StoreType.FLAT_FILE:
             default:
                 store = new LocalFlatFileStore();
                 break;
         }
     }

     public IIdentityCardStore.StoreType get_store_type() {
         return store.get_store_type();
     }

     public bool HasNonTrivialIdentities() {
         foreach (IdCard card in this.store.get_card_list()) {
             // The 'NoIdentity' card is non-trivial if it has services or rules.
             // All other cards are automatically non-trivial.
             if ((!card.IsNoIdentity()) || 
                 (card.services.length > 0) ||
                 (card.rules.length > 0)) {
                 return true;
             }
         }
         return false;
     }


    private IdentityManagerApp parent;

    public IdentityManagerModel(IdentityManagerApp parent_app, IIdentityCardStore.StoreType store_type) {
        parent = parent_app;
        password_table = new PasswordHashTable();
        set_store_type(store_type);
    }
}
