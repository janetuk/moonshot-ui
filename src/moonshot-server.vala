#if IPC_DBUS

[DBus (name = "org.janet.Moonshot")]
public class MoonshotServer : Object {

    private MainWindow main_window;

    public MoonshotServer (Gtk.Window window)
    {
        this.main_window = (MainWindow) window;
    }

    public async bool get_identity (string nai,
                                    string password,
                                    string service,
                                    out string nai_out,
                                    out string password_out,
                                    out string server_certificate_hash,
                                    out string ca_certificate,
                                    out string subject_name_constraint,
                                    out string subject_alt_name_constraint)
    {
        var request = new IdentityRequest (main_window,
                                           nai,
                                           password,
                                           service);
        request.set_callback ((IdentityRequest) => get_identity.callback());
        request.execute ();
        yield;

        nai_out = "";
        password_out = "";
        server_certificate_hash = "";
        ca_certificate = "";
        subject_name_constraint = "";
        subject_alt_name_constraint = "";

        var id_card = request.id_card;

        if (id_card != null) {
            nai_out = id_card.nai;
            password_out = id_card.password;

            server_certificate_hash = "certificate";

            // User should have been prompted if there was no p/w.
            return_if_fail (nai_out != null);
            return_if_fail (password_out != null);

            return true;
        }

        return false;
    }

    public async bool get_default_identity (out string nai_out,
                                            out string password_out,
                                            out string server_certificate_hash,
                                            out string ca_certificate,
                                            out string subject_name_constraint,
                                            out string subject_alt_name_constraint)
    {
        var request = new IdentityRequest.default (main_window);
        request.set_callback ((IdentityRequest) => get_default_identity.callback());
        request.execute ();
        yield;

        nai_out = "";
        password_out = "";
        server_certificate_hash = "";
        ca_certificate = "";
        subject_name_constraint = "";
        subject_alt_name_constraint = "";

        if (request.id_card != null)
        {
            nai_out = request.id_card.nai;
            password_out = request.id_card.password;

            server_certificate_hash = "certificate";

            // User should have been prompted if there was no p/w.
            return_val_if_fail (nai_out != null, false);
            return_val_if_fail (password_out != null, false);

            return true;
        }

        return false;
    }
    
    public async bool install_id_card (string   display_name,
                                       string   user_name,
                                       string   password,
                                       string   realm,
                                       Rule[]   rules,
                                       string[] services,
                                       string   ca_cert,
                                       string   subject,
                                       string   subject_alt,
                                       string   server_cert)
    {
      IdCard idcard = new IdCard ();
      
      idcard.display_name = display_name;
      idcard.username = user_name;
      idcard.password = password;
      idcard.issuer = realm;
      idcard.rules = rules;
      idcard.services = services;
      idcard.trust_anchor.ca_cert = ca_cert;
      idcard.trust_anchor.subject = subject;
      idcard.trust_anchor.subject_alt = subject_alt;
      idcard.trust_anchor.server_cert = server_cert;
      /* TODO: Ask for confirmation */
      /* TODO: Check if display name already exists */
      
      main_window.insert_id_card (idcard);
      
      return true;
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

    [CCode (cname = "moonshot_get_identity_rpc")]
    public static void get_identity (Rpc.AsyncCall call,
                                     string nai,
                                     string password,
                                     string service,
                                     ref string nai_out,
                                     ref string password_out,
                                     ref string server_certificate_hash,
                                     ref string ca_certificate,
                                     ref string subject_name_constraint,
                                     ref string subject_alt_name_constraint)
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
        server_certificate_hash = "";
        ca_certificate = "";
        subject_name_constraint = "";
        subject_alt_name_constraint = "";

        var id_card = request.id_card;

        if (id_card == null) {
            // The strings are freed by the RPC runtime
            nai_out = id_card.nai;
            password_out = id_card.password;
            server_certificate_hash = "certificate";

            return_if_fail (nai_out != null);
            return_if_fail (password_out != null);
            return_if_fail (server_certificate_hash != null);
            return_if_fail (ca_certificate != null);
            return_if_fail (subject_name_constraint != null);
            return_if_fail (subject_alt_name_constraint != null);

            result = true;
        }

        // The outputs must be set before this function is called. For this
        // reason they are 'ref' not 'out' parameters - Vala assigns to the
        // 'out' parameters only at the end of the function, which is too
        // late.
        call.return (&result);

        request.cond.signal ();
        request.mutex.unlock ();
    }

    [CCode (cname = "moonshot_get_default_identity_rpc")]
    public static void get_default_identity (Rpc.AsyncCall call,
                                             ref string nai_out,
                                             ref string password_out,
                                             ref string server_certificate_hash,
                                             ref string ca_certificate,
                                             ref string subject_name_constraint,
                                             ref string subject_alt_name_constraint)
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
        server_certificate_hash = "";
        ca_certificate = "";
        subject_name_constraint = "";
        subject_alt_name_constraint = "";

        if (request.id_card != null)
        {
            nai_out = request.id_card.nai;
            password_out = request.id_card.password;
            server_certificate_hash = "certificate";

            return_if_fail (nai_out != null);
            return_if_fail (password_out != null);
            return_if_fail (server_certificate_hash != null);
            return_if_fail (ca_certificate != null);
            return_if_fail (subject_name_constraint != null);
            return_if_fail (subject_alt_name_constraint != null);

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
