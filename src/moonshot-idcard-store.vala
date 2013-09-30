using Gee; 
public interface IIdentityCardStore : Object {
    // Methods
    public enum StoreType {
        FLAT_FILE,
        KEYRING
    }

    public abstract void add_card(IdCard card);
    public abstract void remove_card(IdCard card);
    public abstract void update_card(IdCard card);
    public abstract StoreType get_store_type();
    public abstract LinkedList<IdCard> get_card_list(); 
}

