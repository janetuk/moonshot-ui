/* Binding between the MIDL-generated C code for the RPC interface and Vala */

using Rpc;

[CCode (cheader_filename = "moonshot-msrpc.h")]
namespace MoonshotRpcInterface {
    [CCode (cname = "moonshot_v1_0_s_ifspec")]
    public const InterfaceHandle spec;

    [CCode (cname = "moonshot_binding_handle")]
    public BindingHandle binding_handle;

    [CCode (cname = "MoonshotServiceRule_RPC")]
    public struct Rule_RPC {
        string pattern;
        string always_confirm;
    }

    [CCode (cname = "moonshot_get_identity_rpc")]
    public extern void get_identity (Rpc.AsyncCall call,
                                     string nai,
                                     string password,
                                     string service,
                                     ref string nai_out,
                                     ref string password_out,
                                     ref string server_certificate_hash,
                                     ref string ca_certificate,
                                     ref string subject_name_constraint,
                                     ref string subject_alt_name_constraint);

    [CCode (cname = "moonshot_get_default_identity_rpc")]
    public extern void get_default_identity (Rpc.AsyncCall call,
                                             ref string nai_out,
                                             ref string password_out);
}
