/* Binding between the MIDL-generated C code for the RPC interface and Vala */

using Rpc;

[CCode (cheader_filename = "moonshot-msrpc.h")]
namespace MoonshotRpcInterface {
    [CCode (cname = "moonshot_v1_0_s_ifspec")]
    public const InterfaceHandle spec;

    [CCode (cname = "moonshot_binding_handle")]
    public BindingHandle binding_handle;

    [CCode (cname = "moonshot_get_identity")]
    public extern void get_identity (Rpc.AsyncCall call,
                                     string nai,
                                     string password,
                                     string service,
                                     ref string nai_out,
                                     ref string password_out,
                                     ref string certificate_out);

    [CCode (cname = "moonshot_get_default_identity")]
    public extern void get_default_identity (Rpc.AsyncCall call,
                                             ref string nai_out,
                                             ref string password_out);
}
