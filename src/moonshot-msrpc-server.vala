using Rpc;
using MoonshotRpcInterface;

/* This class is the closure when we pass execution from the RPC thread
 * to the GLib main loop thread; we need to be executing inside the main
 * loop before we can access any state or make any Gtk+ calls.
 */
public class IdentityRequest : Object {
    private Rpc.AsyncCall call;
    private MainWindow main_window;
    private char **p_identity;
    private char **p_password;
    private char **p_service;

    public IdentityRequest (Rpc.AsyncCall _call,
                            Gtk.Window window,
                            char **_p_identity,
                            char **_p_password,
                            char **_p_service)
    {
        call = _call;
        p_identity = _p_identity;
        p_password = _p_password;
        p_service = _p_service;
    }

    public bool main_loop_cb ()
    {
        main_window.set_callback (id_card_selected_cb);
        return false;
    }

    public bool id_card_selected_cb ()
    {
        var id_card = this.main_window.selected_id_card_widget.id_card;

        *p_identity = "identity";
        *p_password = id_card.password;
        *p_service = "certificate";
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
                                              char **out_identity,
                                              char **out_password,
                                              char **out_service)
    {
        IdentityRequest request = new IdentityRequest (call,
                                                       main_window,
                                                       out_identity,
                                                       out_password,
                                                       out_service);

        // Pass execution to the main loop thread
        Idle.add (request.main_loop_cb);
    }
}
