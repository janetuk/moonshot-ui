using Rpc;
using MoonshotRpcInterface;

/* This class is the closure when we pass execution from the RPC thread
 * to the GLib main loop thread; we need to be executing inside the main
 * loop before we can access any state or make any Gtk+ calls.
 */
public class IdentityRequest : Object {
    private Rpc.AsyncCall call;
    private MainWindow main_window;
    private Identity **result;

    public IdentityRequest (Rpc.AsyncCall _call,
                            Gtk.Window window,
                            Identity **_result)
    {
        call = _call;
        main_window = (MainWindow)window;
        result = _result;
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
        var id_card = this.main_window.selected_id_card_widget.id_card;

        *result = new Identity();

        (*result)->identity = "identity";
        (*result)->password = id_card.password;
        (*result)->service = "certificate";

        call.return (null);

        //delete result;

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
    private static int counter;
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

    /* Note that these RPC callbacks execute outside the GLib main loop,
     * in threads owned by the RPC runtime
     */

    [CCode (cname = "moonshot_ping")]
    public static int ping (string msg)
    {
        stdout.printf ("%s\n", msg);
        return counter ++;
    }

    [CCode (cname = "moonshot_get_identity")]
    public static void moonshot_get_identity (Rpc.AsyncCall call,
                                              string in_identity,
                                              string in_password,
                                              string in_service,
                                              Identity **result)
    {
        IdentityRequest request = new IdentityRequest (call, main_window, result);

        // Pass execution to the main loop thread
        Idle.add (request.main_loop_cb);
    }
}
