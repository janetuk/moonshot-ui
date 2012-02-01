using Gtk;


class IdentityManagerApp {
    public IdentityManagerModel model;
    private IdentityManagerView view;
    private MoonshotServer ipc_server;
#if OS_MACOS
	public OSXApplication osxApp;
	public bool on_osx_open_files (string file_name ) {
	print ("on_osx_open_files()  file_name = %s\n", file_name);
		return ipc_server.install_from_file(file_name);
	}
#endif
    private const int WINDOW_WIDTH = 400;
    private const int WINDOW_HEIGHT = 500;
    public void show() {
        view.show();    
    }
	
    public IdentityManagerApp () {
        model = new IdentityManagerModel(this);
        view = new IdentityManagerView(this);
        init_ipc_server ();
#if OS_MACOS
 		osxApp = OSXApplication.get_instance();
// This wont work with Vala 0.12		
// 		osxApp.ns_application_open_file.connect(ipc_server.install_from_file);
// so we have to use this old way
		Signal.connect(osxApp, "NSApplicationOpenFile", (GLib.Callback)(on_osx_open_files), ipc_server);
//		Signal.connect_data(osxApp, "NSApplicationOpenFile", (GLib.Callback)(ipc_server.install_from_file), ipc_server, null, 0);

#endif
        view.show();
    }   
    
#if IPC_MSRPC
    private void init_ipc_server ()
    {
        // Errors will currently be sent via g_log - ie. to an
        // obtrusive message box, on Windows
        //
        this.ipc_server = MoonshotServer.get_instance ();
        MoonshotServer.start (this.view);
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
            assert (reply == DBus.RequestNameReply.PRIMARY_OWNER);

            this.ipc_server = new MoonshotServer (this.view);
            conn.register_object ("/org/janet/moonshot", ipc_server);
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
        this.ipc_server = new MoonshotServer (this.view);
        GLib.Bus.own_name (GLib.BusType.SESSION,
                           "org.janet.Moonshot",
                           GLib.BusNameOwnerFlags.NONE,
                           bus_acquired_cb,
                           (conn, name) => {},
                           (conn, name) => {
                               error ("Couldn't own name %s on DBus.", name);
                           });
    }
#endif
}


public static int main(string[] args){
        Gtk.init(ref args);
		stdout.printf("Hello\n");
        foreach (string arg in args)
			stdout.printf("arg %s\n", arg);

#if OS_WIN32
        // Force specific theme settings on Windows without requiring a gtkrc file
        Gtk.Settings settings = Gtk.Settings.get_default ();
        settings.set_string_property ("gtk-theme-name", "ms-windows", "moonshot");
        settings.set_long_property ("gtk-menu-images", 0, "moonshot");
#endif

        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);
       
	   
        var app = new IdentityManagerApp();
        
        app.show();

        Gtk.main();

        return 0;
    }

