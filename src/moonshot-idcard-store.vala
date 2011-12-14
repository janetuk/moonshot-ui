using Gee; 
public interface IIdentityCardStore : Object {
    // Methods
    public abstract void add_card(IdCard card);
    public abstract void remove_card(IdCard card);
    public abstract void update_card(IdCard card);
    public abstract LinkedList<IdCard> get_card_list(); 
}

