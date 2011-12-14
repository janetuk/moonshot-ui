using Gee;

class IdentityManagerModel : Object {
    private const string FILE_NAME = "identities.txt";

    private IIdentityCardStore store;
    public LinkedList<IdCard>  get_card_list() {
         return store.get_card_list(); 
    }
    public signal void card_list_changed();

    public void add_card(IdCard card) {
        store.add_card(card);
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

    private IdentityManagerApp parent;

    public IdentityManagerModel(IdentityManagerApp parent_app) {
        parent = parent_app;
        store = new LocalFlatFileStore();
    }
}
