using Gee;

public class IdentityManagerModel : Object {
    private const string FILE_NAME = "identities.txt";

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
         return identities;
    }
    public signal void card_list_changed();

    /* This method finds a valid display name */
    public bool display_name_is_valid (string name,
                                       out string? candidate)
    {
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
        string candidate;
        IIdentityCardStore.StoreType saved_store_type = get_store_type();

        if (force_flat_file_store)
            set_store_type(IIdentityCardStore.StoreType.FLAT_FILE);

        if (!display_name_is_valid (card.display_name, out candidate))
        {
          card.display_name = candidate;
        }

        store.add_card(card);
        set_store_type(saved_store_type);
        card_list_changed();
     }

     public void update_card(IdCard card) {
        store.update_card(card);
        card_list_changed();
     }

     public void remove_card(IdCard card) {
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
         var identities = store.get_card_list();
         return !identities.is_empty;
     }


    private IdentityManagerApp parent;

    public IdentityManagerModel(IdentityManagerApp parent_app, IIdentityCardStore.StoreType store_type) {
        parent = parent_app;
        set_store_type(store_type);
    }
}
