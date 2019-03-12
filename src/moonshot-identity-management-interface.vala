
using Gee;
public errordomain IdentityManagerError {
    KEYRING_LOCKED
}

public interface IdentityManagerInterface : Object {
    public abstract bool add_identity(IdCard id_card, bool force_flat_file_store);
    public abstract void queue_identity_request(IdentityRequest request);
    public abstract void make_visible();
    public abstract IdCard check_add_password(IdCard identity, IdentityRequest request, IdentityManagerModel model);
    public abstract bool confirm_trust_anchor(IdCard card, TrustAnchorConfirmationRequest request);
    public abstract void generic_info_dialog(string title, string msg);

    /* Reports whether there are identities with ideantical NAI */
    internal void report_expired_trust_anchors(IdentityManagerModel model) {
        Gee.List<IdCard> card_list = model.get_card_list();
        foreach (IdCard id_card in card_list) {
            if (id_card.trust_anchor.is_expired()) {
                string message = _("Trust anchor for identity '%s' expired the %s.\n\n").printf(id_card.nai, id_card.trust_anchor.get_expiration_date())
                    + _("That means that any attempt to authenticate with that identity will fail. ")
                    + _("Please, ask your organisation to provide you with an updated credential.");
                generic_info_dialog("Expired Trust Anchor", message);
            }
        }
    }

    /* Reports whether there are identities with ideantical NAI */
    internal void report_duplicate_nais(IdentityManagerModel model) {
        Gee.List<Gee.List<IdCard>> duplicates;
        model.find_duplicate_nai_sets(out duplicates);
        foreach (Gee.List<IdCard> list in duplicates) {
            string message = _("The following identities use the same Network Access Identifier (NAI),\n'%s'.").printf(list.get(0).nai)
                + _("\n\nDuplicate NAIs are not allowed. Please remove identities you don't need, or modify")
                + _(" user ID or issuer fields so that they are no longer the same NAI.");

            foreach (var card in list) {
                message += _("\n\nDisplay Name: '%s'\nServices:\n     %s").printf(card.display_name, card.get_services_string(",\n     "));
            }
            generic_info_dialog("Duplicate NAIs", message);
        }
    }

}
