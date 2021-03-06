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

const string MAIN_GROUP="Main";


#if IPC_DBUS
[DBus (name = "org.janet.Moonshot")]
interface IIdentityManager : GLib.Object {
  public abstract bool show_ui() throws IOError;
}
#endif

public enum UiMode {
    INTERACTIVE,
    NON_INTERACTIVE,
    DISABLED,
    MAX;

    public string to_string() {
        switch (this) {
            case INTERACTIVE:
                return "INTERACTIVE";

            case NON_INTERACTIVE:
                return "NON_INTERACTIVE";

            case DISABLED:
                return "DISABLED";

            default:
                assert_not_reached();
        }
    }

    public static UiMode[] all() {
        return { INTERACTIVE, NON_INTERACTIVE, DISABLED };
     }

}

public extern unowned string GetVersion();

public class IdentityManagerApp {
    public static MoonshotLogger logger = get_logger("IdentityManagerApp");

    public IdentityManagerModel model;
    public IdCard default_id_card;
    public bool explicitly_launched;
    public IdentityManagerInterface view;
    private MoonshotServer ipc_server;
    private bool name_is_owned;
    private bool show_requested;
    private bool shown;
    public bool use_flat_file_store {public get; private set;}
    public bool headless {public get; private set;}

    /** If we're successfully registered with DBus, or the UI was explicitly launched in TXT mode, show the UI.
        Otherwise, wait until we're registered. */
    public void show() {
        if (name_is_owned || (explicitly_launched && headless)) {
            if (view != null) {
                view.make_visible();
            }
        }
        else {
            show_requested = true;
        }
    }

#if USE_LOG4VALA
    // Call this from main() to ensure that the logger is initialized
    internal IdentityManagerApp.dummy() {}
#endif

    public IdentityManagerApp(bool headless, bool use_flat_file_store, bool cli_enabled, bool explicitly_launched) {
        this.headless = headless;
        this.explicitly_launched = explicitly_launched;

        use_flat_file_store |= UserForcesFlatFileStore();
        this.use_flat_file_store = use_flat_file_store;

#if GNOME_KEYRING || LIBSECRET_KEYRING
        bool keyring_available = (!use_flat_file_store) && KeyringStore.is_available();
#else
        bool keyring_available = false;
#endif

        IIdentityCardStore.StoreType store_type;
        if (headless || use_flat_file_store || !keyring_available) {
            logger.trace("Choosing FLAT_FILE store: headless=%d, use_flat_file_store=%d, keyring_available=%d".printf(
                (int) headless, (int) use_flat_file_store, (int) keyring_available));
            store_type = IIdentityCardStore.StoreType.FLAT_FILE;
        }
        else
            store_type = IIdentityCardStore.StoreType.KEYRING;

        model = new IdentityManagerModel(this, store_type);
        /* if headless, but we have nothing in the flat file store
         * and keyring is available, switch to keyring */
        if (headless && keyring_available && !use_flat_file_store && !model.HasNonTrivialIdentities())
            model.set_store_type(IIdentityCardStore.StoreType.KEYRING);


        /* We create one view or the other, or none if we have no control over STDOUT (i.e. daemons) */
        if (!headless)
            view = new IdentityManagerView(this, use_flat_file_store);
        else if (cli_enabled) {
            view = new IdentityManagerCli(this, use_flat_file_store);
        }

        Gee.List<IdCard> card_list = model.get_card_list();
        if (card_list.size > 0)
            this.default_id_card = card_list.last();

        /* Start the IPC server, except when explicitly launched in TEXT mode. */
        if (!(explicitly_launched && cli_enabled))
            init_ipc_server();
    }

    public bool add_identity(IdCard id, bool force_flat_file_store) {
        if (view != null)
        {
            logger.trace("add_identity: calling view.add_identity");
            return view.add_identity(id, model, force_flat_file_store);
        }
        else {
            logger.trace("add_identity: calling model.add_card");
            model.add_card(id, force_flat_file_store);
            return true;
        }
    }

    public static UiMode get_mode() {
        // get the mode from the environment variable
        string mode = GLib.Environment.get_variable("MOONSHOT_MODE");

        // if the variable is not set, get it from the configuration file
        if (mode == null)
            mode = get_string_setting(MAIN_GROUP, "moonshot_mode", "INTERACTIVE");
        mode = mode.up();
        if (mode == "NON_INTERACTIVE")
            return UiMode.NON_INTERACTIVE;
        else if (mode == "DISABLED")
            return UiMode.DISABLED;
        else
            return UiMode.INTERACTIVE;
    }

    public void select_identity(IdentityRequest request) {
        logger.trace("select_identity: request.nai=%s".printf(request.nai ?? "[null]"));

        IdCard identity = null;

        if (request.select_default) {
            identity = default_id_card;
        }

        // get the mode
        UiMode mode = get_mode();

        if (identity == null && mode != UiMode.DISABLED)
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

            if (confirm && (view != null) && mode == UiMode.INTERACTIVE) {
                view.queue_identity_request(request);
                if (!explicitly_launched)
                    show();
                return;
            } else {
                logger.debug("select_identity. Not showing UI because confirm=%d view=%d mode=%s".printf((int) confirm,
                                                                                                         (int) view,
                                                                                                         mode.to_string()));
            }
        }
        // Send back the identity (we can't directly run the
        // callback because we may be being called from a 'yield')
        GLib.Idle.add(
            () => {
                if (view != null && identity != null) {
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
#else
    private void bus_acquired_cb(DBusConnection conn) {
        logger.trace("bus_acquired_cb");
        try {
            conn.register_object("/org/janet/moonshot", ipc_server);
        }
        catch (Error e)
        {
            logger.error("bus_acquired_cb: Error registering object: " + e.message);
            stderr.printf("Couldn't register /org/janet/moonshot on dbus: %s\n", e.message);
            GLib.Process.exit(1);
        }
    }

    private void name_lost_cb(DBusConnection? conn, string name){
            logger.trace("name_lost_cb");

            // This callback usually means that another moonshot is already running.
            // But it *might* mean that we lost the name for some other reason
            // (though it's unclear to me yet what those reasons are.)
            // Clearing these flags seems like a good idea for that case. -- dbreslau
            name_is_owned = false;
            show_requested = false;

            // If we fail to connect to the DBus bus, this callback is called with conn=null
            if (conn == null) {
                    unowned string dbus_address_env = GLib.Environment.get_variable ("DBUS_SESSION_BUS_ADDRESS");
                    logger.error("name_lost_cb: Failed to connect to bus");
                    if (dbus_address_env == null) {
                            stderr.printf("Could not connect to dbus session bus (DBUS_SESSION_BUS_ADDRESS is not set).\n"+
                                                      "You may want to try 'dbus-run-session' to start a session bus.\n");
                            GLib.Process.exit(1);
                    } else {
                            stderr.printf("Could not connect to dbus session bus. (DBUS_SESSION_BUS_ADDRESS=\"%s\")\n"+
                                                      "You may want to unset DBUS_SESSION_BUS_ADDRESS or try 'dbus-run-session' to start a session bus.\n",
                                                      dbus_address_env);
                            GLib.Process.exit(1);
                    }
            }

            try {
                    if (!shown) {
                            IIdentityManager manager = Bus.get_proxy_sync(BusType.SESSION, name, "/org/janet/moonshot");
                            shown = manager.show_ui();
                    }
            } catch (IOError e) {
                    logger.error("name_lost_cb: Caught IOError: " + e.message);
            }
            if (!shown) {
                    logger.error("name_lost_cb: Couldn't own name '%s' on dbus or show previously launched identity manager".printf(name));
                    stderr.printf("Couldn't own name '%s' on dbus or show previously launched identity manager.\n", name);
                    GLib.Process.exit(1);
            } else {
                    logger.trace("name_lost_cb: Showed previously launched identity manager.");
                    stdout.printf("Showed previously launched identity manager.\n");
                    GLib.Process.exit(0);
            }
    }

    private void init_ipc_server() {
        this.ipc_server = new MoonshotServer(this);
        var our_name = "org.janet.Moonshot";
        shown = false;
        GLib.Bus.own_name(GLib.BusType.SESSION,
                          our_name,
                          GLib.BusNameOwnerFlags.NONE,
                          bus_acquired_cb,

                          // Name acquired callback:
                          (conn, name) => {
                              logger.trace(@"init_ipc_server: name_acquired_closure; show_requested=$show_requested; conn="
                              + (conn==null?"null":"non-null; name='" + name + "'"));

                              name_is_owned = true;

                              // Now that we know that we own the name, it's safe to show the UI.
                              if (show_requested) {
                                  show();
                                  show_requested = false;
                              }
                              shown = true;
                          },

                          name_lost_cb);

        }
#endif
}

static bool explicitly_launched = true;
static bool use_flat_file_store = false;
static bool cli_enabled = false;
static bool version = false;
static string? set_mode = null;
static bool get_mode = false;

const GLib.OptionEntry[] options = {
    {"dbus-launched", 0, GLib.OptionFlags.REVERSE, GLib.OptionArg.NONE,
     ref explicitly_launched, "launch for dbus rpc use", null},
    {"version", 'v', 0, GLib.OptionArg.NONE,
     ref version, "display version information and exit", null},
    {"cli", 0, 0, GLib.OptionArg.NONE,
     ref cli_enabled, "enable the command line interface (text-based)", null},
    {"flat-file-store", 'f', 0, GLib.OptionArg.NONE,
     ref use_flat_file_store, "force use of flat file identity store (used by default only for headless operation)", null},
    {"get-mode", 'g', 0, GLib.OptionArg.NONE,
     ref get_mode, "get the current mode of operation", null},
    {"set-mode", 's', 0, GLib.OptionArg.STRING,
     ref set_mode, "set the mode of operation (INTERACTIVE, NON_INTERACTIVE, DISABLED)", "MODE"},
    {null}
};


public static int main(string[] args) {

#if USE_LOG4VALA
    // Initialize the logger.
    new IdentityManagerApp.dummy();
#endif

#if IPC_MSRPC
    bool headless = false;
#else
    bool headless = GLib.Environment.get_variable("DISPLAY") == null;
#endif

    if (!headless) {
        try {
            if (!Gtk.init_with_args(ref args, _(""), options, null)) {
                stdout.printf(_("unable to initialize window\n"));
                return -1;
            }
            gtk_available = true;
        } catch (OptionError e) {
            stdout.printf(_("error (code=%d): %s\n"), e.code, e.message);
            if (e is  OptionError.FAILED) {
                // Couldn't open DISPLAY
                stdout.printf(_("Trying headless mode.\n"));
                headless = true;
            }
            else {
                stdout.printf(_("Run '%s --help' to see a full list of available options\n"), args[0]);
                return -1;
            }
        } catch (Error e) {
            stdout.printf(_("fatal error (%d): %s\n"), e.code, e.message);
            return -1;
        }
    }

    if (headless) {
        try {
            var opt_context = new OptionContext("");
            opt_context.set_help_enabled(true);
            opt_context.add_main_entries(options, null);
            opt_context.parse(ref args);
        } catch (OptionError e) {
            stdout.printf(_("error: %s\n"),e.message);
            stdout.printf(_("Run '%s --help' to see a full list of available options\n"), args[0]);
            return -1;
        }
        //explicitly_launched = false;
    }

#if OS_WIN32
    // Force specific theme settings on Windows without requiring a gtkrc file
    Gtk.Settings settings = Gtk.Settings.get_default();
    settings.set_string_property("gtk-theme-name", "ms-windows", "moonshot");
    settings.set_long_property("gtk-menu-images", 0, "moonshot");
#endif

    if (version) {
        stdout.printf(_("Moonshot UI version %s\n"), GetVersion());
        return 0;
    }

    if (get_mode) {
        stdout.printf(_("Moonshot is configured in mode: %s\n"), IdentityManagerApp.get_mode().to_string());
        return 0;
    }

    if (set_mode != null) {
        set_mode = set_mode.up();
        if (set_mode.has_prefix("INT"))
            set_mode = "INTERACTIVE";
        else if (set_mode.has_prefix("NON"))
            set_mode = "NON_INTERACTIVE";
        else if (set_mode.has_prefix("DIS"))
            set_mode = "DISABLED";
        else {
            stdout.printf(_("Invalid mode selected: %s\n"), set_mode);
            return -1;
        }
        set_string_setting(MAIN_GROUP, "moonshot_mode", set_mode);
        stdout.printf(_("Moonshot UI has been configured in %s mode\n"), set_mode);
        return 0;
    }

    //TODO?? Do we need to call Intl.setlocale(LocaleCategory.MESSAGES, "");
    Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
    Intl.bind_textdomain_codeset(Config.GETTEXT_PACKAGE, "UTF-8");
    Intl.textdomain(Config.GETTEXT_PACKAGE);

    // When explicitly launched in headless, cli is automatically enabled
    if (explicitly_launched && headless)
        cli_enabled = true;

    IdentityManagerApp app = new IdentityManagerApp(headless, use_flat_file_store, cli_enabled, explicitly_launched);
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
