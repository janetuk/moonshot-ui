/* Binding between the MIDL-generated C code for the RPC interface and Vala */

using Rpc;

[CCode (cheader_filename = "moonshot-msrpc.h")]

namespace MoonshotRpcInterface {
    [CCode (cname = "moonshot_v1_0_s_ifspec")]
    public const InterfaceHandle spec;

    [CCode (cname = "moonshot_binding_handle")]
    public BindingHandle binding_handle;

    [CCode (cname = "moonshot_ping")]
    public int ping (string message);

    [CCode (cname = "moonshot_get_message")]
    public void moonshot_get_identity (string in_identity,
                                       string in_password,
                                       string in_service,
                                       char **out_identity,
                                       char **out_password,
                                       char **out_service);
}
