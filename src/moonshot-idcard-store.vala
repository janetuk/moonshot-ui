public interface IIdentityCardStore : Object {
    // Methods
    public abstract void add_card(IdCard card);
    public abstract void remove_card(IdCard card);
    public abstract void update_card(IdCard card);
    public abstract SList<IdCard> get_card_list(); 
    public signal void card_list_changed();
}

