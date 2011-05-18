using Rpc;
using MoonshotRpcInterface;

void main () {
    Rpc.client_bind (ref MoonshotRpcInterface.binding_handle, "/org/janet/Moonshot");

    int pong = ping ("Hello from Vala");
    stdout.printf ("%d\n", pong);

    Identity *id = null;
    Rpc.AsyncCall call = Rpc.AsyncCall();
    get_identity (call, "identity", "username", "pass", &id);

    call.complete ();

    if (id == null)
        /* FIXME: this is happening when moonshot crashes instead
         * of returning a result - surely RpcAsyncCompleteCall should
         * *tell* us that the call failed !
         */
        error ("Call failed but error was not raised\n");
    else
        stdout.printf ("%s %s %s\n", id->identity, id->password, id->service);

    Rpc.client_unbind (ref MoonshotRpcInterface.binding_handle);
}

