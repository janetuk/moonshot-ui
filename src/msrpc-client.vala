using Rpc;
using MoonshotRpcInterface;

void main () {
    Rpc.client_bind (ref MoonshotRpcInterface.binding_handle,
                     "/org/janet/Moonshot",
                     Rpc.Flags.PER_USER);

    string nai = null, password = null, certificate = null;
    string a = null, b = null, c = null;
    bool result = false;

    /* Get default identity */
    Rpc.AsyncCall call = Rpc.AsyncCall();
    get_default_identity (call, ref nai, ref password);
    result = call.complete_bool ();

    if (result == false)
        error ("Unable to get default identity");
    else
        stdout.printf ("default: %s %s\n", nai, password);

    /* Prompt for identity */
    call = Rpc.AsyncCall();
    get_identity (call,
                  "username@issuer",
                  "pass",
                  "service",
                  ref nai,
                  ref password,
                  ref certificate,
                  ref a,
                  ref b,
                  ref c);
    result = call.complete_bool ();

    if (result == false)
        error ("The nai, password or service does not match the selected identity\n");
    else
        stdout.printf ("%s %s %s\n", nai, password, certificate);

    Rpc.client_unbind (ref MoonshotRpcInterface.binding_handle);
}
