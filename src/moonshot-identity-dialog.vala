/*
 * Copyright (c) 2016, JANET(UK)
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

// Defined here as workaround for emacs vala-mode indentation failure.
#if VALA_0_12
const string CANCEL = Stock.CANCEL;
#else
const string CANCEL = STOCK_CANCEL;
#endif

extern int parse_der_certificate(char* der, int der_len, char* cert_text, int cert_text_len);


// For use when exporting certificates.
static string export_directory = null;

class IdentityDialog : Dialog
{
    private static Gdk.Color white = make_color(65535, 65535, 65535);
    private static Gdk.Color selected_color = make_color(0xd9 << 8, 0xf7 << 8, 65535);

    private static MoonshotLogger logger = get_logger("IdentityDialog");

    const string displayname_labeltext = _("Display Name");
    const string realm_labeltext = _("Realm");
    const string username_labeltext = _("Username");
    const string password_labeltext = _("Password");

    private Entry displayname_entry;
    private Label displayname_label;
    private Entry realm_entry;
    private Label realm_label;
    private Entry username_entry;
    private Label username_label;
    private Entry password_entry;
    private Label password_label;
    private CheckButton remember_checkbutton;
    private CheckButton mfa_checkbutton;
    private Label message_label;
    public bool complete;
    private IdCard card;
    private Gee.List<string> services;

    private Label selected_item = null;

    // Whether to clear the card's TrustAnchor after the user selects OK
    internal bool clear_trust_anchor = false;

    public string display_name {
        get { return displayname_entry.get_text(); }
    }

    public string issuer {
        get { return realm_entry.get_text(); }
    }

    public string username {
        get { return username_entry.get_text(); }
    }

    public string password {
        get { return password_entry.get_text(); }
    }

    public bool store_password {
        get { return remember_checkbutton.active; }
    }

    public bool has_2fa {
        get { return mfa_checkbutton.active; }
    }

    /**
     * Don't leave passwords in memory longer than necessary.
     * This may not actually erase the password data bytes, but it seems to be the best we can do.
     */
    public void clear_password() {
        clear_password_entry(password_entry);
    }

    internal Gee.List<string> get_services()
    {
        return services;
    }

    public IdentityDialog(IdentityManagerView parent)
    {
        this.with_idcard(null, _("Add ID Card"), parent);
    }

    public IdentityDialog.with_idcard(IdCard? a_card, string title, IdentityManagerView parent)
    {
        bool is_new_card = false;
        if (a_card == null)
        {
            is_new_card = true;
        }

        card = a_card ?? new IdCard();
        this.set_title(title);
        this.set_modal(true);
        this.set_transient_for(parent);

        this.add_buttons(CANCEL, ResponseType.CANCEL, _("OK"), ResponseType.OK);
        Box content_area = (Box) this.get_content_area();

        displayname_label = new Label(@"$displayname_labeltext:");
        displayname_label.set_alignment(0, (float) 0.5);
        displayname_entry = new Entry();
        displayname_entry.set_text(card.display_name);
        displayname_entry.set_width_chars(40);

        realm_label = new Label(@"$realm_labeltext:");
        realm_label.set_alignment(0, (float) 0.5);
        realm_entry = new Entry();
        realm_entry.set_text(card.issuer);
        realm_entry.set_width_chars(60);

        username_label = new Label(@"$username_labeltext:");
        username_label.set_alignment(0, (float) 0.5);
        username_entry = new Entry();
        username_entry.set_text(card.username);
        username_entry.set_width_chars(40);

        password_label = new Label(@"$password_labeltext:");
        password_label.set_alignment(0, (float) 0.5);

        remember_checkbutton = new CheckButton.with_label(_("Remember password"));
        remember_checkbutton.active = card.store_password;

        mfa_checkbutton = new CheckButton.with_label(_("Requires 2FA"));
        mfa_checkbutton.active = card.has_2fa;

        password_entry = new Entry();
        password_entry.set_invisible_char('*');
        password_entry.set_visibility(false);
        password_entry.set_width_chars(40);
        password_entry.set_text(card.password);

        message_label = new Label("");
        message_label.set_visible(false);

        set_atk_relation(displayname_label, displayname_entry, Atk.RelationType.LABEL_FOR);
        set_atk_relation(realm_label, realm_entry, Atk.RelationType.LABEL_FOR);
        set_atk_relation(username_label, username_entry, Atk.RelationType.LABEL_FOR);
        set_atk_relation(password_label, password_entry, Atk.RelationType.LABEL_FOR);

        content_area.pack_start(message_label, false, false, 6);
        add_as_vbox(content_area, displayname_label, displayname_entry);
        add_as_vbox(content_area, username_label, username_entry);
        add_as_vbox(content_area, realm_label, realm_entry);
        add_as_vbox(content_area, password_label, password_entry);

        var remember_hbox = new_hbox(40);
        remember_hbox.pack_start(new_hbox(0), false, false, 0);
        remember_hbox.pack_start(remember_checkbutton, false, false, 0);
        remember_hbox.pack_start(mfa_checkbutton, false, false, 0);
        content_area.pack_start(remember_hbox, false, false, 2);

        this.response.connect(on_response);
        content_area.set_border_width(6);

        this.services = new ArrayList<string>();
        this.services.add_all(card.services);

        if (!is_new_card)
        {
            Widget trust_anchor_box = make_trust_anchor_box(card);
            content_area.pack_start(trust_anchor_box, false, false, 15);

            var services_vbox = make_services_vbox();
            content_area.pack_start(services_vbox);
            var services_vbox_bottom_spacer = new Alignment(0, 0, 0, 0);
            services_vbox_bottom_spacer.set_size_request(0, 12);
            content_area.pack_start(services_vbox_bottom_spacer, false, false, 0);
        }

        if (card.is_no_identity())
        {
            displayname_entry.set_sensitive(false);
            realm_entry.set_sensitive(false);
            username_entry.set_sensitive(false);
            password_entry.set_sensitive(false);
            remember_checkbutton.set_sensitive(false);
            mfa_checkbutton.set_sensitive(false);
        }

        this.destroy.connect(() => {
                logger.trace("Destroying IdentityDialog; clearing its password.");
                this.clear_password();
            });


        this.set_border_width(6);
        this.set_resizable(false);
        set_bg_color(this);
        this.show_all();
    }

    private Widget make_trust_anchor_box(IdCard id)
    {

        int nrows = 7;
        int ncolumns = 2;
        string ta_label_prefix = _("Trust anchor: ");
        string none = _("None");

        Box trust_anchor_box = new_hbox(0);
        string ta_label_text = ta_label_prefix + IdentityManagerInterface.ta_type_name(id);

        Label ta_label = new Label(ta_label_text);
        ta_label.set_alignment(0, 0.5f);

        if (id.trust_anchor.is_empty()) {
            trust_anchor_box.pack_start(ta_label, false, false, 0);
            return trust_anchor_box;
        }


        AttachOptions fill_and_expand = AttachOptions.EXPAND | AttachOptions.FILL;
        AttachOptions fill = AttachOptions.FILL;

        Table ta_table = new Table(nrows, ncolumns, false);
        int row = 0;

        var ta_clear_button = new Button.with_label(_("Clear Trust Anchor"));
        ta_clear_button.clicked.connect((w) => {
                var result = WarningDialog.confirm(this,
                                                   Markup.printf_escaped(
                                                       "<span font-weight='heavy'>"
                                                       + _("You are about to clear the trust anchor fingerprint for '%s'.")
                                                       + "</span>",
                                                       id.display_name)
                                                   + _("\n\nAre you sure you want to do this?"),
                                                   "clear_trust_anchor");

                if (result)
                {
                    clear_trust_anchor = true;

                    // Clearing the trust_anchor_box's children, and then re-packing
                    // a label into it, doesn't seem to work. Instead, let's clear out
                    // the table's children, and then re-insert a label into it.
                    var children = ta_table.get_children();
                    foreach (var child in children) {
                        ta_table.remove(child);
                    }

                    ta_table.resize(1, ncolumns);
                    ta_label.set_text(ta_label_prefix + none);
                    ta_table.attach(ta_label, 0, 1, 0, 1,
                                    fill_and_expand, fill_and_expand, 0, 0);

                }
            }
            );

        ta_table.attach(ta_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 0, 0);
        ta_table.attach(ta_clear_button, 1, 2, row, row + 1, fill, fill, 0, 0);
        row++;

        Label added_label = new Label(_("Added: " + id.trust_anchor.datetime_added));
        added_label.set_alignment(0, 0.5f);
        ta_table.attach(added_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 20, 5);
        row++;

        if (id.trust_anchor.get_anchor_type() == TrustAnchor.TrustAnchorType.SERVER_CERT) {
            Widget fingerprint = make_ta_fingerprint_widget(id.trust_anchor.server_cert);
            ta_table.attach(fingerprint, 0, 2, row, row + 2, fill_and_expand, fill_and_expand, 20, 5);
        }
        else {
            if (id.trust_anchor.subject != "") {
                Label subject_label = new Label(_("Subject: ") + id.trust_anchor.subject);
                subject_label.set_alignment(0, 0.5f);
                subject_label.set_line_wrap(true);
                subject_label.set_size_request(400, -1);
                ta_table.attach(subject_label, 0, 2, row, row + 1, fill_and_expand, fill_and_expand, 20, 5);
                row++;
            }

            if (id.trust_anchor.subject_alt != "") {
                Label subject_alt_label = new Label(_("Subject-Alt: ") + id.trust_anchor.subject_alt);
                subject_alt_label.set_alignment(0, 0.5f);
                subject_alt_label.set_line_wrap(true);
                subject_alt_label.set_size_request(400, -1);
                ta_table.attach(subject_alt_label, 0, 2, row, row + 1, fill_and_expand, fill_and_expand, 20, 5);
                row++;
            }

            Label expiration_label = new Label(_("Expiration date: ") + id.trust_anchor.get_expiration_date());
            expiration_label.set_alignment(0, 0.5f);
            ta_table.attach(expiration_label, 0, 2, row, row + 1, fill_and_expand, fill_and_expand, 20, 5);
            row++;

            var export_button = new Button.with_label(_("Export CA Certificate"));
            var view_button = new Button.with_label(_("View CA Certificate"));
            export_button.clicked.connect((w) => {export_certificate(id);});
            view_button.clicked.connect((w) => {view_certificate(id);});
            ta_table.attach(view_button, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 20, 0);
            ta_table.attach(export_button, 1, 2, row, row + 1, fill, fill, 0, 0);
            row++;


            //!!TODO: What goes here?
            // Label constraint_label = new Label(_("Constraint: "));
            // constraint_label.set_alignment(0, 0.5f);
            // ta_table.attach(constraint_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 20, 0);
            // row++;
        }

        trust_anchor_box.pack_start(ta_table, false, false, 0);
        return trust_anchor_box;
    }

    private static void add_as_vbox(Box content_area, Label label, Entry entry)
    {
        Box vbox = new_vbox(2);

        vbox.pack_start(label, false, false, 0);
        vbox.pack_start(entry, false, false, 0);

        // Hack to prevent the text entries from stretching horizontally
        Box hbox = new_hbox(0);
        hbox.pack_start(vbox, false, false, 0);
        content_area.pack_start(hbox, false, false, 6);
    }

    private static string update_preamble(string preamble)
    {
        if (preamble == "")
            return _("Missing required field: ");
        return _("Missing required fields: ");
    }

    private static string update_message(string old_message, string new_item)
    {
        string message;
        if (old_message == "")
            message = new_item;
        else
            message = old_message + ", " + new_item;
        return message;
    }

    private static void check_field(string field, Label label, string fieldname, ref string preamble, ref string message)
    {
        if (field != "") {
            label.set_markup(@"$fieldname:");
            return;
        }
        label.set_markup(@"<span foreground=\"red\">$fieldname:</span>");
        preamble = update_preamble(preamble);
        message = update_message(message, fieldname);
    }

    private bool check_fields()
    {
        string preamble = "";
        string message = "";
        string password_test = store_password ? password : "not required";
        if (!card.is_no_identity())
        {
            check_field(display_name, displayname_label, displayname_labeltext, ref preamble, ref message);
            check_field(username, username_label, username_labeltext, ref preamble, ref message);
            check_field(issuer, realm_label, realm_labeltext, ref preamble, ref message);
            check_field(password_test, password_label, password_labeltext, ref preamble, ref message);
        }
        if (message != "") {
            message_label.set_visible(true);
            message_label.set_markup(@"<span foreground=\"red\">$preamble$message</span>");
            return false;
        }
        return true;
    }

    private void on_response(Dialog source, int response_id)
    {
        switch (response_id) {
        case ResponseType.OK:
            complete = check_fields();
            break;
        case ResponseType.CANCEL:
            complete = true;
            break;
        }
    }

    private void refresh_services_model(Gtk.ListStore model, Label label) {
        label.set_text(_("Services: (%d)").printf(services.size));
        model.clear();
        foreach (string service in services)
            model.insert_with_values(null, -1, 0, service, -1);
    }

    private Box make_services_vbox()
    {
        logger.trace("make_services_vbox");

        var services_vbox_alignment = new Alignment(0, 0, 1, 0);
        var services_vscroll = new ScrolledWindow(null, null);
        services_vscroll.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        services_vscroll.set_shadow_type(ShadowType.IN);
        services_vscroll.set_size_request(0, 100);
        services_vscroll.add_with_viewport(services_vbox_alignment);

#if VALA_0_12
        var remove_button = new Button.from_stock(Stock.REMOVE);
        var add_button = new Button.from_stock(Stock.ADD);
#else
        var remove_button = new Button.from_stock(STOCK_REMOVE);
        var add_button = new Button.from_stock(STOCK_ADD);
#endif

        var services_model = new Gtk.ListStore (1, typeof (string));
        var services_view = new Gtk.TreeView();
        services_view.set_model(services_model);
        services_view.headers_visible = false;
        var cell = new Gtk.CellRendererText();
        services_view.insert_column_with_attributes (-1, "Services", cell, "text", 0);

        var table_button_hbox = new_hbox(6);
        table_button_hbox.pack_start(services_vscroll, true, true, 4);

        // Hack to prevent the button from growing vertically
        Box fixed_height = new_vbox(0);
        fixed_height.pack_start(add_button, false, false, 0);
        fixed_height.pack_start(remove_button, false, false, 0);
        table_button_hbox.pack_start(fixed_height, false, false, 0);

        services_vbox_alignment.add(services_view);

        var services_vbox_title = new Label(_("Services:"));
        services_vbox_title.set_alignment(0, 0.5f);

        var services_vbox = new_vbox(6);
        services_vbox.pack_start(services_vbox_title, false, false, 0);
        services_vbox.pack_start(table_button_hbox, true, true, 0);

        refresh_services_model(services_model, services_vbox_title);
        remove_button.clicked.connect((remove_button) =>
            {
                Gtk.TreeIter iter;
                string service = null;
                var selection = services_view.get_selection();
                if (selection.get_selected(null, out iter)) {
                    services_model.get(iter, 0, out service);
                    var result = WarningDialog.confirm(this,
                                                   Markup.printf_escaped(
                                                       "<span font-weight='heavy'>"
                                                       + _("You are about to remove the service\n'%s'.")
                                                       + "</span>",
                                                       service)
                                                   + _("\n\nAre you sure you want to do this?"),
                                                   "delete_service");

                    if (result && card != null) {
                        services.remove(service);
                        refresh_services_model(services_model, services_vbox_title);
                    }
                }
            });

        add_button.clicked.connect((add_button) => {
            var dialog = new AddServiceDialog(this);
            var result = dialog.run();
            var service = dialog.service;
            if (result == ResponseType.OK && service != "") {
                services.add(service);
                refresh_services_model(services_model, services_vbox_title);
            }
            dialog.destroy();
        });

        return services_vbox;
    }

    private void view_certificate(IdCard id)
    {
        uint8 cert_info[4096];
        uint8[] der_cert = Base64.decode(id.trust_anchor.ca_cert);
        string message = "Could not load certificate!";
        int rv = parse_der_certificate(der_cert, der_cert.length, cert_info, 4096);
        if (rv == 1)
            message = (string) cert_info;
        var dialog = new Gtk.MessageDialog(this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                           Gtk.MessageType.INFO, Gtk.ButtonsType.OK,
                                           "The following is the information extracted from the CA certificate for this Trust Anchor.");
        Box content = (Box) dialog.get_content_area();
        content.add(make_ta_fingerprint_widget(message, "", false, 400, true));
        dialog.set_size_request(700, -1);
        dialog.show_all();
        dialog.run();
        dialog.destroy();
    }

    private void export_certificate(IdCard id)
    {
        var dialog = new FileChooserDialog("Save File",
                                           this,
                                           FileChooserAction.SAVE,
                                           _("Cancel"),ResponseType.CANCEL,
                                           _("Save"), ResponseType.ACCEPT,
                                           null);
        dialog.set_do_overwrite_confirmation(true);
        if (export_directory != null) {
            dialog.set_current_folder(export_directory);
        }
        // Remove slashes from the default filename.
        string default_filename =
            (id.display_name + ".pem").replace(Path.DIR_SEPARATOR_S, "_");
        dialog.set_current_name(default_filename);
        if (dialog.run() == ResponseType.ACCEPT)
        {
            // Export the certificate in PEM format.
            string CERT_HEADER = "-----BEGIN CERTIFICATE-----\n";
            string CERT_FOOTER = "\n-----END CERTIFICATE-----\n";

            // Strip any embedded newlines in the certificate...
            string cert = id.trust_anchor.ca_cert.replace("\n", "");

            // Re-embed newlines every 64 chars.
            string newcert = CERT_HEADER;
            while (cert.length > 63) {
                newcert += cert[0:64];
                newcert += "\n";
                cert = cert[64:cert.length];
            }
            if (cert.length > 0) {
                newcert += cert;
            }
            newcert += CERT_FOOTER;

            string filename = dialog.get_filename();
            var file  = File.new_for_path(filename);
#if VALA_0_12
            try {
                var stream = file.replace(null, false, FileCreateFlags.PRIVATE);
	           // Not sure if this works in 12; it definitely doesn't work in 10.
                stream.write(newcert.data);
            }
            catch (Error e) {
                logger.error("Error exporting certificate");
            }
#else
            var stream = FileStream.open(filename, "wb");
            stream.printf(newcert);
            stream.flush();
#endif
            // Save the parent directory to use as default for next save
            export_directory = file.get_parent().get_path();
        }
        dialog.destroy();
    }
}
