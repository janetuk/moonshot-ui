using Rpc;
using MoonshotRpcInterface;

/* This class must be a singleton, because we use a global RPC
 * binding handle. I cannot picture a situation where more than
 * one instance of the same interface would be needed so this
 * shouldn't be a problem.
 *
 * Shutdown is automatically done by the RPC runtime when the
 * process ends
 */
public class MoonshotServer : Object {
    private static MainWindow main_window;

    private static MoonshotServer instance = null;

    public static void start (Gtk.Window window)
    {
        main_window = (MainWindow) window;
        Rpc.server_start (MoonshotRpcInterface.spec, "/org/janet/Moonshot", Rpc.Flags.PER_USER);
    }

    public static MoonshotServer get_instance ()
    {
        if (instance == null)
            instance = new MoonshotServer ();
        return instance;
    }

    [CCode (cname = "moonshot_get_identity")]
    public static void moonshot_get_identity (Rpc.AsyncCall call,
                                              string nai,
                                              string password,
                                              string service,
                                              ref string nai_out,
                                              ref string password_out,
                                              ref string certificate_out)
    {
        bool result = false;

        var request = new IdentityRequest (main_window,
                                           nai,
                                           password,
                                           service);

        // Pass execution to the main loop and block the RPC thread
        request.mutex = new Mutex ();
        request.cond = new Cond ();
        request.set_callback (return_identity_cb);

        request.mutex.lock ();
        Idle.add (request.execute);

        while (request.complete == false)
            request.cond.wait (request.mutex);

        nai_out = "";
        password_out = "";
        certificate_out = "";

        var id_card = request.id_card;
        bool has_service = false;

        if (id_card == null) {
            foreach (string id_card_service in id_card.services)
            {
                if (id_card_service == service)
                    has_service = true;
            }

            if (has_service)
            {
                // The strings are freed by the RPC runtime
                nai_out = id_card.nai;
                password_out = id_card.password;
                certificate_out = "certificate";

                result = true;
            }
        }

        // The outputs must be set before this function is called. For this
        // reason they are 'ref' not 'out' parameters - Vala assigns to the
        // 'out' parameters only at the end of the function, which is too
        // late.
        call.return (&result);

        request.cond.signal ();
        request.mutex.unlock ();
    }

    // Called from the main loop thread when an identity has
    // been selected
    static void return_identity_cb (IdentityRequest request) {
        // Notify the RPC thread that the request is complete
        request.mutex.lock ();
        request.cond.signal ();

        // Block the main loop until the RPC call has returned
        // to avoid any races
        request.cond.wait (request.mutex);
        request.mutex.unlock ();
    }
}
