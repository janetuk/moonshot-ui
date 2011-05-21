using Rpc;
using MoonshotRpcInterface;

/* Apologies in advance */
[CCode (cname = "g_strdup")]
public extern char *strdup (string str);

/* This class is the closure when we pass execution from the RPC thread
 * to the GLib main loop thread; we need to be executing inside the main
 * loop before we can access any state or make any Gtk+ calls.
 */
/* Fixme: can you make *this* an async callback? */
public class IdentityRequest : Object {
    private MainWindow main_window;
    private unowned Mutex mutex;
    private unowned Cond cond;

    internal IdCard? id_card = null;

    public IdentityRequest (Gtk.Window window,
                            Mutex _mutex,
                            Cond _cond)
    {
        main_window = (MainWindow)window;
        mutex = _mutex;
        cond = _cond;
    }

    public bool main_loop_cb ()
    {
        // Execution is passed from the RPC get_identity() call to
        // here, where we are inside the main loop thread.
        main_window.set_callback (this.id_card_selected_cb);
        return false;
    }

    public bool id_card_selected_cb ()
    {
        this.id_card = this.main_window.selected_id_card_widget.id_card;

        mutex.lock ();
        cond.signal ();

        // Block the mainloop until the ID card details have been read and
        // sent, to prevent races
        cond.wait (mutex);
        mutex.unlock ();

        return false;
    }
}

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
        Rpc.server_start (MoonshotRpcInterface.spec, "/org/janet/Moonshot");
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
                                              char **nai_out,
                                              char **password_out,
                                              char **certificate_out)
    {
        Mutex mutex = new Mutex ();
        Cond cond = new Cond ();
        bool result;

        mutex.lock ();

        IdentityRequest request = new IdentityRequest (main_window, mutex, cond);

        // Pass execution to the main loop thread and wait for
        // the 'send' action to be signalled.
        Idle.add (request.main_loop_cb);
        while (request.id_card == null)
            cond.wait (mutex);

        // Send back the results. Memory is freed by the RPC runtime.
        if (request.id_card.nai == nai || request.id_card.password == password)
        {
            *nai_out = strdup (request.id_card.nai);
            *password_out = strdup (request.id_card.password);
            *certificate_out = strdup ("certificate");
            result = true;
        }
        else
        {
            *nai_out = null;
            *password_out = null;
            *certificate_out = null;
            result = false;
        }

        call.return (&result);

        cond.signal ();
        mutex.unlock ();
    }
}
