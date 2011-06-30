#if IPC_DBUS

[DBus (name = "org.janet.Moonshot")]
public class MoonshotServer : Object {

    private MainWindow main_window;

    public MoonshotServer (Gtk.Window window)
    {
        this.main_window = (MainWindow) window;
    }

    /**
     * This is the function used by the GSS mechanism to get the NAI,
     * password and certificate of the ID card for the specificated service.
     *
     * The function will block until the user choose the ID card.
     *
     * @param nai NAI of the ID Card (optional)
     * @param password Password of the ID Card (optional)
     * @param service Service application request an ID Card for
     * @param nai_out NAI stored in the ID Card
     * @param password_out Password stored in the ID Card
     * @param certificate Certificate stored in th ID Card
     *
     * @return true if the user choose a correct ID card for that service,
     *         false otherwise.
     */
    public async bool get_identity (string nai,
                                    string password,
                                    string service,
                                    out string nai_out,
                                    out string password_out,
                                    out string certificate_out)
    {
        bool has_service = false;

        var request = new IdentityRequest (main_window,
                                           nai,
                                           password,
                                           service);
        request.set_callback ((IdentityRequest) => get_identity.callback());
        request.execute ();
        yield;

        nai_out = "";
        password_out = "";
        certificate_out = "";

        var id_card = request.id_card;

        if (id_card != null) {
            foreach (string id_card_service in id_card.services)
            {
                if (id_card_service == service)
                    has_service = true;
            }

            if (has_service)
            {
                nai_out = id_card.nai;
                password_out = id_card.password;
                certificate_out = "certificate";

                // User should have been prompted if there was no p/w.
                return_if_fail (nai_out != null);
                return_if_fail (password_out != null);

                return true;
            }
        }

        return false;
    }

    /**
     * Returns the default identity - most recently used.
     *
     * @param nai_out NAI stored in the ID card
     * @param password_out Password stored in the ID card
     *
     * @return true on success, false if no identities are stored
     */
    public async bool get_default_identity (out string nai_out,
                                            out string password_out)
    {
        var request = new IdentityRequest.default (main_window);
        request.set_callback ((IdentityRequest) => get_default_identity.callback());
        request.execute ();
        yield;

        nai_out = "";
        password_out = "";

        if (request.id_card != null)
        {
            nai_out = request.id_card.nai;
            password_out = request.id_card.password;

            // User should have been prompted if there was no p/w.
            return_val_if_fail (nai_out != null, false);
            return_val_if_fail (password_out != null, false);

            return true;
        }

        return false;
    }
}

#elif IPC_MSRPC

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
    public static void get_identity (Rpc.AsyncCall call,
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

                return_if_fail (nai_out != null);
                return_if_fail (password_out != null);

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

    [CCode (cname = "moonshot_get_default_identity")]
    public static void get_default_identity (Rpc.AsyncCall call,
                                             ref string nai_out,
                                             ref string password_out)
    {
        bool result;

        var request = new IdentityRequest.default (main_window);
        request.mutex = new Mutex ();
        request.cond = new Cond ();
        request.set_callback (return_identity_cb);

        request.mutex.lock ();
        Idle.add (request.execute);

        while (request.complete == false)
            request.cond.wait (request.mutex);

        nai_out = "";
        password_out = "";

        if (request.id_card != null)
        {
            nai_out = request.id_card.nai;
            password_out = request.id_card.password;

            return_if_fail (nai_out != null);
            return_if_fail (password_out != null);

            result = true;
        }
        else
        {
            result = false;
        }

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

#endif
