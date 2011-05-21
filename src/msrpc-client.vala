using Rpc;
using MoonshotRpcInterface;

void main () {
    Rpc.client_bind (ref MoonshotRpcInterface.binding_handle, "/org/janet/Moonshot");

    char *nai_out = null;
    char *password_out = null;
    char *certificate_out = null;
    bool result = false;

    Rpc.AsyncCall call = Rpc.AsyncCall();
    get_identity (call, "username@issuer", "pass", "service", &nai_out, &password_out, &certificate_out);
    result = call.complete_bool ();

    if (result == false)
        error ("The nai, password or service does not match the selected identity\n");
    else
        stdout.printf ("%s %s %s\n", (string)nai_out, (string)password_out, (string)certificate_out);

    delete nai_out;
    delete password_out;
    delete certificate_out;

    Rpc.client_unbind (ref MoonshotRpcInterface.binding_handle);
}

