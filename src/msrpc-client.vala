using Rpc;
using MoonshotRpcInterface;

void main () {
    Rpc.client_bind (ref MoonshotRpcInterface.binding_handle, "/org/janet/Moonshot");

    string nai = null, password = null, certificate = null;
    bool result = false;

    Rpc.AsyncCall call = Rpc.AsyncCall();
    get_identity (call, "username@issuer", "pass", "service", ref nai, ref password, ref certificate);
    result = call.complete_bool ();

    if (result == false)
        error ("The nai, password or service does not match the selected identity\n");
    else
        stdout.printf ("%s %s %s\n", nai, password, certificate);

    Rpc.client_unbind (ref MoonshotRpcInterface.binding_handle);
}

