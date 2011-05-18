/* Binding between the MIDL-generated C code for the RPC interface and Vala */

using Rpc;

[CCode (cheader_filename = "moonshot-msrpc-vala.h")]
namespace MoonshotRpcInterface {
    [CCode (cname = "moonshot_v1_0_s_ifspec")]
    public const InterfaceHandle spec;

    [CCode (cname = "moonshot_binding_handle")]
    public BindingHandle binding_handle;

    [CCode (cname = "MoonshotRpcInterfaceIdentity")]
    [Compact]
    public class Identity {
        public Identity() {}
        public string identity;
        public string password;
        public string service;
    }

    [CCode (cname = "moonshot_ping")]
    public extern int ping (string message);

    [CCode (cname = "moonshot_get_identity")]
    public extern void get_identity (Rpc.AsyncCall call,
                                     string in_identity,
                                     string in_password,
                                     string in_service,
                                     MoonshotRpcInterface.Identity **identity);
}
