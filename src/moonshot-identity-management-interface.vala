
using Gee;
public interface IdentityManagerInterface : Object {
    public abstract bool add_identity(IdCard id_card, bool force_flat_file_store, out ArrayList<IdCard>? old_duplicates=null);
    public abstract void queue_identity_request(IdentityRequest request);
    public abstract void make_visible();
    public abstract IdCard check_add_password(IdCard identity, IdentityRequest request, IdentityManagerModel model);
    public abstract bool confirm_trust_anchor(IdCard card, string userid, string realm, string fingerprint);
}
