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
        report_duplicate_nais();
        report_expired_trust_anchors();
    }

    /* Reports whether there are identities with ideantical NAI */
    private void report_duplicate_nais() {
        // TODO: This could be merged with GTK version
        Gee.List<Gee.List<IdCard>> duplicates;
        identities_manager.find_duplicate_nai_sets(out duplicates);
        foreach (Gee.List<IdCard> list in duplicates) {
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

    private void report_expired_trust_anchors() {
        Gee.List<IdCard> card_list = identities_manager.get_card_list();
        foreach (IdCard id_card in card_list) {
            if (id_card.trust_anchor.is_expired()) {
                string message = _("Trust anchor for identity '%s' expired the %s.\n\n").printf(id_card.nai, id_card.trust_anchor.get_expiration_date())
                    + _("That means that any attempt to authenticate with that identity will fail. ")
                    + _("Please, ask your organisation to provide you with an updated credential.");
                init_newt();
                info_dialog("Expired Trust Anchor", message, 70, 10);
                newtFinished();
            }
        }
    }

    /* Adds an identity to the store, showing feedback about the process */
    public bool add_identity(IdCard id_card, bool force_flat_file_store)
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
                info_dialog("Warning", "The ID card was already present in your keyring and does not need to be added again.");
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
            this.identities_manager.add_card(id_card, force_flat_file_store);
            return true;
        }
        else {
            return false;
        }
    }

    /* Queues an identity request. Since the TXT version can only handle one request, instead of a QUEUE object,
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
        newtDrawRootText(0, 0, "The Moonshot Text ID selector. Using %s backend".printf(this.identities_manager.get_store_type().to_string()));
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
        if (yesno_dialog("Remove ID card", "Are you sure you want to remove this identity?", false, 4))
            this.identities_manager.remove_card(id_card);
    }

    /* Adds an ID card */
    private void add_id_card_dialog() {
        newtComponent form, disp_entry, user_entry, realm_entry, passwd_entry, disp_label, user_label, passwd_label,
                realm_label, chosen, add_btn, cancel_btn, storepwd_chk, mfa_chk;
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
        passwd_entry = newtEntry(15, 4, null, 37, null, Flag.PASSWORD);
        storepwd_chk = newtCheckbox(53, 4, "Remember?", ' ', " *", null);
        mfa_chk = newtCheckbox(67, 4, "2FA?", ' ', " *", null);
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
        newtFormAddComponent(form, mfa_chk);
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
                id_card.has_2fa = (newtCheckboxGetValue(mfa_chk) == '*');
                if (id_card.display_name == "" || id_card.username == "" || id_card.issuer == "") {
                    info_dialog("Missing information", "Please, fill in the missing fields. Only the password one is optional");
                    repeat = true;
                    newtFormSetCurrent(form, disp_entry);
                }
                else {
                    this.identities_manager.add_card(id_card, false);
                }
            }
        } while (repeat);
        newtFormDestroy(form);
        newtPopWindow();
    }

    /* Edits an ID card */
    private void edit_id_card_dialog(IdCard id_card) {
        newtComponent form, disp_entry, user_entry, realm_entry, passwd_entry, cert_entry, disp_label, user_label,
                passwd_label, passwd_btn, realm_label, cert_label, services_label, edit_btn, cancel_btn, remove_btn,
                listbox, cert_btn, chosen, storepwd_chk, show_btn, mfa_chk;
        weak newtComponent focus;
        bool exit = false;
        Gee.List<string> services = new ArrayList<string>();
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
        passwd_entry = newtEntry(15, 4, id_card.password, 30, null, Flag.PASSWORD);
        storepwd_chk = newtCheckbox(46, 4, "Remember?", ' ', " *", null);
        mfa_chk = newtCheckbox(60, 4, "2FA?", ' ', " *", null);
        passwd_btn = newtCompactButton(68, 4, "Show");
        if (id_card.store_password)
            newtCheckboxSetValue(storepwd_chk, '*');
        if (id_card.has_2fa)
            newtCheckboxSetValue(mfa_chk, '*');
        cert_label = newtLabel(1, 5, "Trust anchor:");
        var ta_type = id_card.trust_anchor.get_anchor_type();
        string ta_type_name = (ta_type == TrustAnchor.TrustAnchorType.SERVER_CERT ? "Server certificate"
                               : (ta_type == TrustAnchor.TrustAnchorType.CA_CERT ? "CA certificate" : "None"));
        if (id_card.trust_anchor.is_expired())
            ta_type_name += " [EXPIRED]";

        cert_entry = newtTextbox(15, 5, 36, 1, 0);
        newtTextboxSetText(cert_entry, ta_type_name);
        newtComponentTakesFocus(cert_entry, false);
        cert_btn = newtCompactButton(60, 5, "Clear");
        show_btn = newtCompactButton(68, 5, "Show");
        services_label = newtLabel(1, 6, "FILL ME");
        listbox = newtListbox(1, 7, 9, Flag.SCROLL | Flag.BORDER | Flag.RETURNEXIT);
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
        newtFormAddComponent(form, mfa_chk);
        newtFormAddComponent(form, passwd_btn);
        newtFormAddComponent(form, cert_label);
        newtFormAddComponent(form, cert_entry);
        newtFormAddComponent(form, cert_btn);
        newtFormAddComponent(form, show_btn);
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
                newtListboxAppendEntry(listbox, service, (void*) (long) services.index_of(service));
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
            else if (chosen == show_btn) {
                if (ta_type == TrustAnchor.TrustAnchorType.SERVER_CERT) {
                    string msg = "Fingerprint:\n%s".printf(id_card.trust_anchor.server_cert);
                    info_dialog("Trust anchor details", msg, 70, 5, false);
                }
                else if (ta_type == TrustAnchor.TrustAnchorType.CA_CERT) {
                    string msg = "Subject: %s\n\n".printf(id_card.trust_anchor.subject)
                                 + "Expiration date: %s\n\n".printf(id_card.trust_anchor.get_expiration_date())
                                 + "CA certificate (PEM format):\n%s".printf(id_card.trust_anchor.ca_cert);
                    info_dialog("Trust anchor details", msg, 75, 20, true);
                }
            }
            else if (chosen == cert_btn) {
                newtTextboxSetText(cert_entry, "None");
                ta_type = TrustAnchor.TrustAnchorType.EMPTY;
                focus = cert_btn;
            }
            else if (chosen == passwd_btn) {
                info_dialog("Cleartext password",
                            "Your cleartext password is: <%s>".printf(newtEntryGetValue(passwd_entry)), 70, 3);
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
                id_card.has_2fa = (newtCheckboxGetValue(mfa_chk) == '*');
                id_card.update_services_from_list(services);
                if (ta_type == TrustAnchor.TrustAnchorType.EMPTY)
                    id_card.clear_trust_anchor();
                this.identities_manager.update_card(id_card);
            }
        } while (!exit);

        newtFormDestroy(form);
        newtPopWindow();
    }

    private bool id_card_menu(IdCard? id_card, bool include_send) {
        bool rv = false;
        newtComponent form, listbox, chosen;
        int height = include_send ? 4: 3;
        newtCenteredWindow(15, height, "Action");
        form = newtForm(null, null, 0);
        listbox = newtListbox(1, 0, height, Flag.RETURNEXIT);
        newtListboxSetWidth(listbox, 13);
        if (include_send)
            newtListboxAppendEntry(listbox, "Send", (void *) "Send");
        newtListboxAppendEntry(listbox, "Edit", (void *) "Edit");
        newtListboxAppendEntry(listbox, "Remove", (void *) "Remove");
        newtListboxAppendEntry(listbox, "Back", (void *) "Back");

        newtFormAddComponent(form, listbox);
        chosen = newtRunForm(form);
        if (chosen == listbox){
            string? option = (string?) newtListboxGetCurrent(listbox);
            if (option == "Send") {
                send_id_card_confirmation_dialog(id_card);
                rv = true;
            }
            else if (option == "Edit")
                edit_id_card_dialog(id_card);
            else if (option == "Remove")
                delete_id_card_dialog(id_card);
        }
        newtFormDestroy(form);
        newtPopWindow();
        return rv;
    }


    private void select_id_card_dialog() {
        newtComponent form, add_btn, listbox, exit_btn, chosen, about_btn, doc;
        bool exit_loop = false;
        int offset = 0;
        init_newt();
        do {
            newtCenteredWindow(78, 20, "Moonshot Identity Selector (Text version)");
            form = newtForm(null, null, 0);
            if (request != null) {
                offset = 1;
                newtComponent info = newtLabel(1, 0, "Request ID for: ");
                newtComponent serv = newtTextbox(17, 0, 59, 1, 0);
                newtTextboxSetColors(serv, Colorset.TITLE, Colorset.TITLE);
                newtTextboxSetText(serv, request.service);
                newtFormAddComponent(form, info);
                newtFormAddComponent(form, serv);
            }
            doc = newtLabel(1, offset, "Select an ID card to pop up more options");
            listbox = newtListbox(1, offset + 1, 17 - offset, Flag.SCROLL | Flag.BORDER | Flag.RETURNEXIT);
            newtListboxSetWidth(listbox, 76);
            Gee.List<IdCard> card_list = identities_manager.get_card_list();
            foreach (IdCard id_card in card_list) {
                string text = "%s %s (%s)".printf(id_card.trust_anchor.is_expired() ? "[EXPIRED]" : "", id_card.display_name, id_card.nai);
                newtListboxAppendEntry(listbox, text, id_card);
            }

            add_btn = newtCompactButton(1, 19, "Add");
            about_btn = newtCompactButton(60, 19, "About");
            exit_btn = newtCompactButton(69, 19, "Exit");
            newtFormAddComponent(form, listbox);
            newtFormAddComponent(form, doc);
            newtFormAddComponent(form, add_btn);
            newtFormAddComponent(form, about_btn);
            newtFormAddComponent(form, exit_btn);
            chosen = newtRunForm(form);
            IdCard? id_card = (IdCard?) newtListboxGetCurrent(listbox);
            if (chosen == add_btn){
                add_id_card_dialog();
            }
            else if (chosen == about_btn) {
                about_dialog();
            }
            else if (chosen == listbox) {
                exit_loop = id_card_menu(id_card, request != null);
            }
            else {
                // we need to send NULL identity to gracefully exit properly from the send_identity callback
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

    public bool confirm_trust_anchor(IdCard card, TrustAnchorConfirmationRequest request)
    {
        init_newt();
        string warning = "";
        int offset;
        if (card.trust_anchor.server_cert == "") {
            warning = _("You are using this identity for the first time with the following trust anchor:");
            offset = 2;
        }
        else {
            // The server's fingerprint isn't what we're expecting this server to provide.
            warning = _("WARNING: The certificate we received for the authentication server for %s").printf(card.issuer)
            + _(" is different than expected. Either the server certificate has changed, or an")
            + _(" attack may be underway. If you proceed to the wrong server, your login credentials may be compromised.");
            offset = 4;
        }

        bool result = false;
        newtComponent form, info, yes_btn, no_btn, chosen, comp;
        newtCenteredWindow(78, 18 + offset, "Accept trust anchor");
        info = newtTextbox(1, 0, 76, offset, Flag.WRAP);
        newtTextboxSetText(info, warning);
        form = newtForm(null, null, 0);

        comp = newtTextbox(1, offset + 2, 75, 1, 0);
        newtTextboxSetText(comp, "Server's trust anchor certificate (SHA-256 fingerprint):");
        newtFormAddComponent(form, comp);
        comp = newtTextbox(1, offset + 3, 75, 1, 0);
        newtTextboxSetText(comp, request.fingerprint != "" ? request.fingerprint : "None");
        newtTextboxSetColors(comp, Colorset.TITLE, Colorset.TITLE);
        newtFormAddComponent(form, comp);

        comp = newtTextbox(1, offset + 1, 10, 1, 0);
        newtTextboxSetText(comp, "Username:");
        newtFormAddComponent(form, comp);
        comp = newtTextbox(11, offset + 1, 65, 1, 0);
        newtTextboxSetText(comp, "%s@%s".printf(card.username, card.issuer));
        newtTextboxSetColors(comp, Colorset.TITLE, Colorset.TITLE);
        newtFormAddComponent(form, comp);

        comp = newtTextbox(1, offset + 4, 75, 1, 0);
        newtTextboxSetText(comp, "Server's trust anchor issuer:");
        newtFormAddComponent(form, comp);
        comp = newtTextbox(1, offset + 5, 75, 2,  Flag.WRAP | Flag.SCROLL);
        newtTextboxSetText(comp, request.issuer);
        newtTextboxSetColors(comp, Colorset.TITLE, Colorset.TITLE);
        newtFormAddComponent(form, comp);

        comp = newtTextbox(1, offset + 7, 75, 1, 0);
        newtTextboxSetText(comp, "Server's trust anchor subject:");
        newtFormAddComponent(form, comp);
        comp = newtTextbox(1, offset + 8, 75, 2,  Flag.WRAP | Flag.SCROLL);
        newtTextboxSetText(comp, request.subject);
        newtTextboxSetColors(comp, Colorset.TITLE, Colorset.TITLE);
        newtFormAddComponent(form, comp);

        comp = newtTextbox(1, offset + 10, 75, 1, 0);
        newtTextboxSetText(comp, "Server's trust anchor expiration:");
        newtFormAddComponent(form, comp);
        comp = newtTextbox(1, offset + 11, 75, 1,  Flag.WRAP | Flag.SCROLL);
        newtTextboxSetText(comp, request.expiration_date);
        newtTextboxSetColors(comp, Colorset.TITLE, Colorset.TITLE);
        newtFormAddComponent(form, comp);

        comp = newtTextbox(1, offset + 13, 75, 3, Flag.WRAP);
        newtTextboxSetText(comp, "Please, check with your realm administrator for the correct fingerprint for your "
                                 + "authentication server. If it matches the above fingerprint, confirm the change. "
                                 + "If not, then cancel.");
        newtFormAddComponent(form, comp);

        yes_btn = newtCompactButton(23, offset + 17, "Yes");
        no_btn = newtCompactButton(42, offset + 17, "No");

        newtFormAddComponent(form, info);
        newtFormAddComponent(form, yes_btn);
        newtFormAddComponent(form, no_btn);
        newtFormSetCurrent(form, no_btn);
        chosen = newtRunForm(form);
        if (chosen == yes_btn)
            result = true;
        newtFormDestroy(form);
        newtPopWindow();
        newtFinished();
        return result;
    }

    private void about_dialog()
    {
        string logo = """                         XXXXXXXXXX
                  XXXXXXXXXXXXXXXXXXXXXXXX
              XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
           XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  XXXXXX
         XXXXXXXXXXXXXXXXXXXXXXXXXXXX   XXXXXXXXXXX
       XXXXXXXXXXXXXXXXXXXXXXXXXXXX   XXXXXXXXXXXXXXX
      XXXXXXXXXXXXXXXXXXXXXXXXXX    XXXXXXXXXXXXXXXXXX
    XXXXXXXXXXXXXXXXXXXXXXXXXX    XXXXXXXXXXXXXXXXXXXXXX
   XXXXXXXXXXXXXXXXXXXXXXXXX    XXXXXXXXXXXXXXXXXXXXXXXXX
  XXXXXXXXXXXXXXXXXXXXXXXXX   XXXXXXXXXXXXXXXXXXXXXXXXXXXX
  XX  XXXXXXX   XXXX         XXXXX        XXXX  XXXXXX  XX
 XXX   XXXXX    XX   XXX     XXX    XXXX    XX    XXXX  XXX
 XXX     XX     X   XX    XX  XX  XXXXXXXX  XX     XXX  XXX
XXXX  XX    XX  X   X    XXX  X   XXXXXXXX  XX  XX  XX  XXXX
XXXX  XXX  XXX  XX      XXX   XX   XXXXXXX  XX  XXX  X  XXXX
XXXX  XXXXXXXX  XXX    XXX   XXXX   XXXX   XXX  XXXX    XXXX
XXXX  XXXXXXXX  XXXXX      XXXXXXXX      XXXXX  XXXXX   XXXX
 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 XXXXXXXX       XXX  XXXXX  XXXX       XXX          XXXXXXX
  XXXXXX   XXXX  XX  XXXXX  XX    XXXX   XXXXX  XXXXXXXXXX
  XXXXXX     XXXXXX  XXXXX  X   XXXXXXXX  XXXX  XXXXXXXXXX
   XXXXXXX       XX         X   XXXXXXXX  XXXX  XXXXXXXXX
    XXXX  XXXXX   X  XXXXX  XX   XXXXXX   XXXX  XXXXXXXX
      XX    X    XX  XXXXX  XXX   XXX    XXXXX  XXXXXX
       XXXX   XXXXX  XXXXX  XXXXX     XXXXXXXX  XXXXX
         XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
           XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
              XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                  XXXXXXXXXXXXXXXXXXXXXXXX
                         XXXXXXXXXX""";

        string license = """Copyright (c) 2018, JISC JANET(UK)
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

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.""";
        info_dialog("Moonshot project Text UI", "%s\n\n%s".printf(logo, license), 78, 20, true);
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

        // check 2FA
        if (retval.has_2fa) {
            init_newt();
            retval.mfa_code = password_dialog(
                "Enter 2FA code", "Enter the 2FA code for <%s> (<%s>)".printf(identity.display_name, identity.nai));
            newtFinished();
        }

        return retval;
    }
}
