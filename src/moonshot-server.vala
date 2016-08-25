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

#if IPC_DBUS

[DBus (name = "org.janet.Moonshot")]
public class MoonshotServer : Object {

    static MoonshotLogger logger = get_logger("MoonshotServer");

    private string app_name = "Moonshot";

    private IdentityManagerApp parent_app;

    public MoonshotServer(IdentityManagerApp app)
    {
        logger.trace("MoonshotServer.<constructor>; app=" + (app == null ? "null" : "non-null"));
        this.parent_app = app;
    }

    public bool show_ui()
    {
        logger.trace("MoonshotServer.show_ui");

        if (parent_app.view == null) {
            stderr.printf(app_name, "show_ui: parent_app.view is null!\n");
            logger.warn("show_ui: parent_app.view is null!");
            return false;
        }
        parent_app.show();
        parent_app.explicitly_launched = true;
        logger.trace("MoonshotServer.show_ui: returning true");
        return true;
    }

    public async bool get_identity(string nai,
                                   string password,
                                   string service,
                                   out string nai_out,
                                   out string password_out,
                                   out string server_certificate_hash,
                                   out string ca_certificate,
                                   out string subject_name_constraint,
                                   out string subject_alt_name_constraint)
    {
        logger.trace(@"MoonshotServer.get_identity: nai='$nai'; service='$service'");
        var request = new IdentityRequest(parent_app,
                                          nai,
                                          password,
                                          service);
        logger.trace(@"MoonshotServer.get_identity: Calling request.execute()");
        request.set_callback((IdentityRequest) => get_identity.callback());
        request.execute();
        logger.trace(@"MoonshotServer.get_identity: Back from request.execute()");
        yield;
        logger.trace(@"MoonshotServer.get_identity: back from yield");

        nai_out = "";
        password_out = "";
        server_certificate_hash = "";
        ca_certificate = "";
        subject_name_constraint = "";
        subject_alt_name_constraint = "";

        var id_card = request.id_card;

        if ((id_card != null) && (!id_card.is_no_identity())) {
            nai_out = id_card.nai;
            if ((request.password != null) && (request.password != ""))
                password_out = request.password;
            else
                password_out = id_card.password;

            server_certificate_hash = id_card.trust_anchor.server_cert;
            ca_certificate = id_card.trust_anchor.ca_cert;
            subject_name_constraint = id_card.trust_anchor.subject;
            subject_alt_name_constraint = id_card.trust_anchor.subject_alt;

            if (nai_out == null)
                nai_out = "";
            if (password_out == null)
                password_out = "";
            if (server_certificate_hash == null)
                server_certificate_hash = "";
            if (ca_certificate == null)
                ca_certificate = "";
            if (subject_name_constraint == null)
                subject_name_constraint = "";
            if (subject_alt_name_constraint == null)
                subject_alt_name_constraint = "";

            logger.trace(@"MoonshotServer.get_identity: returning with nai_out=$nai_out");

            return true;
        }

        logger.trace("MoonshotServer.get_identity: returning false");
        return false;
    }

    public async bool get_default_identity(out string nai_out,
                                           out string password_out,
                                           out string server_certificate_hash,
                                           out string ca_certificate,
                                           out string subject_name_constraint,
                                           out string subject_alt_name_constraint)
    {
        logger.trace("MoonshotServer.get_default_identity");
        var request = new IdentityRequest.default(parent_app);
        request.set_callback((IdentityRequest) => get_default_identity.callback());
        request.execute();
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

            server_certificate_hash = request.id_card.trust_anchor.server_cert;
            ca_certificate = request.id_card.trust_anchor.ca_cert;
            subject_name_constraint = request.id_card.trust_anchor.subject;
            subject_alt_name_constraint = request.id_card.trust_anchor.subject_alt;

            if (nai_out == null)
                nai_out = "";
            if (password_out == null)
                password_out = "";
            if (server_certificate_hash == null)
                server_certificate_hash = "";
            if (ca_certificate == null)
                ca_certificate = "";
            if (subject_name_constraint == null)
                subject_name_constraint = "";
            if (subject_alt_name_constraint == null)
                subject_alt_name_constraint = "";

            logger.trace("MoonshotServer.get_default_identity: returning true");
            return true;
        }

        return false;
    }

    public bool install_id_card(string   display_name,
                                string   user_name,
                                string   ?password,
                                string   ?realm,
                                string[] ?rules_patterns,
                                string[] ?rules_always_confirm,
                                string[] ?services,
                                string   ?ca_cert,
                                string   ?subject,
                                string   ?subject_alt,
                                string   ?server_cert,
                                int      force_flat_file_store)
    {
        IdCard idcard = new IdCard();

        idcard.display_name = display_name;
        idcard.username = user_name;
        idcard.password = password;
        if ((password != null) && (password != ""))
            idcard.store_password = true;
        idcard.issuer = realm;
        idcard.update_services(services);
        var ta = new TrustAnchor(ca_cert, server_cert, subject, subject_alt, false);

        if (!ta.is_empty()) {
            // We have to set the datetime_added here, because it isn't delivered via IPC.
            string ta_datetime_added = TrustAnchor.format_datetime_now();
            ta.set_datetime_added(ta_datetime_added);
            logger.trace("install_id_card : Set ta_datetime_added for '%s' to '%s'; ca_cert='%s'; server_cert='%s'".printf(idcard.display_name, ta.datetime_added, ta.ca_cert, ta.server_cert));
        }
        idcard.set_trust_anchor_from_store(ta);

        logger.trace("install_id_card: Card '%s' has services: '%s'"
                     .printf(idcard.display_name, idcard.get_services_string("; ")));

        logger.trace(@"Installing IdCard named '$(idcard.display_name)'; ca_cert='$(idcard.trust_anchor.ca_cert)'; server_cert='$(idcard.trust_anchor.server_cert)'");


        if (rules_patterns.length == rules_always_confirm.length)
        {
            /* workaround Centos vala array property bug: use temp array */
            Rule[] rules = new Rule[rules_patterns.length];
         
            for (int i = 0; i < rules.length; i++)
            { 
                rules[i].pattern = rules_patterns[i];
                rules[i].always_confirm = rules_always_confirm[i];
            }
            idcard.rules = rules;
        }

        ArrayList<IdCard>? old_duplicates = null;
        var ret = parent_app.add_identity(idcard, (force_flat_file_store != 0), out old_duplicates);

        if (old_duplicates != null) {
            // Printing to stdout here is ugly behavior; but it's old behavior that
            // may be expected. (TODO: Do we need to keep this?)
            foreach (IdCard id_card in old_duplicates) {
                stdout.printf("removed duplicate id for '%s'\n", id_card.nai);
            }
        }
        return ret;
    }


    public int install_from_file(string file_name)
    {
        var webp = new WebProvisioning.Parser(file_name);

        webp.parse();
        bool result = false;
        int installed_cards = 0;
        foreach (IdCard card in webp.cards)
        {
            string[] rules_patterns = {};
            string[] rules_always_confirm = {};
        
            if (card.rules.length > 0)
            {
                int i = 0;
                rules_patterns = new string[card.rules.length];
                rules_always_confirm = new string[card.rules.length];
                foreach (Rule r in card.rules)
                {
                    rules_patterns[i] = r.pattern;
                    rules_always_confirm[i] = r.always_confirm;
                    i++;
                }
            } 


            // prevent a crash by holding the reference to otherwise
            // unowned array(?)

            // string[] svcs = card.services.to_array();
            // string[] svcs = card.services.to_array()[:];
            string[] svcs = new string[card.services.size];
            for (int i = 0; i < card.services.size; i++) {
                svcs[i] = card.services[i];
            }

            logger.trace(@"install_from_file: Adding card with display name '$(card.display_name)'");
            result = install_id_card(card.display_name,
                                     card.username,
                                     card.password,
                                     card.issuer,
                                     rules_patterns,
                                     rules_always_confirm,
                                     svcs,
                                     card.trust_anchor.ca_cert,
                                     card.trust_anchor.subject,
                                     card.trust_anchor.subject_alt,
                                     card.trust_anchor.server_cert,
                                     0);
            if (result) {
                installed_cards++;
            }
        }
        return installed_cards;
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
    private static IdentityManagerApp parent_app;

    private static MoonshotServer instance = null;

    public static void start(IdentityManagerApp app)
    {
        parent_app = app;
        Rpc.server_start(MoonshotRpcInterface.spec, "/org/janet/Moonshot", Rpc.Flags.PER_USER);
    }

    public static MoonshotServer get_instance()
    {
        if (instance == null)
            instance = new MoonshotServer();
        return instance;
    }

    [CCode (cname = "moonshot_get_identity_rpc")]
    public static void get_identity(Rpc.AsyncCall call,
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
        logger.trace("(static) get_identity");

        bool result = false;

        var request = new IdentityRequest(parent_app,
                                          nai,
                                          password,
                                          service);

        // Pass execution to the main loop and block the RPC thread
        request.mutex = new Mutex();
        request.cond = new Cond();
        request.set_callback(return_identity_cb);

        request.mutex.lock();
        Idle.add(request.execute);

        while (request.complete == false)
            request.cond.wait(request.mutex);

        nai_out = "";
        password_out = "";
        server_certificate_hash = "";
        ca_certificate = "";
        subject_name_constraint = "";
        subject_alt_name_constraint = "";

        var id_card = request.id_card;

        if (id_card != null) {
            // The strings are freed by the RPC runtime
            nai_out = id_card.nai;
            password_out = id_card.password;
            server_certificate_hash = id_card.trust_anchor.server_cert;
            ca_certificate = id_card.trust_anchor.ca_cert;
            subject_name_constraint = id_card.trust_anchor.subject;
            subject_alt_name_constraint = id_card.trust_anchor.subject_alt;

            return_if_fail(nai_out != null);
            return_if_fail(password_out != null);
            return_if_fail(server_certificate_hash != null);
            return_if_fail(ca_certificate != null);
            return_if_fail(subject_name_constraint != null);
            return_if_fail(subject_alt_name_constraint != null);

            result = true;
        }

        // The outputs must be set before this function is called. For this
        // reason they are 'ref' not 'out' parameters - Vala assigns to the
        // 'out' parameters only at the end of the function, which is too
        // late.
        call.return(&result);

        request.cond.signal();
        request.mutex.unlock();
    }

    [CCode (cname = "moonshot_get_default_identity_rpc")]
    public static void get_default_identity(Rpc.AsyncCall call,
                                            ref string nai_out,
                                            ref string password_out,
                                            ref string server_certificate_hash,
                                            ref string ca_certificate,
                                            ref string subject_name_constraint,
                                            ref string subject_alt_name_constraint)
    {
        logger.trace("(static) get_default_identity");

        bool result;

        var request = new IdentityRequest.default(parent_app);
        request.mutex = new Mutex();
        request.cond = new Cond();
        request.set_callback(return_identity_cb);

        request.mutex.lock();
        Idle.add(request.execute);

        while (request.complete == false)
            request.cond.wait(request.mutex);

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

            return_if_fail(nai_out != null);
            return_if_fail(password_out != null);
            return_if_fail(server_certificate_hash != null);
            return_if_fail(ca_certificate != null);
            return_if_fail(subject_name_constraint != null);
            return_if_fail(subject_alt_name_constraint != null);

            result = true;
        }
        else
        {
            result = false;
        }

        call.return(&result);

        request.cond.signal();
        request.mutex.unlock();
    }

    // Called from the main loop thread when an identity has
    // been selected
    static void return_identity_cb(IdentityRequest request) {
        // Notify the RPC thread that the request is complete
        request.mutex.lock();
        request.cond.signal();

        // Block the main loop until the RPC call has returned
        // to avoid any races
        request.cond.wait(request.mutex);
        request.mutex.unlock();
    }

    [CCode (cname = "moonshot_install_id_card_rpc")]
    public static bool install_id_card(string     display_name,
                                       string     user_name,
                                       string     password,
                                       string     realm,
                                       string[]   rules_patterns,
                                       string[]   rules_always_confirm,
                                       string[]   services,
                                       string     ca_cert,
                                       string     subject,
                                       string     subject_alt,
                                       string     server_cert,
                                       bool       force_flat_file_store)
    {
        logger.trace("(static) install_id_card");
        IdCard idcard = new IdCard();

        bool success = false;
        Mutex mutex = new Mutex();
        Cond cond = new Cond();

        idcard.display_name = display_name;
        idcard.username = user_name;
        idcard.password = password;
        idcard.issuer = realm;
        idcard.services = services;
        idcard.trust_anchor.ca_cert = ca_cert;
        idcard.trust_anchor.subject = subject;
        idcard.trust_anchor.subject_alt = subject_alt;
        idcard.trust_anchor.server_cert = server_cert;

        if (rules_patterns.length == rules_always_confirm.length)
        {
            idcard.rules = new Rule[rules_patterns.length];
         
            for (int i = 0; i < idcard.rules.length; i++)
            { 
                idcard.rules[i].pattern = rules_patterns[i];
                idcard.rules[i].always_confirm = rules_always_confirm[i];
            }
        }

        mutex.lock();

        ArrayList<IdCard>? old_duplicates = null;
        // Defer addition to the main loop thread.
        Idle.add(() => {
                mutex.lock();
                success = parent_app.add_identity(idcard, force_flat_file_store, out old_duplicates);
                foreach (IdCard id_card in old_duplicates) {
                    stdout.printf("removing duplicate id for '%s'\n", new_card.nai);
                }
                cond.signal();
                mutex.unlock();
                return false;
            });

        cond.wait(mutex);
        mutex.unlock();

        return success;
    }

}


#endif
