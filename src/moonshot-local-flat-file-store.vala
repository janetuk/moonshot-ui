
public class LocalFlatFileStore : Object, IIdentityCardStore {
     private SList<IdCard> id_card_list;

     public void add_card(IdCard card) {
     }

     public void update_card(IdCard card) {
     }

     public void remove_card(IdCard card) {
     }

     public SList<IdCard> get_card_list() {
          return id_card_list.copy(); 
     }
 }

