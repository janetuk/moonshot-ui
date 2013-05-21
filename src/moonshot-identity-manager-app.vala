using Gee;
using Gtk;

#if IPC_DBUS
[DBus (name = "org.janet.Moonshot")]
interface IIdentityManager : GLib.Object {
#if IPC_DBUS_GLIB
    public abstract bool show_ui() throws DBus.Error;
#else
    public abstract bool show_ui() throws IOError;
#endif
}
#endif

public class IdentityManagerApp {
    public IdentityManagerModel model;
    public IdCard default_id_card;
    public bool explicitly_launched;
    public IdentityManagerView view;
    private MoonshotServer ipc_server;

#if OS_MACOS
	public OSXApplication osxApp;
  
    // the signal handler function.
    // the current instance of our app class is passed in the 
    // id_manager_app_instanceparameter 
	public static bool on_osx_open_files (OSXApplication osx_app_instance, 
                                        string file_name, 
                                        IdentityManagerApp id_manager_app_instance ) {
    int added_cards = id_manager_app_instance.ipc_server.install_from_file(file_name);
    return true;
	}
#endif

    private const int WINDOW_WIDTH = 400;
    private const int WINDOW_HEIGHT = 500;
    public void show() {
        if (view != null) view.show();    
    }
	
    public IdentityManagerApp (bool headless) {
        model = new IdentityManagerModel(this);
        if (!headless)
            view = new IdentityManagerView(this);
        LinkedList<IdCard> card_list = model.get_card_list() ;
        if (card_list.size > 0)
            this.default_id_card = card_list.first();

        init_ipc_server ();

#if OS_MACOS

        osxApp = OSXApplication.get_instance();
        // The 'correct' way of connrcting wont work in Mac OS with Vala 0.12	e.g.	
        // 		osxApp.ns_application_open_file.connect(install_from_file);
        // so we have to use this old way
        Signal.connect(osxApp, "NSApplicationOpenFile", (GLib.Callback)(on_osx_open_files), this);

#endif
    }

    public bool add_identity (IdCard id) {
        if (view != null) return view.add_identity(id);
        model.add_card(id);
        return true;
    }

    public void select_identity (IdentityRequest request) {
        IdCard identity = null;

        if (request.select_default)
        {
            identity = default_id_card;
        }

        if (identity == null)
        {
            bool has_nai = request.nai != null && request.nai != "";
            bool has_srv = request.service != null && request.service != "";
            bool confirm = false;
            IdCard nai_provided = null;

            foreach (IdCard id in model.get_card_list())
            {
                /* If NAI matches we add id card to the candidate list */
                if (has_nai && request.nai == id.nai)
                {
                    nai_provided = id;
                    request.candidates.append (id);
                    continue;
                }

                /* If any service matches we add id card to the candidate list */
                if (has_srv)
                {
                    foreach (string srv in id.services)
                    {
                        if (request.service == srv)
                        {
                            request.candidates.append (id);
                            continue;
                        }
                    }
                }
            }

            /* If more than one candidate we dissasociate service from all ids */
            if (has_srv && request.candidates.length() > 1)
            {
                foreach (IdCard id in request.candidates)
                {
                    int i = 0;
                    SList<string> services_list = null;
                    bool has_service = false;

                    foreach (string srv in id.services)
                    {
                        if (srv == request.service)
                        {
                            has_service = true;
                            continue;
                        }
                        services_list.append (srv);
                    }
                    
                    if (!has_service)
                        continue;

                    if (services_list.length () == 0)
                    {
                        id.services = {};
                        continue;
                    }

                    string[] services = new string[services_list.length ()];
                    foreach (string srv in services_list)
                    {
                        services[i] = srv;
                        i++;
                    }

                    id.services = services;
                }
            }

//            model.store_id_cards ();

            /* If there are no candidates we use the service matching rules */
            if (request.candidates.length () == 0)
            {
                foreach (IdCard id in model.get_card_list())
                {
                    foreach (Rule rule in id.rules)
                    {
                        if (!match_service_pattern (request.service, rule.pattern))
                            continue;

                        request.candidates.append (id);

                        if (rule.always_confirm == "true")
                            confirm = true;
                    }
                }
            }
            
            if (request.candidates.length () > 1)
            {
                if (has_nai && nai_provided != null)
                {
                    identity = nai_provided;
                    confirm = false;
                }
                else
                    confirm = true;
            }
            if (identity == null)
                identity = request.candidates.nth_data (0);
            if (identity == null)
                confirm = true;

            /* TODO: If candidate list empty return fail */
            
            if (confirm && (view != null))
            {
                if (!explicitly_launched)
                    show();
		view.queue_identity_request(request);
                return;
            }
        }
        // Send back the identity (we can't directly run the
        // callback because we may be being called from a 'yield')
        Idle.add(
            () => {
                request.return_identity (identity);
// The following occasionally causes the app to exit without sending the dbus
// reply, so for now we just don't exit
//                if (!explicitly_launched)
//                    Idle.add( () => { Gtk.main_quit(); return false; } );
                return false;
            }
        );
        return;
    }

    private bool match_service_pattern (string service, string pattern)
    {
        var pspec = new PatternSpec (pattern);
        return pspec.match_string (service);
    }   
    
#if IPC_MSRPC
    private void init_ipc_server ()
    {
        // Errors will currently be sent via g_log - ie. to an
        // obtrusive message box, on Windows
        //
        this.ipc_server = MoonshotServer.get_instance ();
        MoonshotServer.start (this);
    }
#elif IPC_DBUS_GLIB
    private void init_ipc_server ()
    {
        try {
            var conn = DBus.Bus.get (DBus.BusType.SESSION);
            dynamic DBus.Object bus = conn.get_object ("org.freedesktop.DBus",
                                                       "/org/freedesktop/DBus",
                                                       "org.freedesktop.DBus");

            // try to register service in session bus
            uint reply = bus.request_name ("org.janet.Moonshot", (uint) 0);
            if (reply == DBus.RequestNameReply.PRIMARY_OWNER)
            {
                this.ipc_server = new MoonshotServer (this);
                conn.register_object ("/org/janet/moonshot", ipc_server);
            } else {
                bool shown=false;
                GLib.Error e;
                DBus.Object manager_proxy = conn.get_object ("org.janet.Moonshot",
                                                             "/org/janet/moonshot",
                                                             "org.janet.Moonshot");
                if (manager_proxy != null)
                    manager_proxy.call("show_ui", out e, GLib.Type.INVALID, typeof(shown), out shown, GLib.Type.INVALID);

                if (!shown) {
                    GLib.error ("Couldn't own name org.janet.Moonshot on dbus or show previously launched identity manager.");
                } else {
                    stdout.printf("Showed previously launched identity manager.\n");
                    GLib.Process.exit(0);
                }
            }
        }
        catch (DBus.Error e)
        {
            stderr.printf ("%s\n", e.message);
        }
    }
#else
    private void bus_acquired_cb (DBusConnection conn)
    {
        try {
            conn.register_object ("/org/janet/moonshot", ipc_server);
        }
        catch (Error e)
        {
            stderr.printf ("%s\n", e.message);
        }
    }

    private void init_ipc_server ()
    {
        this.ipc_server = new MoonshotServer (this);
        GLib.Bus.own_name (GLib.BusType.SESSION,
                           "org.janet.Moonshot",
                           GLib.BusNameOwnerFlags.NONE,
                           bus_acquired_cb,
                           (conn, name) => {},
                           (conn, name) => {
                               bool shown=false;
                               try {
                                   IIdentityManager manager = Bus.get_proxy_sync (BusType.SESSION, name, "/org/janet/moonshot");
                                   shown = manager.show_ui();
                               } catch (IOError e) {
                               }
                               if (!shown) {
                                   GLib.error ("Couldn't own name %s on dbus or show previously launched identity manager.", name);
                               } else {
                                   stdout.printf("Showed previously launched identity manager.\n");
                                   GLib.Process.exit(0);
                               }
                           });
    }
#endif
}

static bool explicitly_launched = true;
const GLib.OptionEntry[] options = {
    {"DBusLaunch",0,GLib.OptionFlags.REVERSE,GLib.OptionArg.NONE,
     ref explicitly_launched,"launch for dbus rpc use",null},
    {null}
};


public static int main(string[] args){
#if IPC_MSRPC
	bool headless = false;
#else
        bool headless = GLib.Environment.get_variable("DISPLAY") == null;
#endif

        if (headless) {
            explicitly_launched = false;
        } else {
            try {
                Gtk.init_with_args(ref args, _(""), options, null);
            } catch (GLib.Error e) {
                stdout.printf(_("error: %s\n"),e.message);
                stdout.printf(_("Run '%s --help' to see a full list of available options"), args[0]);
            }
        }

#if OS_WIN32
        // Force specific theme settings on Windows without requiring a gtkrc file
        Gtk.Settings settings = Gtk.Settings.get_default ();
        settings.set_string_property ("gtk-theme-name", "ms-windows", "moonshot");
        settings.set_long_property ("gtk-menu-images", 0, "moonshot");
#endif

        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);
       
	   
        var app = new IdentityManagerApp(headless);
        app.explicitly_launched = explicitly_launched;
        
	if (app.explicitly_launched) {
            app.show();
        }

        if (headless) {
#if !IPC_MSRPC
            MainLoop loop = new MainLoop();
            loop.run();
#endif
        } else {
            Gtk.main();
        }

        return 0;
    }

