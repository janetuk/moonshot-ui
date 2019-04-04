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

const string WARN_GROUP="WarningDialogs";
const string PATH_GROUP="Paths";

public class IdentityManagerCli: IdentityManagerInterface, Object {
    static MoonshotLogger logger = get_logger("IdentityManagerCli");
    bool use_flat_file_store = false;
    protected IdentityManagerApp parent_app;
    internal IdentityManagerModel identities_manager;
    private IdentityRequest? request;
    private bool newt_initiated;

    public IdentityManagerCli(IdentityManagerApp app, bool use_flat_file_store) {
        parent_app = app;
        newt_initiated = false;
        this.use_flat_file_store = use_flat_file_store;
        identities_manager = parent_app.model;
        request = null;
        report_duplicate_nais(identities_manager);
        report_expired_trust_anchors(identities_manager);
    }

    /* Queues an identity request. Since the TXT version can only handle one request, instead of a QUEUE object,
     * we store just the request object. */
    public void queue_identity_request(IdentityRequest request)
    {
        this.request = request;
    }

    private int estimate_text_height(string message, int width)
    {
        string[] substrings = message.split("\n");
        return ((int) message.length / width + substrings.length);
    }

    private int estimate_text_width(string message)
    {
        int max_width = 0;
        string[] substrings = message.split("\n");
        foreach(string str in substrings)
            if (str.length > max_width)
                max_width = (int) str.length;
        return max_width > 77 ? 77 : max_width;
    }

    /* Shows a generic info dialog. NEWT needs to be initialized */
    private void info_dialog(string title, string msg)
    {
        bool finalize = newt_init();
        int text_height, text_width;
        string message = newtReflowText(msg, 76, 50, 0, out text_width, out text_height);
        newtComponent form, info, button;
        int flags = 0;
        if (text_height > 20) {
            text_height = 20;
            flags |= Flag.SCROLL;
        }
        newtCenteredWindow(text_width + 2, text_height + 1, title);
        info = newtTextbox(0, 0, text_width, text_height, flags);
        newtTextboxSetText(info, message);
        button = newtCompactButton((text_width - 11) / 2, text_height, "Dismiss");
        form = newtForm(null, null, 0);
        newtFormAddComponent(form, info);
        newtFormAddComponent(form, button);
        newtRunForm(form);
        newtFormDestroy(form);
        newtPopWindow();
        newt_finish(finalize);
    }

    /* Shows a password request dialog. */
    private string? password_dialog(string title, string text, bool show_remember, out bool remember)
    {
        bool finalize = newt_init();
        newtComponent form, entry, info, accept, abort, chosen, storepwd_chk;
        string? password = null;
        int text_height, text_width;
        string message = newtReflowText(text, 70, 0, 0, out text_width, out text_height);
        newtCenteredWindow(70, text_height + 4, title);
        info = newtTextbox(0, 0, 70, text_height, 0);
        newtTextboxSetText(info, message);
        int entrylen = show_remember ? 53 : 68;
        entry = newtEntry(0, text_height + 1, null, entrylen, null, Flag.PASSWORD | Flag.RETURNEXIT | Flag.SCROLL);
        storepwd_chk = newtCheckbox(56, text_height + 1, "Remember?", ' ', " *", null);
        accept = newtCompactButton(20, text_height + 3, "Accept");
        abort = newtCompactButton(45, text_height + 3, "Abort");
        form = newtForm(null, null, 0);
        newtFormAddComponent(form, entry);
        if (show_remember)
            newtFormAddComponent(form, storepwd_chk);
        newtFormAddComponent(form, info);
        newtFormAddComponent(form, accept);
        newtFormAddComponent(form, abort);
        chosen = newtRunForm(form);
        password = newtEntryGetValue(entry);
        remember = (newtCheckboxGetValue(storepwd_chk) == '*');
        newtFormDestroy(form);
        newtPopWindow();
        newt_finish(finalize);
        if (chosen == abort || password == "")
            return null;
        return password;
    }

    /* Initialise NEWT environment */
    private bool newt_init()
    {
        if (newt_initiated)
            return false;
        newtInit();
        newtCls();
        newtDrawRootText(0, 0, "The Moonshot Text ID selector. Using %s backend".printf(this.identities_manager.get_store_type().to_string()));
        newtDrawRootText(-25, -1, "(c) 2019 Jisc limited");
        newt_initiated = true;
        return true;
    }

    private void newt_finish(bool finalize)
    {
        if (finalize){
            newtFinished();
            newt_initiated = false;
        }
    }

    /* Shows a YES/NO dialog. NEWT needs to be initialised */
    private bool yesno_dialog(string title, string msg, bool default_yes) {
        if (get_bool_setting(WARN_GROUP, title, false)) {
            logger.trace(@"confirm: Settings group $WARN_GROUP has 'true' for key $title; skipping dialog and returning true.");
            return true;
        }
        bool finalize = newt_init();
        bool result = false;
        int text_height, text_width;
        string message = newtReflowText(msg, 78, 30, 0, out text_width, out text_height);
        newtComponent form, info, yes_btn, no_btn, remember_chk, chosen;
        newtCenteredWindow(text_width, text_height + 4, title);
        info = newtTextbox(0, 0, text_width, text_height, 0);
        newtTextboxSetText(info, message);
        remember_chk = newtCheckbox(0, text_height + 1, _("Do not show this message again"), ' ', " *", null);
        no_btn = newtCompactButton(text_width / 2 - 10, text_height + 3, "No");
        yes_btn = newtCompactButton(text_width / 2 + 5, text_height + 3, "Yes");
        form = newtForm(null, null, 0);
        newtFormAddComponent(form, info);
        newtFormAddComponent(form, remember_chk);
        newtFormAddComponent(form, no_btn);
        newtFormAddComponent(form, yes_btn);
        if (!default_yes)
            newtFormSetCurrent(form, no_btn);
        chosen = newtRunForm(form);
        if (chosen == yes_btn) {
            result = true;
            if (newtCheckboxGetValue(remember_chk) == '*') {
                set_bool_setting(WARN_GROUP, title, true);
            }
        }
        newtFormDestroy(form);
        newtPopWindow();
        newt_finish(finalize);
        return result;
    }

    /* Shows a delete ID dialog. If successful, the ID is removed */
    private void delete_id_card_dialog(IdCard id_card) {
        if (yesno_dialog("Remove ID card", "Are you sure you want to remove this identity?", false))
            this.identities_manager.remove_card(id_card);
    }

    /* Adds an ID card */
    private void add_id_card_dialog() {
        bool finalize = newt_init();
        newtComponent form, disp_entry, user_entry, realm_entry, passwd_entry, disp_label, user_label, passwd_label,
                realm_label, chosen, add_btn, cancel_btn, storepwd_chk, mfa_chk;
        bool repeat = false;
        newtCenteredWindow(78, 7, "Add Identity");
        form = newtForm(null, null, 0);
        disp_label = newtLabel(1, 1, "Display name:");
        user_label = newtLabel(1, 2, "User name:");
        realm_label = newtLabel(1, 3, "Realm:");
        passwd_label = newtLabel(1, 4, "Password:");
        disp_entry = newtEntry(15, 1, null, 60, null, Flag.SCROLL);
        user_entry = newtEntry(15, 2, null, 60, null, Flag.SCROLL);
        realm_entry = newtEntry(15, 3, null, 60, null, Flag.SCROLL);
        passwd_entry = newtEntry(15, 4, null, 37, null, Flag.PASSWORD | Flag.SCROLL);
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
                    info_dialog("Missing information",
                                "Please, fill in the missing fields. Only the password one is optional");
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
        newt_finish(finalize);
    }

    /* Edits an ID card */
    private void edit_id_card_dialog(IdCard id_card) {
        bool finalize = newt_init();
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
        disp_entry = newtEntry(15, 1, id_card.display_name, 60, null, Flag.SCROLL);
        user_label = newtLabel(1, 2, "User name:");
        user_entry = newtEntry(15, 2, id_card.username, 60, null, Flag.SCROLL);
        realm_label = newtLabel(1, 3, "Realm:");
        realm_entry = newtEntry(15, 3, id_card.issuer, 60, null, Flag.SCROLL);
        passwd_label = newtLabel(1, 4, "Password:");
        passwd_entry = newtEntry(15, 4, id_card.password, 30, null, Flag.PASSWORD | Flag.SCROLL);
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
                if (services.size > 0) {
                    int index = (int) newtListboxGetCurrent(listbox);
                    string service = services[index];
                    bool remove = yesno_dialog("Remove service association",
                                       "You are about to remove the service <%s>.\n\n".printf(service)
                                       + "Are you sure you want to do this?", false);
                    if (remove)
                        services.remove_at(index);
                }
                focus = listbox;
            }
            else if (chosen == show_btn) {
                if (ta_type == TrustAnchor.TrustAnchorType.SERVER_CERT) {
                    string msg = "Fingerprint:\n%s".printf(id_card.trust_anchor.server_cert);
                    info_dialog("Trust anchor details", msg);
                }
                else if (ta_type == TrustAnchor.TrustAnchorType.CA_CERT) {
                    uint8 cert_info[4096];
                    uint8[] der_cert = Base64.decode(id_card.trust_anchor.ca_cert);
                    string cert_info_msg = "Could not load certificate!";
                    int rv = parse_der_certificate(der_cert, der_cert.length, cert_info, 4096);
                    if (rv == 1)
                        cert_info_msg = (string) cert_info;

                    string msg = "Subject: %s\n\n".printf(id_card.trust_anchor.subject)
                                 + "Expiration date: %s\n\n".printf(id_card.trust_anchor.get_expiration_date())
                                 + "CA certificate:\n%s".printf(cert_info_msg);
                    info_dialog("Trust anchor details", msg);
                }
            }
            else if (chosen == cert_btn) {
                newtTextboxSetText(cert_entry, "None");
                ta_type = TrustAnchor.TrustAnchorType.EMPTY;
                focus = cert_btn;
            }
            else if (chosen == passwd_btn) {
                info_dialog("Cleartext password",
                            "Your cleartext password is:\n<%s>".printf(newtEntryGetValue(passwd_entry)));
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
        newt_finish(finalize);
    }

    private bool id_card_menu(IdCard? id_card, bool include_send, bool remember) {
        bool finalize = newt_init();
        bool rv = false;
        newtComponent form, listbox, chosen;
        int height = include_send ? 5: 3;
        newtCenteredWindow(15, height, "Action");
        form = newtForm(null, null, 0);
        listbox = newtListbox(0, 0, height, Flag.RETURNEXIT);
        newtListboxSetWidth(listbox, 15);
        if (include_send) {
            newtListboxAppendEntry(listbox, "Send", (void *) "Send");
            newtListboxAppendEntry(listbox, "Send & forget", (void *) "SendForget");
        }
        newtListboxAppendEntry(listbox, "Edit", (void *) "Edit");
        newtListboxAppendEntry(listbox, "Remove", (void *) "Remove");
        newtListboxAppendEntry(listbox, "Back", (void *) "Back");

        newtFormAddComponent(form, listbox);
        chosen = newtRunForm(form);
        if (chosen == listbox){
            string? option = (string?) newtListboxGetCurrent(listbox);
            if (option == "Send") {
                send_id_card_confirmation_dialog(id_card, remember);
                rv = true;
            }
            else if (option == "SendForget") {
                send_id_card_confirmation_dialog(id_card, false);
                rv = true;
            }
            else if (option == "Edit")
                edit_id_card_dialog(id_card);
            else if (option == "Remove")
                delete_id_card_dialog(id_card);
        }
        newtFormDestroy(form);
        newtPopWindow();
        newt_finish(finalize);
        return rv;
    }

    private string select_file_dialog() {
        newtComponent form, listbox, cancel_btn, chosen;
        bool exit_loop = false;
        string directory = get_string_setting(PATH_GROUP, "last_import_folder", GLib.Environment.get_home_dir());
        string? result = null;
        do {
            bool finalize = newt_init();
            newtCenteredWindow(60, 22, "Import Identity file");
            form = newtForm(null, null, 0);
            newtComponent locator = newtTextbox(0, 0, 60, 2, Flag.WRAP);
            newtTextboxSetColors(locator, Colorset.TITLE, Colorset.TITLE);
            newtTextboxSetText(locator, directory);
            listbox = newtListbox(0, 2, 18, Flag.SCROLL | Flag.BORDER | Flag.RETURNEXIT);
            cancel_btn = newtCompactButton(25, 21, "Cancel");
            GLib.List<string> files = new GLib.List<string>();
            newtListboxSetWidth(listbox, 58);
            try{
                string? name = null;
                Dir dir = Dir.open(directory, 0);
                while ((name = dir.read_name()) != null) {
                    string path = Path.build_filename(directory, name);
                    files.insert_sorted(path, strcmp);
                }
                for (int i=0; i<files.length(); i++) {
                    string entry = files.nth_data(i);
                    string text = "%s%s".printf(
                        Path.get_basename(entry),
                        FileUtils.test(entry, FileTest.IS_DIR) ? "/" : "");
                    newtListboxAppendEntry(listbox, text, files.nth(i));
                }

                // Include ../ since GLib does not provide it to us
                files.insert_before(files.first(), Path.get_dirname(directory));
                newtListboxInsertEntry(listbox, "../", files.first(), null);
            } catch (Error e) {
                logger.error("Could not open folder!");
            }

            newtFormAddComponent(form, locator);
            newtFormAddComponent(form, listbox);
            newtFormAddComponent(form, cancel_btn);
            chosen = newtRunForm(form);
            unowned GLib.List<string>? element = (GLib.List<string>) newtListboxGetCurrent(listbox);
            if (chosen == listbox) {
                if (FileUtils.test(element.data, FileTest.IS_DIR))
                    directory = element.data;
                else {
                    set_string_setting(PATH_GROUP, "last_import_folder", directory);

                    result = element.data;
                    exit_loop = true;
                }
            }
            else
                exit_loop = true;
            newtFormDestroy(form);
            newtPopWindow();
            newt_finish(finalize);
        } while (!exit_loop);

        return result;
    }

    private void import_identities_dialog() {
        string? filename = select_file_dialog();
        if (filename == null)
            return;

        import_identities(filename, identities_manager, logger);
    }

    private void select_id_card_dialog() {
        newtComponent form, add_btn, listbox, exit_btn, chosen, about_btn, import_btn,
                      edit_btn, remove_btn, send_btn, remember_chk, doc, filter_entry, filter_btn;
        bool exit_loop = false;
        int offset = 0;
        string filter = "";
        weak newtComponent focus;

        bool finalize = newt_init();
        newtCenteredWindow(78, 20, "Moonshot Identity Selector (Text version)");
        form = newtForm(null, null, 0);
        if (request != null) {
            offset = 1;
            newtComponent info = newtLabel(1, 0, "ID requested for: ");
            newtComponent serv = newtTextbox(19, 0, 59, 1, 0);
            newtTextboxSetColors(serv, Colorset.TITLE, Colorset.TITLE);
            newtTextboxSetText(serv, request.service);
            newtFormAddComponent(form, info);
            newtFormAddComponent(form, serv);
        }

        doc = newtLabel(1, offset, "Select your identity:");
        filter_entry = newtEntry(22, offset, filter, 35, null, Flag.RETURNEXIT | Flag.SCROLL);
        filter_btn = newtCompactButton(57, offset, "Filter");
        listbox = newtListbox(1, offset + 1, 18 - offset, Flag.SCROLL | Flag.BORDER | Flag.RETURNEXIT);
        newtListboxSetWidth(listbox, 66);
        add_btn = newtCompactButton(68, offset + 2, "Add");
        import_btn = newtCompactButton(68, offset + 4, "Import");
        edit_btn = newtCompactButton(68, offset + 6, "Edit");
        remove_btn = newtCompactButton(68, offset + 8, "Remove");
        send_btn = newtCompactButton(68, offset + 10, "Send");
        about_btn = newtCompactButton(68, 15, "About");
        exit_btn = newtCompactButton(68, 17, "Exit");
        remember_chk = newtCheckbox(1, 19, "Remember my identity choice for this service", '*', " *", null);
        newtFormAddComponent(form, filter_entry);
        newtFormAddComponent(form, filter_btn);
        newtFormAddComponent(form, listbox);
        newtFormAddComponent(form, doc);
        if (request != null)
            newtFormAddComponent(form, remember_chk);
        newtFormAddComponent(form, add_btn);
        newtFormAddComponent(form, import_btn);
        newtFormAddComponent(form, edit_btn);
        newtFormAddComponent(form, remove_btn);
        if (request != null)
            newtFormAddComponent(form, send_btn);
        newtFormAddComponent(form, about_btn);
        newtFormAddComponent(form, exit_btn);

        focus = listbox;
        IdCard? selected_id_card = null;
        do {
            Gee.List<IdCard> card_list = identities_manager.get_card_list();
            newtListboxClear(listbox);
            foreach (IdCard id_card in card_list) {
                if (filter != "" && !id_matches_search(id_card, filter, null))
                    continue;
                string text = "%s %s (%s)".printf(id_card.trust_anchor.is_expired() ? "[EXPIRED]" : "",
                                                  id_card.display_name, id_card.nai);
                newtListboxAppendEntry(listbox, text, id_card);

                // select the previously selected ID card, if available
                if (selected_id_card != null && id_card.nai == selected_id_card.nai)
                    newtListboxSetCurrentByKey(listbox, id_card);
            }

            newtFormSetCurrent(form, focus);
            chosen = newtRunForm(form);
            focus = listbox;
            selected_id_card = (IdCard?) newtListboxGetCurrent(listbox);
            bool remember = (newtCheckboxGetValue(remember_chk) == '*');
            if (chosen == add_btn) {
                add_id_card_dialog();
            }
            else if (chosen == edit_btn) {
                edit_id_card_dialog(selected_id_card);
            }
            else if (chosen == import_btn) {
                import_identities_dialog();
            }
            else if (chosen == filter_entry || chosen == filter_btn) {
                filter = newtEntryGetValue(filter_entry);
                focus = filter_entry;
            }
            else if (chosen == remove_btn) {
                delete_id_card_dialog(selected_id_card);
            }
            else if (chosen == send_btn) {
                send_id_card_confirmation_dialog(selected_id_card, remember);
                exit_loop = true;
            }
            else if (chosen == about_btn) {
                about_dialog();
            }
            else if (chosen == listbox) {
                exit_loop = id_card_menu(selected_id_card, request != null, remember);
            }
            else {
                // we need to send NULL identity to gracefully exit properly from the send_identity callback
                send_id_card_confirmation_dialog(null, false);
                exit_loop = true;
            }
        } while (!exit_loop);
        newtFormDestroy(form);
        newtPopWindow();
        newt_finish(finalize);
    }

    public void make_visible()
    {
        select_id_card_dialog();
        if (parent_app.explicitly_launched)
            GLib.Process.exit(0);
    }

    public bool confirm_trust_anchor(IdCard card, TrustAnchorConfirmationRequest request)
    {
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

        bool? result = null;
        do {
            bool must_finish = newt_init();
            newtComponent form, info, yes_btn, no_btn, chosen, comp, view_btn;
            newtCenteredWindow(78, 13 + offset, "Accept trust anchor");
            info = newtTextbox(1, 0, 76, offset, Flag.WRAP);
            newtTextboxSetText(info, warning);
            form = newtForm(null, null, 0);

            comp = newtTextbox(1, offset + 1, 10, 1, 0);
            newtTextboxSetText(comp, "Username:");
            newtFormAddComponent(form, comp);
            comp = newtTextbox(11, offset + 1, 65, 1, 0);
            newtTextboxSetText(comp, request.userid);
            newtTextboxSetColors(comp, Colorset.TITLE, Colorset.TITLE);
            newtFormAddComponent(form, comp);

            comp = newtTextbox(1, offset + 2, 10, 1, 0);
            newtTextboxSetText(comp, "Realm:");
            newtFormAddComponent(form, comp);
            comp = newtTextbox(11, offset + 2, 65, 1, 0);
            newtTextboxSetText(comp, request.realm);
            newtTextboxSetColors(comp, Colorset.TITLE, Colorset.TITLE);
            newtFormAddComponent(form, comp);

            comp = newtTextbox(1, offset + 3, 75, 1, 0);
            newtTextboxSetText(comp, "Server's trust anchor certificate (SHA-256 fingerprint):");
            newtFormAddComponent(form, comp);
            comp = newtTextbox(1, offset + 4, 75, 2, 0);
            newtTextboxSetText(comp, colonize(request.fingerprint, 16));
            newtTextboxSetColors(comp, Colorset.TITLE, Colorset.TITLE);
            newtFormAddComponent(form, comp);

            view_btn = newtCompactButton(0, offset + 6, "View Server Certificate");
            newtFormAddComponent(form, view_btn);

            comp = newtTextbox(1, offset + 8, 75, 3, Flag.WRAP);
            newtTextboxSetText(comp, "Please, check with your realm administrator for the correct fingerprint for your "
                                     + "authentication server. If it matches the above fingerprint, confirm the change. "
                                     + "If not, then cancel.");
            newtFormAddComponent(form, comp);

            yes_btn = newtCompactButton(67, offset + 12, "Confirm");
            no_btn = newtCompactButton(57, offset + 12, "Cancel");

            newtFormAddComponent(form, info);
            newtFormAddComponent(form, no_btn);
            newtFormAddComponent(form, yes_btn);
            newtFormSetCurrent(form, view_btn);
            chosen = newtRunForm(form);
            if (chosen == view_btn)
                info_dialog("View certificate", request.cert_text);
            if (chosen == yes_btn)
                result = true;
            if (chosen == no_btn)
                result = false;
            newtFormDestroy(form);
            newtPopWindow();
            newt_finish(must_finish);
        } while (result == null);
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
        info_dialog("Moonshot project Text UI", "%s\n\n%s".printf(logo, license));
    }

    private void send_id_card_confirmation_dialog(IdCard? id_card, bool remember) {
        IdCard? identity = null;
        if (id_card != null) {
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
}
