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
static const string CANCEL = Stock.CANCEL;
#else
static const string CANCEL = STOCK_CANCEL;
#endif


// For use when exporting certificates.
static string export_directory = null;

class IdentityDialog : Dialog
{
    private static Gdk.Color white = make_color(65535, 65535, 65535);
    private static Gdk.Color selected_color = make_color(0xd9 << 8, 0xf7 << 8, 65535);

    private static MoonshotLogger logger = get_logger("IdentityDialog");

    static const string displayname_labeltext = _("Display Name");
    static const string realm_labeltext = _("Realm");
    static const string username_labeltext = _("Username");
    static const string password_labeltext = _("Password");

    private Entry displayname_entry;
    private Label displayname_label;
    private Entry realm_entry;
    private Label realm_label;
    private Entry username_entry;
    private Label username_label;
    private Entry password_entry;
    private Label password_label;
    private CheckButton remember_checkbutton;
    private Label message_label;
    public bool complete;
    private IdCard card;

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

    internal ArrayList<string> get_services()
    {
        return card.services;
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

        var remember_hbox = new HBox(false, 40);
        remember_hbox.pack_start(new HBox(false, 0), false, false, 0);
        remember_hbox.pack_start(remember_checkbutton, false, false, 0);
        content_area.pack_start(remember_hbox, false, false, 2);

        this.response.connect(on_response);
        content_area.set_border_width(6);

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
        }

        this.set_border_width(6);
        this.set_resizable(false);
        set_bg_color(this);
        this.show_all();
    }

    private Widget make_trust_anchor_box(IdCard id)
    {

        Label ta_label = new Label(_("Trust anchor: ")
                                   + (id.trust_anchor.is_empty() ? _("None") : _("Enterprise provisioned")));
        ta_label.set_alignment(0, 0.5f);

        if (id.trust_anchor.is_empty()) {
            return ta_label;
        }


        AttachOptions fill_and_expand = AttachOptions.EXPAND | AttachOptions.FILL;
        AttachOptions fill = AttachOptions.FILL;

        Table ta_table = new Table(6, 2, false);
        int row = 0;

        var ta_clear_button = new Button.with_label(_("Clear Trust Anchor"));
        ta_clear_button.clicked.connect((w) => {
                clear_trust_anchor = true;
                ta_table.set_sensitive(false);
            }
            );

        ta_table.attach(ta_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 0, 0);
        ta_table.attach(ta_clear_button, 1, 2, row, row + 1, fill, fill, 0, 0);
        row++;

        Label added_label = new Label(_("Added : " + id.trust_anchor.datetime_added));
        added_label.set_alignment(0, 0.5f);
        ta_table.attach(added_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 20, 5);
        row++;

        if (id.trust_anchor.get_anchor_type() == TrustAnchor.TrustAnchorType.SERVER_CERT) {
            Widget fingerprint = make_ta_fingerprint_widget(id.trust_anchor.server_cert);
            // ta_table.attach(fingerprint, 0, 1, row, row + 2, fill_and_expand, fill_and_expand, 5, 5);

            // To make the fingerprint box wider, try:
            ta_table.attach(fingerprint, 0, 2, row, row + 2, fill_and_expand, fill_and_expand, 20, 5);

        }
        else {
            Label ca_cert_label = new Label(_("CA Certificate:"));
            ca_cert_label.set_alignment(0, 0.5f);
            var export_button = new Button.with_label(_("Export Certificate"));
            //!!TODO!
            export_button.clicked.connect((w) => {export_certificate(id);});

            ta_table.attach(ca_cert_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 20, 0);
            ta_table.attach(export_button, 1, 2, row, row + 1, fill, fill, 0, 0);
            row++;

            //!!TODO: When to show Subject, and when (if ever) show Subject-Altname here?
            Label subject_label = new Label(_("Subject: ") + id.trust_anchor.subject);
            subject_label.set_alignment(0, 0.5f);
            ta_table.attach(subject_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 40, 5);
            row++;

            Label expiration_label = new Label(_("Expiration date: ") + id.trust_anchor.get_expiration_date());
            expiration_label.set_alignment(0, 0.5f);
            ta_table.attach(expiration_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 40, 5);
            row++;

            //!!TODO: What *is* this?
            Label constraint_label = new Label(_("Constraint: "));
            constraint_label.set_alignment(0, 0.5f);
            ta_table.attach(constraint_label, 0, 1, row, row + 1, fill_and_expand, fill_and_expand, 20, 0);
            row++;
        }

        return ta_table;

    }

    private static void add_as_vbox(Box content_area, Label label, Entry entry)
    {
        VBox vbox = new VBox(false, 2);

        vbox.pack_start(label, false, false, 0);
        vbox.pack_start(entry, false, false, 0);

        // Hack to prevent the text entries from stretching horizontally
        HBox hbox = new HBox(false, 0);
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

    private VBox make_services_vbox()
    {
        logger.trace("make_services_vbox");

        var services_vbox_alignment = new Alignment(0, 0, 1, 0);
        var services_vscroll = new ScrolledWindow(null, null);
        services_vscroll.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        services_vscroll.set_shadow_type(ShadowType.IN);
        services_vscroll.set_size_request(0, 60);
        services_vscroll.add_with_viewport(services_vbox_alignment);

#if VALA_0_12
        var remove_button = new Button.from_stock(Stock.REMOVE);
#else
        var remove_button = new Button.from_stock(STOCK_REMOVE);
#endif
        remove_button.set_sensitive(false);


        var services_table = new Table(card.services.size, 1, false);
        services_table.set_row_spacings(1);
        services_table.set_col_spacings(0);
        set_bg_color(services_table);

        var table_button_hbox = new HBox(false, 6);
        table_button_hbox.pack_start(services_vscroll, true, true, 4);

        // Hack to prevent the button from growing vertically
        VBox fixed_height = new VBox(false, 0);
        fixed_height.pack_start(remove_button, false, false, 0);
        table_button_hbox.pack_start(fixed_height, false, false, 0);

        // A table doesn't have a background color, so put it in an EventBox, and
        // set the EventBox's background color instead.
        EventBox table_bg = new EventBox();
        set_bg_color(table_bg);
        table_bg.add(services_table);
        services_vbox_alignment.add(table_bg);

        var services_vbox_title = new Label(_("Services:"));
        services_vbox_title.set_alignment(0, 0.5f);

        var services_vbox = new VBox(false, 6);
        services_vbox.pack_start(services_vbox_title, false, false, 0);
        services_vbox.pack_start(table_button_hbox, true, true, 0);

        int i = 0;
        foreach (string service in card.services)
        {
            var label = new Label(service);
            label.set_alignment((float) 0, (float) 0);
            label.xpad = 3;

            EventBox event_box = new EventBox();
            event_box.modify_bg(StateType.NORMAL, white);
            event_box.add(label);
            event_box.button_press_event.connect(() =>
                {
                    var state = label.get_state();
                    logger.trace("button_press_callback: Label state=" + state.to_string() + " setting bg to " + white.to_string());

                    if (selected_item == label)
                    {
                        // Deselect
                        selected_item.parent.modify_bg(state, white);
                        selected_item = null;
                        remove_button.set_sensitive(false);
                    }
                    else
                    {
                        if (selected_item != null)
                        {
                            // Deselect
                            selected_item.parent.modify_bg(state, white);
                            selected_item = null;
                        }

                        // Select
                        selected_item = label;
                        selected_item.parent.modify_bg(state, selected_color);
                        remove_button.set_sensitive(true);
                    }
                    return false;
                });

            services_table.attach_defaults(event_box, 0, 1, i, i+1);
            i++;
        }

        remove_button.clicked.connect((remove_button) =>
            {
                var result = WarningDialog.confirm(this,
                                                   Markup.printf_escaped(
                                                       "<span font-weight='heavy'>You are about to remove the service '%s'.</span>",
                                                       selected_item.label)
                                                   + "\n\nAre you sure you want to do this?",
                                                   "delete_service");

                if (result)
                {
                    if (card != null) {
                        card.services.remove(selected_item.label);
                        services_table.remove(selected_item.parent);
                        selected_item = null;
                        remove_button.set_sensitive(false);
                    }
                }

            });

        return services_vbox;
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

            const string CERT_HEADER = "-----BEGIN CERTIFICATE-----\n";
            const string CERT_FOOTER = "\n-----END CERTIFICATE-----\n";

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
            var stream = file.replace(null, false, FileCreateFlags.PRIVATE);
            stream.write(newcert.data);

            // Save the parent directory to use as default for next save
            export_directory = file.get_parent().get_path();
        }
        dialog.destroy();
    }
}
