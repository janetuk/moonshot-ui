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
using Newt;

public class IdentityManagerCli: IdentityManagerInterface, Object {
    static MoonshotLogger logger = get_logger("IdentityManagerCli");
    bool use_flat_file_store = false;
    protected IdentityManagerApp parent_app;
    internal IdentityManagerModel identities_manager;
    private IdentityRequest? request;

    public IdentityManagerCli(IdentityManagerApp app, bool use_flat_file_store) {
        parent_app = app;
        this.use_flat_file_store = use_flat_file_store;
        identities_manager = parent_app.model;
        request = null;
        unlock_keyring();
        report_duplicate_nais();
    }

    /* Attempts to unlock the model. This only happens if PAM is not configured to unlock the Gnome Keyring */
    private bool unlock_keyring() {
        if (identities_manager.is_locked()) {
            bool success = false;
            init_newt();
            while (!success) {
                string? password = password_dialog("Enter password to unlock your default keyring",
                                                   "The default keyring is LOCKED. Please, Configure PAM to auto-unlock "
                                                   + " on login if you don't trust entering your password here.");
                if (password == null) {
                    info_dialog("ERROR", "No keyring password provided. You are not able to use the CLI.", 70, 4);
                    return false;
                }
                success = identities_manager.unlock(password);
            }
            newtFinished();
        }
        return true;
    }

    /* Reports whether there are identities with ideantical NAI */
    private void report_duplicate_nais() {
        // TODO: This could be merged with GTK version
        ArrayList<ArrayList<IdCard>> duplicates;
        identities_manager.find_duplicate_nai_sets(out duplicates);
        foreach (ArrayList<IdCard> list in duplicates) {
            string message = _("The following identities use the same Network Access Identifier (NAI),\n'%s'.").printf(list.get(0).nai)
                + _("\n\nDuplicate NAIs are not allowed. Please remove identities you don't need, or modify") 
                + _(" user ID or issuer fields so that they are no longer the same NAI.");

            foreach (var card in list) {
                message += _("\n\nDisplay Name: '%s'\nServices:\n     %s").printf(card.display_name, card.get_services_string(",\n     "));
            }

            init_newt();
            info_dialog("Duplicate NAIs", message, 70, 20, true);
            newtFinished();
        }
    }

    /* Adds an identity to the store, showing feedback about the process */
    public bool add_identity(IdCard id_card, bool force_flat_file_store, out ArrayList<IdCard>? old_duplicates=null)
    {
        // TODO: This could be merged with GTK version
        bool dialog = false;
        IdCard? prev_id = identities_manager.find_id_card(id_card.nai, force_flat_file_store);
        logger.trace("add_identity(flat=%s, card='%s'): find_id_card returned %s"
                     .printf(force_flat_file_store.to_string(), id_card.display_name, (prev_id != null ? prev_id.display_name : "null")));
        init_newt();
        if (prev_id != null) {
            int flags = prev_id.Compare(id_card);
            logger.trace("add_identity: compare returned " + flags.to_string());
            if (flags == 0) {
                if (&old_duplicates != null) {
                    old_duplicates = new ArrayList<IdCard>();
                }

                return false; // no changes, no need to update
            } else if ((flags & (1 << IdCard.DiffFlags.DISPLAY_NAME)) != 0) {
                dialog = yesno_dialog(
                    "Install ID Card",
                    "Would you like to update ID Card '%s' using nai '%s'?".printf(prev_id.display_name, prev_id.nai),
                    true, 10);
            } else {
                dialog = yesno_dialog(
                    "Install ID Card",
                    "Would you like to replace ID Card '%s' using nai '%s' with the new ID Card '%s'?".printf(
                        prev_id.display_name, prev_id.nai, id_card.display_name),
                    true, 10);
            }
        } else {
            dialog = yesno_dialog(
                "Install ID Card",
                "Would you like to add '%s' ID Card to the ID Card Organizer?".printf(id_card.display_name),
                true, 10);
        }
        newtFinished();
        if (dialog) {
            this.identities_manager.add_card(id_card, force_flat_file_store, out old_duplicates);
            return true;
        }
        else {
            if (&old_duplicates != null) {
                old_duplicates = new ArrayList<IdCard>();
            }
            return false;
        }
    }

    /* Queues an identity request. Since the CLI version can only handle one request, instead of a QUEUE object, 
     * we store just the request object. */
    public void queue_identity_request(IdentityRequest request)
    {
        this.request = request;
    }

    /* Shows a generic info dialog. NEWT needs to be initialized */
    private void info_dialog(string title, string msg, int width=70, int height=10, bool scroll=false) {
        newtComponent form, info, button;
        newtCenteredWindow(width, height, title);
        int flags = scroll ? Flag.WRAP | Flag.SCROLL : Flag.WRAP;
        info = newtTextbox(1, 0, width - 3, height - 1, flags);
        newtTextboxSetText(info, msg);
        button = newtCompactButton((width - 11) / 2, height - 1, "Dismiss");
        form = newtForm(null, null, 0);
        newtFormAddComponent(form, info);
        newtFormAddComponent(form, button);
        newtRunForm(form);
        newtFormDestroy(form);
        newtPopWindow();
    }

    /* Shows a password request dialog. NEWT needs to be initialized */
    private string? password_dialog(string title, string text) {
        newtComponent form, entry, info, button, chosen;
        string? password = null;
        newtCenteredWindow(70, 6, title);
        info = newtTextbox(1, 0, 68, 3, Flag.WRAP);
        newtTextboxSetText(info, text);
        entry = newtEntry(1, 3, null, 68, null, Flag.PASSWORD | Flag.RETURNEXIT);
        button = newtCompactButton(30, 5, "Abort");
        form = newtForm(null, null, 0);
        newtFormAddComponent(form, entry);
        newtFormAddComponent(form, info);
        newtFormAddComponent(form, button);
        chosen = newtRunForm(form);
        password = newtEntryGetValue(entry);
        newtFormDestroy(form);
        newtPopWindow();
        if (chosen == button || password == "")
            return null;
        return password;
    }

    /* Shows a password request dialog. NEWT needs to be initialized */
    private string? password_dialog_remember(string title, string text, out bool remember) {
        newtComponent form, entry, info, accept, abort, chosen, storepwd_chk;
        string? password = null;
        newtCenteredWindow(70, 6, title);
        info = newtTextbox(1, 0, 68, 3, Flag.WRAP);
        newtTextboxSetText(info, text);
        entry = newtEntry(1, 3, null, 53, null, Flag.PASSWORD | Flag.RETURNEXIT);
        storepwd_chk = newtCheckbox(56, 3, "Remember?", ' ', " *", null);
        accept = newtCompactButton(20, 5, "Accept");
        abort = newtCompactButton(45, 5, "Abort");
        form = newtForm(null, null, 0);
        newtFormAddComponent(form, entry);
        newtFormAddComponent(form, storepwd_chk);
        newtFormAddComponent(form, info);
        newtFormAddComponent(form, accept);
        newtFormAddComponent(form, abort);
        chosen = newtRunForm(form);
        password = newtEntryGetValue(entry);
        remember = (newtCheckboxGetValue(storepwd_chk) == '*');
        newtFormDestroy(form);
        newtPopWindow();
        if (chosen == abort || password == "")
            return null;
        return password;
    }

    /* Initialise NEWT environment */
    private void init_newt()
    {
        newtInit();
        newtCls();
        newtDrawRootText(0, 0, "The Moonshot CLI ID selector. Using %s backend".printf(this.identities_manager.get_store_type().to_string()));
        newtDrawRootText(-25, -2, "(c) 2017 JISC limited");
    }

    /* Shows a YES/NO dialog. NEWT needs to be initialised */
    private bool yesno_dialog(string title, string  message, bool default_yes, int height) {
        bool result = false;
        newtComponent form, info, yes_btn, no_btn, chosen;
        newtCenteredWindow(66, height, title);
        info = newtTextbox(1, 0, 65, height - 1, Flag.WRAP);
        newtTextboxSetText(info, message);
        yes_btn = newtCompactButton(20, height - 1, "Yes");
        no_btn = newtCompactButton(39, height - 1, "No");
        form = newtForm(null, null, 0);
        newtFormAddComponent(form, info);
        newtFormAddComponent(form, yes_btn);
        newtFormAddComponent(form, no_btn);
        if (!default_yes)
            newtFormSetCurrent(form, no_btn);
        chosen = newtRunForm(form);
        if (chosen == yes_btn)
            result = true;
        newtFormDestroy(form);
        newtPopWindow();
        return result;
    }

    /* Shows a delete ID dialog. If successful, the ID is removed */
    private void delete_id_card_dialog(IdCard id_card) {
        if (yesno_dialog("Delete ID card", "Are you sure you want to delete this identity?", false, 4))
            this.identities_manager.remove_card(id_card);
    }

    /* Adds an ID card */
    private void add_id_card_dialog() {
        newtComponent form, disp_entry, user_entry, realm_entry, passwd_entry, disp_label, user_label, passwd_label,
                realm_label, chosen, add_btn, cancel_btn, storepwd_chk;
        bool repeat = false;
        newtCenteredWindow(78, 7, "Add Identity");
        form = newtForm(null, null, 0);
        disp_label = newtLabel(1, 1, "Display name:");
        user_label = newtLabel(1, 2, "User name:");
        realm_label = newtLabel(1, 3, "Realm:");
        passwd_label = newtLabel(1, 4, "Password:");
        disp_entry = newtEntry(15, 1, null, 60, null, 0);
        user_entry = newtEntry(15, 2, null, 60, null, 0);
        realm_entry = newtEntry(15, 3, null, 60, null, 0);
        passwd_entry = newtEntry(15, 4, null, 45, null, Flag.PASSWORD);
        storepwd_chk = newtCheckbox(62, 4, "Remember?", ' ', " *", null);
        add_btn = newtCompactButton(20, 6, "Add");
        cancel_btn = newtCompactButton(50, 6, "Cancel");
        newtFormAddComponent(form, disp_label);
        newtFormAddComponent(form, disp_entry);
        newtFormAddComponent(form, user_label);
        newtFormAddComponent(form, user_entry);
        newtFormAddComponent(form, realm_label);
        newtFormAddComponent(form, realm_entry);
        newtFormAddComponent(form, passwd_label);
        newtFormAddComponent(form, passwd_entry);
        newtFormAddComponent(form, storepwd_chk);
        newtFormAddComponent(form, add_btn);
        newtFormAddComponent(form, cancel_btn);

        do {
            repeat = false;
            chosen = newtRunForm(form);
            if (chosen == add_btn) {
                IdCard id_card = new IdCard();
                id_card.display_name = newtEntryGetValue(disp_entry);
                id_card.username = newtEntryGetValue(user_entry);
                id_card.issuer = newtEntryGetValue(realm_entry);
                id_card.password = newtEntryGetValue(passwd_entry);
                id_card.store_password = (newtCheckboxGetValue(storepwd_chk) == '*');
                if (id_card.display_name == "" || id_card.username == "" || id_card.issuer == "") {
                    info_dialog("Missing information", "Please, fill in the missing fields. Only password is optional");
                    repeat = true;
                    newtFormSetCurrent(form, disp_entry);
                }
                else
                    this.identities_manager.add_card(id_card, false);
            }
        } while (repeat);
        newtFormDestroy(form);
        newtPopWindow();
    }

    /* Edits an ID card */
    private void edit_id_card_dialog(IdCard id_card) {
        newtComponent form, disp_entry, user_entry, realm_entry, passwd_entry, cert_entry, disp_label, user_label,
                passwd_label, passwd_btn, realm_label, cert_label, services_label, edit_btn, cancel_btn, remove_btn,
                listbox, cert_btn, chosen, storepwd_chk;
        weak newtComponent focus;
        bool exit = false;
        ArrayList<string> services = new ArrayList<string>();
        services.add_all(id_card.services);

        newtCenteredWindow(78, 18, "Edit Identity");
        form = newtForm(null, null, 0);
        disp_label = newtLabel(1, 1, "Display name:");
        disp_entry = newtEntry(15, 1, id_card.display_name, 60, null, 0);
        user_label = newtLabel(1, 2, "User name:");
        user_entry = newtEntry(15, 2, id_card.username, 60, null, 0);
        realm_label = newtLabel(1, 3, "Realm:");
        realm_entry = newtEntry(15, 3, id_card.issuer, 60, null, 0);
        passwd_label = newtLabel(1, 4, "Password:");
        passwd_entry = newtEntry(15, 4, id_card.password, 36, null, Flag.PASSWORD);
        passwd_btn = newtCompactButton(66, 4, "Reveal");
        storepwd_chk = newtCheckbox(53, 4, "Remember?", ' ', " *", null);
        if (id_card.store_password)
            newtCheckboxSetValue(storepwd_chk, '*');
        cert_label = newtLabel(1, 5, "Trust anchor:");
        cert_entry = newtEntry(15, 5, id_card.trust_anchor.server_cert, 60, null, 0);
        newtComponentTakesFocus(cert_entry, false);
        cert_btn = newtCompactButton(14, 6, "Clear Trust Anchor");
        services_label = newtLabel(1, 7, "FILL ME");
        listbox = newtListbox(1, 8, 8, Flag.SCROLL | Flag.BORDER | Flag.RETURNEXIT);
        newtListboxSetWidth(listbox, 64);
        remove_btn = newtCompactButton(66, 9, "Remove");
        edit_btn = newtCompactButton(20, 17, "Update");
        cancel_btn = newtCompactButton(50, 17, "Cancel");

        newtFormAddComponent(form, disp_label);
        newtFormAddComponent(form, disp_entry);
        newtFormAddComponent(form, user_label);
        newtFormAddComponent(form, user_entry);
        newtFormAddComponent(form, realm_label);
        newtFormAddComponent(form, realm_entry);
        newtFormAddComponent(form, passwd_label);
        newtFormAddComponent(form, passwd_entry);
        newtFormAddComponent(form, storepwd_chk);
        newtFormAddComponent(form, passwd_btn);
        newtFormAddComponent(form, cert_label);
        newtFormAddComponent(form, cert_entry);
        newtFormAddComponent(form, cert_btn);
        newtFormAddComponent(form, services_label);
        newtFormAddComponent(form, listbox);
        newtFormAddComponent(form, remove_btn);
        newtFormAddComponent(form, edit_btn);
        newtFormAddComponent(form, cancel_btn);

        focus = disp_label;

        do {
            // fill the listbox
            newtListboxClear(listbox);
            newtLabelSetText(services_label, "Services (%d):".printf(services.size));
            foreach (string service in services) {
                newtListboxAppendEntry(listbox, service, (void*) services.index_of(service));
            }

            // set focus
            newtFormSetCurrent(form, focus);

            chosen = newtRunForm(form);

            if (chosen == listbox || chosen == remove_btn) {
                int index = (int) newtListboxGetCurrent(listbox);
                string service = services[index];
                bool remove = yesno_dialog("Remove service association",
                                           "You are about to remove the service <%s>.\n\n".printf(service)
                                           + "Are you sure you want to do this?", false, 5);
                if (remove)
                    services.remove_at(index);

                focus = listbox;
            }
            else if (chosen == cert_btn) {
                newtEntrySet(cert_entry, "", 0);
                focus = cert_btn;
            }
            else if (chosen == passwd_btn) {
                info_dialog("Cleartext password",
                            "Your cleartext password is: <%s>".printf(newtEntryGetValue(passwd_entry)),
                            70, 3);
                focus = passwd_btn;
            }
            else
                exit = true;

            if (chosen == edit_btn) {
                id_card.display_name = newtEntryGetValue(disp_entry);
                id_card.username = newtEntryGetValue(user_entry);
                id_card.issuer = newtEntryGetValue(realm_entry);
                id_card.password = newtEntryGetValue(passwd_entry);
                id_card.store_password = (newtCheckboxGetValue(storepwd_chk) == '*');
                if (newtEntryGetValue(cert_entry) == "")
                    id_card.clear_trust_anchor();
                id_card.update_services_from_list(services);
                this.identities_manager.update_card(id_card);
            }
        } while (!exit);

        newtFormDestroy(form);
        newtPopWindow();
    }

    private void select_id_card_dialog() {
        newtComponent form, add_btn, edit_btn, send_btn, del_btn, listbox, exit_btn, chosen, about_btn;
        bool exit_loop = false;
        // GnomeKeyringFound *id_card = NULL, *result = NULL;
        init_newt();
        do {
            newtCenteredWindow(78, 20, "Moonshot Identity Selector (CLI)");
            form = newtForm(null, null, 0);
            if (request != null) {
                newtComponent info = newtTextbox(1, 0, 30, 1, Flag.WRAP);
                newtComponent serv = newtTextbox(31, 0, 46, 2, Flag.WRAP);
                newtTextboxSetColors(serv, Colorset.TITLE, Colorset.TITLE);
                newtTextboxSetText(info, "Identity request for service: ");
                newtTextboxSetText(serv, request.service);
                newtFormAddComponent(form, info);
                newtFormAddComponent(form, serv);
            }
            listbox = newtListbox(1, 2, 18, Flag.SCROLL | Flag.BORDER | Flag.RETURNEXIT);
            newtListboxSetWidth(listbox, 67);
            LinkedList<IdCard> card_list = identities_manager.get_card_list();
            foreach (IdCard id_card in card_list) {
                string text = "%s (%s)".printf(id_card.display_name, id_card.nai);
                newtListboxAppendEntry(listbox, text, id_card);
            }

            add_btn = newtCompactButton(68, 3, "Add");
            edit_btn = newtCompactButton(68, 5, "Edit");
            del_btn = newtCompactButton(68, 7, "Remove");
            send_btn = newtCompactButton(68, 9, "Send");
            about_btn = newtCompactButton(68, 16, "About");
            exit_btn = newtCompactButton(68, 18, "Exit");
            newtFormAddComponent(form, listbox);
            newtFormAddComponent(form, add_btn);
            newtFormAddComponent(form, edit_btn);
            newtFormAddComponent(form, del_btn);
            if (request != null) {
                newtFormAddComponent(form, send_btn);
            }
            newtFormAddComponent(form, about_btn);
            newtFormAddComponent(form, exit_btn);
            chosen = newtRunForm(form);
            IdCard? id_card = (IdCard?) newtListboxGetCurrent(listbox);
            if (chosen == add_btn){
                add_id_card_dialog();
            }
            else if (chosen == edit_btn || (chosen == listbox && request == null)) {
                edit_id_card_dialog(id_card);
            }
            else if (chosen == del_btn) {
                delete_id_card_dialog(id_card);
            }
            else if (chosen == about_btn) {
                about_dialog();
            }
            else if (request != null && (chosen == send_btn  || chosen == listbox)) {
                send_id_card_confirmation_dialog(id_card);
                exit_loop = true;
            }
            else {
                send_id_card_confirmation_dialog(null);
                exit_loop = true;
            }

            newtFormDestroy(form);
            newtPopWindow();
        } while (!exit_loop);
        newtFinished();
    }

    public void make_visible()
    {
        select_id_card_dialog();
        if (parent_app.explicitly_launched)
            GLib.Process.exit(0);
    }

    public bool confirm_trust_anchor(IdCard card, string userid, string realm, string fingerprint)
    {
        init_newt();
        string msg = """
You are using your identity <%s> for the first time with the following trust anchor:

%s

Please, check with your realm administrator for the correct fingerprint for your authentication server.
If it matches the above fingerprint, confirm the change. If not, then cancel.""".printf(card.nai, fingerprint);
        bool confirmed = yesno_dialog("Accept trust anchor", msg, false, 10);
        newtFinished();
        return confirmed;
    }

    private void about_dialog()
    {
        string copyright = "Copyright (c) 2017, JISC";

        string license =
        """
Copyright (c) 2017, JISC JANET(UK)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

3. Neither the name of JANET(UK) nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.
""";
        info_dialog("Moonshot project CLI UI", license, 78, 20, true);
    }

    private void send_id_card_confirmation_dialog(IdCard? id_card) {
        bool remember = true;
        IdCard? identity = null;
        if (id_card != null) {
            if (!id_card.services.contains(this.request.service)) {
                remember = yesno_dialog("Remember identity choice",
                                         "Do you want to remember your identity choice for this server?", false, 4);
            }

            /* Update password with the information from the user */
            identity = check_add_password(id_card, request, identities_manager);
            if ((identity != null) && (!identity.is_no_identity()))
                parent_app.default_id_card = identity;
        }
        // Send back the identity (we can't directly run the callback because we may be being called from a 'yield')
        GLib.Idle.add(
            () => {
                this.request.return_identity(identity, remember);
                return false;
            }
        );
    }

    public IdCard check_add_password(IdCard identity, IdentityRequest request, IdentityManagerModel model)
    {
        logger.trace(@"check_add_password");
        IdCard retval = identity;
        bool idcard_has_pw = (identity.password != null) && (identity.password != "");
        bool request_has_pw = (request.password != null) && (request.password != "");
        if ((!idcard_has_pw) && (!identity.is_no_identity())) {
            if (request_has_pw) {
                identity.password = request.password;
                retval = model.update_card(identity);
            } else {
                bool remember;
                init_newt();
                identity.password = password_dialog_remember(
                    "Enter password", "Enter the password for <%s> (<%s>)".printf(identity.display_name, identity.nai), out remember);
                newtFinished();
                identity.store_password = remember;
                if (remember)
                    identity.temporary = false;
                retval = model.update_card(identity);
            }
        }
        return retval;
    }
}
