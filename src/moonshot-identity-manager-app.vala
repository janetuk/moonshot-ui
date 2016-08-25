/*
 * Copyright (c) 2011-2016, JANET(UK)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of JANET(UK) nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
*/
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
    public static MoonshotLogger logger = get_logger("IdentityManagerApp");

    public IdentityManagerModel model;
    public IdCard default_id_card;
    public bool explicitly_launched;
    public IdentityManagerView view;
    private MoonshotServer ipc_server;
    private bool name_is_owned;
    private bool show_requested;

#if OS_MACOS
    public OSXApplication osxApp;
  
    // the signal handler function.
    // the current instance of our app class is passed in the 
    // id_manager_app_instanceparameter 
    public static bool on_osx_open_files(OSXApplication osx_app_instance, 
                                         string file_name, 
                                         IdentityManagerApp id_manager_app_instance ) {
        int added_cards = id_manager_app_instance.ipc_server.install_from_file(file_name);
        return true;
    }
#endif

    /** If we're successfully registered with DBus, then show the UI. Otherwise, wait until we're registered. */
    public void show() {
        if (name_is_owned) {
            if (view != null) {
                view.make_visible();
            }
        }
        else {
            show_requested = true;
        }
    }
    
#if LOG4VALA
    // Call this from main() to ensure that the logger is initialized
    internal IdentityManagerApp.dummy() {}
#endif

    public IdentityManagerApp(bool headless, bool use_flat_file_store) {
        use_flat_file_store |= UserForcesFlatFileStore();

#if GNOME_KEYRING
        bool keyring_available = (!use_flat_file_store) && GnomeKeyring.is_available();
#else
        bool keyring_available = false;
#endif

        IIdentityCardStore.StoreType store_type;
        if (headless || use_flat_file_store || !keyring_available)
            store_type = IIdentityCardStore.StoreType.FLAT_FILE;
        else
            store_type = IIdentityCardStore.StoreType.KEYRING;

        model = new IdentityManagerModel(this, store_type);
        /* if headless, but we have nothing in the flat file store
         * and keyring is available, switch to keyring */
        if (headless && keyring_available && !use_flat_file_store && !model.HasNonTrivialIdentities())
            model.set_store_type(IIdentityCardStore.StoreType.KEYRING);

        if (!headless)
            view = new IdentityManagerView(this, use_flat_file_store);
        LinkedList<IdCard> card_list = model.get_card_list();
        if (card_list.size > 0)
            this.default_id_card = card_list.last();

        init_ipc_server();

#if OS_MACOS
        osxApp = OSXApplication.get_instance();
        // The 'correct' way of connecting won't work in Mac OS with Vala 0.12; e.g.
        //     osxApp.ns_application_open_file.connect(install_from_file);
        // so we have to use this old way
        Signal.connect(osxApp, "NSApplicationOpenFile", (GLib.Callback)(on_osx_open_files), this);
#endif
    }

    public bool add_identity(IdCard id, bool force_flat_file_store, out ArrayList<IdCard>? old_duplicates=null) {
        if (view != null) 
        {
            logger.trace("add_identity: calling view.add_identity");
            return view.add_identity(id, force_flat_file_store, out old_duplicates);
        }
        else {
            logger.trace("add_identity: calling model.add_card");
            model.add_card(id, force_flat_file_store, out old_duplicates);
            return true;
        }
    }

    public void select_identity(IdentityRequest request) {
        logger.trace("select_identity: request.nai=%s".printf(request.nai ?? "[null]"));

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

            foreach (IdCard id in model.get_card_list())
            {
                /* If NAI matches, use this id card */
                if (has_nai && request.nai == id.nai)
                {
                    logger.trace("select_identity: request has nai; returning " + id.display_name);
                    identity = id;
                    break;
                }

                /* If any service matches we add id card to the candidate list */
                if (has_srv)
                {
                    if (id.services.contains(request.service)) {
                        logger.trace(@"select_identity: request has service '$(request.service); matched on '$(id.display_name)'");
                        request.candidates.append(id);
                    }
                }
            }

            /* If more than one candidate we dissasociate service from all ids */
            if ((identity == null) && has_srv && request.candidates.length() > 1)
            {
                logger.trace(@"select_identity: multiple candidates; removing service '$(request.service) from all.");
                foreach (IdCard id in request.candidates)
                {
                    id.services.remove(request.service);
                }
            }

            /* If there are no candidates we use the service matching rules */
            if ((identity == null) && (request.candidates.length() == 0))
            {
                logger.trace("select_identity: No candidates; using service matching rules.");
                foreach (IdCard id in model.get_card_list())
                {
                    foreach (Rule rule in id.rules)
                    {
                        if (!match_service_pattern(request.service, rule.pattern))
                            continue;

                        logger.trace(@"select_identity: ID $(id.display_name) matched on service matching rules.");
                        request.candidates.append(id);

                        if (rule.always_confirm == "true")
                            confirm = true;
                    }
                }
            }
            
            if ((identity == null) && has_nai) {
                logger.trace("select_identity: Creating temp identity");
                // create a temp identity
                string[] components = request.nai.split("@", 2);
                identity = new IdCard();
                identity.display_name = request.nai;
                identity.username = components[0];
                if (components.length > 1)
                    identity.issuer = components[1];
                identity.password = request.password;
                identity.temporary = true;
            }
            if (identity == null) {
                if (request.candidates.length() != 1) {
                    logger.trace("select_identity: Have %u candidates; user must make selection.".printf(request.candidates.length()));
                    confirm = true;
                } else {
                    identity = request.candidates.nth_data(0);                    
                }
            }

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
        GLib.Idle.add(
            () => {
                if (view != null) {
                    logger.trace("select_identity (Idle handler): calling check_add_password");
                    identity = view.check_add_password(identity, request, model);
                }
                request.return_identity(identity);
// The following occasionally causes the app to exit without sending the dbus
// reply, so for now we just don't exit
//                if (!explicitly_launched)
//                    Idle.add(() => { Gtk.main_quit(); return false; } );
                return false;
            }
            );
        return;
    }

    private bool match_service_pattern(string service, string pattern) {
        var pspec = new PatternSpec(pattern);
        return pspec.match_string(service);
    }   
    
#if IPC_MSRPC
    private void init_ipc_server() {
        // Errors will currently be sent via g_log - ie. to an
        // obtrusive message box, on Windows
        //
        this.ipc_server = MoonshotServer.get_instance();
        MoonshotServer.start(this);
    }
#elif IPC_DBUS_GLIB
    private void init_ipc_server() {
        try {
            var conn = DBus.Bus.get(DBus.BusType.SESSION);
            dynamic DBus.Object bus = conn.get_object("org.freedesktop.DBus",
                                                      "/org/freedesktop/DBus",
                                                      "org.freedesktop.DBus");

            // try to register service in session bus
            uint reply = bus.request_name("org.janet.Moonshot", (uint) 0);
            if (reply == DBus.RequestNameReply.PRIMARY_OWNER)
            {
                this.ipc_server = new MoonshotServer(this);
                logger.trace("init_ipc_server(IPC_DBUS_GLIB) : Constructed new MoonshotServer");
                conn.register_object("/org/janet/moonshot", ipc_server);
            } else {
                logger.trace("init_ipc_server: reply != PRIMARY_OWNER");
                bool shown = false;
                GLib.Error e;
                DBus.Object manager_proxy = conn.get_object("org.janet.Moonshot",
                                                            "/org/janet/moonshot",
                                                            "org.janet.Moonshot");
                if (manager_proxy != null)
                    manager_proxy.call("ShowUi", out e, GLib.Type.INVALID, typeof(bool), out shown, GLib.Type.INVALID);

                if (!shown) {
                    GLib.error("Couldn't own name org.janet.Moonshot on dbus or show previously launched identity manager.");
                } else {
                    stdout.printf(_("Showed previously launched identity manager.\n"));
                    GLib.Process.exit(0);
                }
            }
        }
        catch (DBus.Error e)
        {
            logger.trace("bus_acquired_cb");
            try {
                conn.register_object ("/org/janet/moonshot", ipc_server);
            }
            catch (Error e)
            {
                stderr.printf ("%s\n", e.message);
                logger.error("bus_acquired_cb: Caught error: " + e.message);
            }
        }
    }
#else
    private void bus_acquired_cb(DBusConnection conn) {
        logger.trace("bus_acquired_cb");
        try {
            conn.register_object("/org/janet/moonshot", ipc_server);
        }
        catch (Error e)
        {
            this.ipc_server = new MoonshotServer (this);
            logger.trace("init_ipc_server: Constructed new MoonshotServer");
            GLib.Bus.own_name (GLib.BusType.SESSION,
                               "org.janet.Moonshot",
                               GLib.BusNameOwnerFlags.NONE,
                               bus_acquired_cb,
                               (conn, name) => {logger.trace("init_ipc_server: name_acquired_closure");},
                               (conn, name) => {
                                   logger.trace("init_ipc_server: name_lost_closure");
                                   bool shown=false;
                                   try {
                                       IIdentityManager manager = Bus.get_proxy_sync (BusType.SESSION, name, "/org/janet/moonshot");
                                       shown = manager.show_ui();
                                   } catch (IOError e) {
                                       logger.error("init_ipc_server.name_lost_closure: Caught error: ");
                                   }
                                   if (!shown) {
                                       logger.error("init_ipc_server.name_lost_closure: Couldn't own name %s on dbus or show previously launched identity manager".printf(name));
                                       GLib.error ("Couldn't own name %s on dbus or show previously launched identity manager.", name);
                                   } else {
                                       logger.trace("init_ipc_server.name_lost_closure: Showed previously launched identity manager.");
                                       stdout.printf("Showed previously launched identity manager.\n");
                                       GLib.Process.exit(0);
                                   }
                               });
        }
    }

    private void init_ipc_server() {
        this.ipc_server = new MoonshotServer(this);
        bool shown = false;
        GLib.Bus.own_name(GLib.BusType.SESSION,
                          "org.janet.Moonshot",
                          GLib.BusNameOwnerFlags.NONE,
                          bus_acquired_cb,

                          // Name acquired callback:
                          (conn, name) => {
                              logger.trace(@"init_ipc_server: name_acquired_closure; show_requested=$show_requested");

                              name_is_owned = true;

                              // Now that we know that we own the name, it's safe to show the UI.
                              if (show_requested) {
                                  show();
                                  show_requested = false;
                              }
                              shown = true;
                          },

                          // Name lost callback:
                          (conn, name) => {
                              logger.trace("init_ipc_server: name_lost_closure");

                              // This callback usually means that another moonshot is already running.
                              // But it *might* mean that we lost the name for some other reason
                              // (though it's unclear to me yet what those reasons are.)
                              // Clearing these flags seems like a good idea for that case. -- dbreslau
                              name_is_owned = false;
                              show_requested = false;

                              try {
                                  if (!shown) {
                                      IIdentityManager manager = Bus.get_proxy_sync(BusType.SESSION, name, "/org/janet/moonshot");
                                      shown = manager.show_ui();
                                  }
                              } catch (IOError e) {
                                  logger.error("init_ipc_server.name_lost_closure: Caught IOError: " + e.message);
                              }
                              if (!shown) {
                                  logger.error("init_ipc_server.name_lost_closure: Couldn't own name %s on dbus or show previously launched identity manager".printf(name));
                                  GLib.error("Couldn't own name %s on dbus or show previously launched identity manager.", name);
                              } else {
                                  logger.trace("init_ipc_server.name_lost_closure: Showed previously launched identity manager.");
                                  stdout.printf("Showed previously launched identity manager.\n");
                                  GLib.Process.exit(0);
                              }
                          });
    }
#endif
}

static bool explicitly_launched = true;
static bool use_flat_file_store = false;
const GLib.OptionEntry[] options = {
    {"dbus-launched", 0, GLib.OptionFlags.REVERSE, GLib.OptionArg.NONE,
     ref explicitly_launched, "launch for dbus rpc use", null},
    {"flat-file-store", 0, 0, GLib.OptionArg.NONE,
     ref use_flat_file_store, "force use of flat file identity store (used by default only for headless operation)", null},
    {null}
};


public static int main(string[] args) {

#if LOG4VALA
    new IdentityManagerApp.dummy();
#endif

#if IPC_MSRPC
    bool headless = false;
#else
    bool headless = GLib.Environment.get_variable("DISPLAY") == null;
#endif

    if (headless) {
        try {
            var opt_context = new OptionContext(null);
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(options, null);
            opt_context.parse(ref args);
        } catch (OptionError e) {
            stdout.printf(_("error: %s\n"),e.message);
            stdout.printf(_("Run '%s --help' to see a full list of available options\n"), args[0]);
            return -1;
        }
        explicitly_launched = false;
    } else {
        try {
            if (!Gtk.init_with_args(ref args, _(""), options, null)) {
                stdout.printf(_("unable to initialize window\n"));
                return -1;
            }
        } catch (GLib.Error e) {
            stdout.printf(_("error: %s\n"),e.message);
            stdout.printf(_("Run '%s --help' to see a full list of available options\n"), args[0]);
            return -1;
        }
        gtk_available = true;
    }

#if OS_WIN32
    // Force specific theme settings on Windows without requiring a gtkrc file
    Gtk.Settings settings = Gtk.Settings.get_default();
    settings.set_string_property("gtk-theme-name", "ms-windows", "moonshot");
    settings.set_long_property("gtk-menu-images", 0, "moonshot");
#endif

    //TODO?? Do we need to call Intl.setlocale(LocaleCategory.MESSAGES, "");
    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);
       
       
    var app = new IdentityManagerApp(headless, use_flat_file_store);
    app.explicitly_launched = explicitly_launched;
    IdentityManagerApp.logger.trace(@"main: explicitly_launched=$explicitly_launched");
        
    if (app.explicitly_launched) {
        app.show();
    }

    if (headless) {
#if !IPC_MSRPC
        MainLoop loop = new MainLoop();
        loop.run();
#endif
    }
    else {
        Gtk.main();
    }

    return 0;
}

