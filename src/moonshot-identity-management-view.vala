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

public class IdentityManagerView : Window, IdentityManagerInterface {
    static MoonshotLogger logger = get_logger("IdentityManagerView");

    bool use_flat_file_store = false;

    // The latest year in which Moonshot sources were modified.
    private static int LATEST_EDIT_YEAR = 2019;

    private const int WINDOW_WIDTH = 700;
    private const int WINDOW_HEIGHT = 500;
    protected IdentityManagerApp parent_app;
    private UIManager ui_manager = new UIManager();
    private Entry search_entry;
    private CustomVBox custom_vbox;
    private Box service_prompt_vbox;
    private Button edit_button;
    private Button remove_button;

    private Button send_button;

    private Gtk.ListStore* listmodel;
    private TreeModelFilter filter;

    private Gtk.Label statusbar;

    internal IdentityManagerModel identities_manager;
    private unowned SList<IdCard> candidates;

    private GLib.Queue<IdentityRequest> request_queue;

    internal CheckButton remember_identity_binding = null;

    private IdCard selected_card = null;

    private string import_directory = null;
    private Gtk.ComboBox modebox = null;

    private enum Columns
    {
        IDCARD_COL,
        LOGO_COL,
        ISSUER_COL,
        USERNAME_COL,
        PASSWORD_COL,
        N_COLUMNS
    }

    private const string menu_layout =
    "<menubar name='MenuBar'>" +
    "        <menu name='HelpMenu' action='HelpMenuAction'>" +
    "             <menuitem name='About' action='AboutAction' />" +
    "        </menu>" +
    "</menubar>";

    public IdentityManagerView(IdentityManagerApp app, bool use_flat_file_store) {
        parent_app = app;
        this.use_flat_file_store = use_flat_file_store;

        identities_manager = parent_app.model;
        request_queue = new GLib.Queue<IdentityRequest>();
        this.title = _("Moonshot Identity Selector");
        this.set_position(WindowPosition.CENTER);
        set_default_size(WINDOW_WIDTH, WINDOW_HEIGHT);
        setup_list_model();
        build_ui();
        load_id_cards();
        connect_signals();
        report_duplicate_nais(identities_manager);
        report_expired_trust_anchors(identities_manager);
    }

    public void info_dialog(string title, string msg)
    {
        var msg_dialog = new Gtk.MessageDialog(this,
                                               Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                               Gtk.MessageType.INFO,
                                               Gtk.ButtonsType.OK,
                                               "%s",
                                               msg);
        msg_dialog.run();
        msg_dialog.destroy();
    }

    private void on_card_list_changed() {
        logger.trace("on_card_list_changed");
        load_id_cards();
    }

    public bool confirm_trust_anchor(IdCard card, TrustAnchorConfirmationRequest request)
    {
        var dialog = new TrustAnchorDialog(card, request);
        var response = dialog.run();
        dialog.destroy();
        return (response == ResponseType.OK);
    }

    private bool visible_func(TreeModel model, TreeIter iter)
    {
        IdCard? id_card;

        model.get(iter, Columns.IDCARD_COL, out id_card);

        string entry_text = search_entry.get_text();

        return id_matches_search(id_card, entry_text, candidates);
    }

    private void setup_list_model()
    {
        this.listmodel = new Gtk.ListStore(Columns.N_COLUMNS, typeof(IdCard),
                                           typeof(Gdk.Pixbuf),
                                           typeof(string),
                                           typeof(string),
                                           typeof(string));
        this.filter = new TreeModelFilter(listmodel, null);

        filter.set_visible_func(visible_func);
    }

    private void search_entry_text_changed_cb()
    {
        this.filter.refilter();
        redraw_id_card_widgets();
    }

    private bool search_entry_key_press_event_cb(Gdk.EventKey e)
    {
        if(Gdk.keyval_name(e.keyval) == "Escape")
            this.search_entry.set_text("");

        // Continue processing this event, since the
        // text entry functionality needs to see it too.
        return false;
    }

    private void load_id_cards() {
        logger.trace("load_id_cards");

        custom_vbox.clear();
        this.listmodel->clear();
        Gee.List<IdCard> card_list = identities_manager.get_card_list();
        if (card_list == null) {
            return;
        }

        foreach (IdCard id_card in card_list) {
            logger.trace(@"load_id_cards: Loading card with display name '$(id_card.display_name)'");
            add_id_card_data(id_card);
            add_id_card_widget(id_card);
        }
    }

    private IdCard update_id_card_data(IdentityDialog dialog, IdCard id_card)
    {
        id_card.display_name = dialog.display_name;
        id_card.issuer = dialog.issuer;
        id_card.username = dialog.username;
        id_card.password = dialog.password;
        id_card.store_password = dialog.store_password;
        id_card.has_2fa = dialog.has_2fa;

        id_card.update_services_from_list(dialog.get_services());

        if (dialog.clear_trust_anchor) {
            id_card.clear_trust_anchor();
        }

        return id_card;
    }

    private void add_id_card_data(IdCard id_card)
    {
        TreeIter   iter;
        Gdk.Pixbuf pixbuf;
        this.listmodel->append(out iter);
        pixbuf = get_pixbuf(id_card);
        listmodel->set(iter,
                       Columns.IDCARD_COL, id_card,
                       Columns.LOGO_COL, pixbuf,
                       Columns.ISSUER_COL, id_card.issuer,
                       Columns.USERNAME_COL, id_card.username,
                       Columns.PASSWORD_COL, id_card.password);
    }

    private void add_id_card_widget(IdCard id_card)
    {
        if (id_card == null) {
            logger.trace("add_id_card_widget: id_card == null; returning.");
            return;
        }

        logger.trace("add_id_card_widget: id_card.nai='%s'; selected nai='%s'"
                     .printf(id_card.nai,
                             this.selected_card == null ? "[null selection]" : this.selected_card.nai));


        var id_card_widget = new IdCardWidget(id_card, this);
        this.custom_vbox.add_id_card_widget(id_card_widget);
        id_card_widget.expanded.connect(this.widget_selected_cb);
        id_card_widget.collapsed.connect(this.widget_unselected_cb);
        id_card_widget.edited.connect(this.widget_edit_cb);
        id_card_widget.removed.connect(this.widget_remove_cb);

        if (this.selected_card != null && this.selected_card.nai == id_card.nai) {
            logger.trace(@"add_id_card_widget: Expanding selected idcard widget");
            id_card_widget.show_details();

            // After a card is added, modified, or deleted, we reload all the cards.
            // (I'm not sure why, or if it's necessary to do this.) This means that the
            // selected_card may now point to a card instance that's not in the current list.
            // Hence the only way to carry the selection across reloads is to identify
            // the selected card by its NAI. And hence we need to reset what our idea of the
            // "selected card" is.
            // There should be a better way to do this, especially since we're not great
            // at preventing duplicate NAIs.
            this.selected_card = id_card;
        }
    }

    private void widget_edit_cb(IdCardWidget id_card_widget)
    {
        this.edit_identity_cb(id_card_widget.id_card);
    }

    private void widget_remove_cb(IdCardWidget id_card_widget)
    {
        this.remove_identity_cb(id_card_widget.id_card);
    }

    private void widget_selected_cb(IdCardWidget id_card_widget)
    {
        logger.trace(@"widget_selected_cb: id_card_widget.id_card.display_name='$(id_card_widget.id_card.display_name)'");

        this.selected_card = id_card_widget.id_card;
        bool allow_removes = !id_card_widget.id_card.is_no_identity();
        this.remove_button.set_sensitive(allow_removes);
        this.edit_button.set_sensitive(true);
        this.custom_vbox.receive_expanded_event(id_card_widget);

        if (this.selection_in_progress())
             this.send_button.set_sensitive(true);
    }

    private void widget_unselected_cb(IdCardWidget id_card_widget)
    {
        logger.trace(@"widget_unselected_cb: id_card_widget.id_card.display_name='$(id_card_widget.id_card.display_name)'");

        this.selected_card = null;
        this.remove_button.set_sensitive(false);
        this.edit_button.set_sensitive(false);
        this.custom_vbox.receive_collapsed_event(id_card_widget);

        this.send_button.set_sensitive(false);
    }

    public bool yesno_dialog(string title, string message, bool default_yes)
    {
        var dialog = new Gtk.MessageDialog(this,
                                       Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                       Gtk.MessageType.QUESTION,
                                       Gtk.ButtonsType.YES_NO,
                                       "%s", message);
        var ret = dialog.run();
        dialog.destroy();
        return (ret == Gtk.ResponseType.YES);
    }

    private void add_identity_cb()
    {
        var dialog = new IdentityDialog(this);
        int result = ResponseType.CANCEL;
        while (!dialog.complete)
            result = dialog.run();

        switch (result) {
        case ResponseType.OK:
            this.identities_manager.add_card(update_id_card_data(dialog, new IdCard()), false);
            break;
        default:
            break;
        }
        dialog.destroy();
    }

    private void edit_identity_cb(IdCard card)
    {
        var dialog = new IdentityDialog.with_idcard(card, _("Edit Identity"), this);
        int result = ResponseType.CANCEL;
        while (!dialog.complete)
            result = dialog.run();

        switch (result) {
        case ResponseType.OK:
            this.identities_manager.update_card(update_id_card_data(dialog, card));

            // Make sure we haven't created a duplicate NAI via this update.
            report_duplicate_nais(identities_manager);
            break;
        default:
            break;
        }
        dialog.destroy();
    }

    private void remove_identity(IdCard id_card)
    {
        logger.trace(@"remove_identity: id_card.display_name='$(id_card.display_name)'");

        this.selected_card = null;
        this.identities_manager.remove_card(id_card);

        // Nothing is selected, so disable buttons
        this.edit_button.set_sensitive(false);
        this.remove_button.set_sensitive(false);
        this.send_button.set_sensitive(false);
    }

    private void redraw_id_card_widgets()
    {
        TreeIter iter;
        IdCard id_card;

        this.custom_vbox.clear();

        if (filter.get_iter_first(out iter))
        {
            do
            {
                filter.get(iter,
                           Columns.IDCARD_COL, out id_card);

                add_id_card_widget(id_card);
            }
            while (filter.iter_next(ref iter));
        }
    }

    private void refresh_status() {
        statusbar.set_markup(_("Using <b>%s</b> backend. Mode is <b>%s</b>".printf(
            this.identities_manager.get_store_name(), parent_app.get_mode().to_string())));
    }

    private void mode_changed_cb() {
#if VALA_0_12
        var ok = Stock.OK;
        var cancel = Stock.CANCEL;
#else
        var ok = STOCK_OK;
        var cancel = STOCK_CANCEL;
#endif
        var dialog = new Gtk.Dialog.with_buttons("Set mode", this, DialogFlags.MODAL,
                                                  cancel, ResponseType.CANCEL, ok, ResponseType.OK, null);
        unowned Box content_area = (Box) dialog.get_content_area ();
        var box = new_vbox(6);
        content_area.pack_start (box);
        var label = new Gtk.Label ("Select the UI mode:");
        box.add(label);

        UiMode mode = parent_app.get_mode();
        string new_mode = mode.to_string();

        unowned SList<RadioButton>? group = null;
        foreach (UiMode x in UiMode.all()) {
            var radiobutton = new RadioButton.with_label(group, x.to_string());
            group = radiobutton.get_group();
            radiobutton.set_label(x.to_string());
            radiobutton.toggled.connect( (radio) => {new_mode = radio.label;});
            box.add(radiobutton);
            if (mode == x)
                radiobutton.active = true;
        }

        dialog.show_all();
        int response = dialog.run();
        dialog.destroy();

        if (response == ResponseType.OK && mode.to_string() != new_mode) {
            change_mode(new_mode);
            refresh_status();
        }

    }

    private void remove_identity_cb(IdCard id_card)
    {
        bool remove = WarningDialog.confirm(this,
                                            Markup.printf_escaped(
                                                "<span font-weight='heavy'>" + _("You are about to remove the identity '%s'.") + "</span>",
                                                id_card.display_name)
                                            + "\n\n" + _("Are you sure you want to do this?"),
                                            "delete_idcard");
        if (remove)
            remove_identity(id_card);
    }

    private void set_prompting_service(string service)
    {
        clear_selection_prompts();

        var prompting_service = new Label(null);
        prompting_service.set_markup(_("Identity requested for service: \n  <b>%s</b>").printf(service));
        // left-align
        prompting_service.set_alignment(0, (float )0.5);
        prompting_service.set_padding(12, 6);

        this.service_prompt_vbox.pack_start(prompting_service, false, false, 0);
        this.service_prompt_vbox.show_all();
    }

    private void clear_selection_prompts()
    {
        var list = service_prompt_vbox.get_children();
        foreach (Widget w in list)
        {
            service_prompt_vbox.remove(w);
        }
    }


    public void queue_identity_request(IdentityRequest request)
    {
        bool queue_was_empty = !this.selection_in_progress();
        this.request_queue.push_tail(request);

        if (queue_was_empty)
        { /* setup widgets */
            candidates = request.candidates;
            filter.refilter();
            redraw_id_card_widgets();
            set_prompting_service(request.service);
            remember_identity_binding.show();

            if (this.custom_vbox.find_idcard_widget(this.selected_card) != null) {
                // A widget is already selected, and has not been filtered out of the display via search
                send_button.set_sensitive(true);
            }

            make_visible();
        }
    }


    /** Makes the window visible, or at least, notifies the user that the window
     * wants to be visible.
     *
     * This differs from show() in that show() does not guarantee that the
     * window will be moved to the foreground. Actually, neither does this
     * method, because the user's settings and window manager may affect the
     * behavior significantly.
     */
    public void make_visible()
    {
        set_urgency_hint(true);
        present();
    }

    private string? password_dialog(string title, string text, bool show_remember, out bool remember)
    {
        var dialog = new AddPasswordDialog(text, show_remember);
        var result = dialog.run();
        remember = dialog.remember;
        string passwd = dialog.password;
        dialog.clear_password();
        dialog.destroy();
        if (result != ResponseType.OK || passwd == "") {
            return null;
        }
        return passwd;
    }

    private void send_identity_cb(IdCard id)
    {
        return_if_fail(this.selection_in_progress());

        var request = this.request_queue.pop_head();
        var identity = check_add_password(id, request, identities_manager);
        send_button.set_sensitive(false);

        candidates = null;

        if (!this.selection_in_progress())
        {
            candidates = null;
            clear_selection_prompts();
            if (!parent_app.explicitly_launched) {
// The following occasionally causes the app to exit without sending the dbus
// reply, so for now we just don't exit
//                Gtk.main_quit();
// just hide instead
                this.hide();
            }
        } else {
            IdentityRequest next = this.request_queue.peek_head();
            candidates = next.candidates;
            set_prompting_service(next.service);
        }
        filter.refilter();
        redraw_id_card_widgets();

        if ((identity != null) && (!identity.is_no_identity()))
            parent_app.default_id_card = identity;

        request.return_identity(identity, remember_identity_binding.active);

        remember_identity_binding.active = true;
        remember_identity_binding.hide();
    }

    private void on_about_action()
    {
        AboutDialog about = new AboutDialog();
        about.set_logo_icon_name("moonshot");
        about.set_comments(_("Moonshot project UI\n Using GTK%d and %s backend".printf(Gtk.MAJOR_VERSION, this.identities_manager.get_store_name())));
        about.set_copyright(this.copyright());
        about.set_website(Config.PACKAGE_URL);
        about.set_website_label(_("Visit the Moonshot project web site"));

        // Note: The package version is configured at the top of moonshot/ui/configure.ac
        about.set_version(Config.PACKAGE_VERSION);
        about.set_license(this.license());
        about.set_modal(true);
        about.set_transient_for(this);
        about.response.connect((a, b) => {about.destroy();});
        set_bg_color(about);

        about.run();
    }

    private Gtk.ActionEntry[] create_actions() {
        Gtk.ActionEntry[] actions = new Gtk.ActionEntry[0];

        Gtk.ActionEntry helpmenu = { "HelpMenuAction",
                                     null,
                                     N_("_Help"),
                                     null, null, null };

        // Pick up the translated version of the name, if any
        helpmenu.label = dgettext(null, helpmenu.label);
        actions += helpmenu;

        Gtk.ActionEntry about = { "AboutAction",
                                  #if VALA_0_12
                                  Stock.ABOUT,
                                  #else
                                  STOCK_ABOUT,
                                  #endif
                                  N_("About"),
                                  null,
                                  N_("About this application"),
                                  on_about_action };

        about.label = dgettext(null, about.label);
        actions += about;

        return actions;
    }


    private void create_ui_manager()
    {
        Gtk.ActionGroup action_group = new Gtk.ActionGroup("GeneralActionGroup");
        action_group.add_actions(create_actions(), this);
        ui_manager.insert_action_group(action_group, 0);
        try
        {
            ui_manager.add_ui_from_string(menu_layout, -1);
        }
        catch (Error e)
        {
            stderr.printf("%s\n", e.message);
            logger.error("create_ui_manager: Caught error: " + e.message);
        }
        ui_manager.ensure_update();
    }

    private void build_ui()
    {
        set_bg_color(this);
        try {
            this.icon = IconTheme.get_default().load_icon("moonshot", 48, 0);
        } catch (Error e) {
            stderr.printf ("Could not load application icon: %s\n", e.message);
        }

        create_ui_manager();

        int num_rows = 18;
        int num_cols = 8;
        int button_width = 1;

        Table top_table = new Table(num_rows, 10, false);
        top_table.set_border_width(12);

        AttachOptions fill_and_expand = AttachOptions.EXPAND | AttachOptions.FILL;
        AttachOptions fill = AttachOptions.FILL;
        int row = 0;

        service_prompt_vbox = new_vbox(0);

        string search_tooltip_text = _("Search for an identity or service");
        this.search_entry = new Entry();

        set_atk_name_description(search_entry, _("Search entry"), _("Search for a specific ID Card"));
        this.search_entry.set_icon_from_pixbuf(EntryIconPosition.SECONDARY,
                                               find_icon_sized("edit-find", Gtk.IconSize.MENU));
        this.search_entry.set_icon_tooltip_text(EntryIconPosition.SECONDARY,
                                                search_tooltip_text);

        this.search_entry.set_tooltip_text(search_tooltip_text);

        this.search_entry.set_icon_sensitive(EntryIconPosition.SECONDARY, false);

        this.search_entry.notify["text"].connect(search_entry_text_changed_cb);
        this.search_entry.key_press_event.connect(search_entry_key_press_event_cb);
        this.search_entry.set_width_chars(24);

        var search_label_markup ="<small>" + search_tooltip_text + "</small>";
        var full_search_label = new Label(null);
        full_search_label.set_markup(search_label_markup);
        full_search_label.set_alignment(1, 0);

        var search_vbox = new_vbox(0);
        search_vbox.pack_start(search_entry, false, false, 0);
        search_vbox.pack_start(full_search_label, false, false, 0);

        // Overlap with the service_prompt_box
        top_table.attach(search_vbox, num_cols / 2, num_cols - button_width, row, row + 1, fill_and_expand, fill_and_expand, 2, 0);
        top_table.attach(service_prompt_vbox, 0, num_cols / 2, row, row + 1, fill_and_expand, fill_and_expand, 2, 0);
        row++;

        this.custom_vbox = new CustomVBox(this, false, 2);

        var viewport = new Viewport(null, null);
        viewport.set_border_width(2);
        viewport.set_shadow_type(ShadowType.NONE);
        viewport.add(custom_vbox);
        var id_scrollwin = new ScrolledWindow(null, null);
        id_scrollwin.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        id_scrollwin.set_shadow_type(ShadowType.IN);
        id_scrollwin.add_with_viewport(viewport);
        top_table.attach(id_scrollwin, 0, num_cols - 1, row, num_rows - 1, fill_and_expand, fill_and_expand, 6, 0);

        var add_button = new Button.with_label(_("Add"));
        add_button.clicked.connect((w) => {add_identity_cb();});
        top_table.attach(make_rigid(add_button), num_cols - button_width, num_cols, row, row + 1, fill, fill, 0, 0);
        row++;

        this.edit_button = new Button.with_label(_("Edit"));
        edit_button.clicked.connect((w) => {edit_identity_cb(this.selected_card);});
        edit_button.set_sensitive(false);
        top_table.attach(make_rigid(edit_button), num_cols - button_width, num_cols, row, row + 1, fill, fill, 0, 0);
        row++;

        this.remove_button = new Button.with_label(_("Remove"));
        remove_button.clicked.connect((w) => {remove_identity_cb(this.selected_card);});
        remove_button.set_sensitive(false);
        top_table.attach(make_rigid(remove_button), num_cols - button_width, num_cols, row, row + 1, fill, fill, 0, 0);
        row++;

        // push the send button down another row.
        this.send_button = new Button.with_label(_("Send"));
        send_button.clicked.connect((w) => {send_identity_cb(this.selected_card);});
        send_button.set_sensitive(false);
        top_table.attach(make_rigid(send_button), num_cols - button_width, num_cols, row, row + 1, fill, fill, 0, 0);
        row += 4;

        var import_button = new Button.with_label(_("Import"));
        import_button.clicked.connect((w) => {import_identities_cb();});
        top_table.attach(make_rigid(import_button), num_cols - button_width, num_cols, row, row + 1, fill, fill, 0, 0);
        row++;

        var export_button = new Button.with_label(_("Export"));
        export_button.clicked.connect((w) => {export_identities_cb();});
        top_table.attach(make_rigid(export_button), num_cols - button_width, num_cols, row, row + 1, fill, fill, 0, 0);
        row += 4;

        var change_mode = new Button.with_label(_("Set mode"));
        change_mode.clicked.connect((w) => {mode_changed_cb();});
        top_table.attach(make_rigid(change_mode), num_cols - button_width, num_cols, row, row + 1, fill, fill, 0, 0);
        row += 4;

        // Right below id_scrollwin:
        remember_identity_binding = new CheckButton.with_label(_("Remember my identity choice for this service"));
        remember_identity_binding.active = true;
        top_table.attach(remember_identity_binding, 0, num_cols - 3, row, row + 1, fill_and_expand, fill_and_expand, 3, 0);
        row++;

#if VALA_0_12
        Gtk.HBox statusbox = new Gtk.HBox(false, 0);
#else
        Gtk.HBox statusbox = new Gtk.HBox(true, 0);
#endif
        statusbar = new Gtk.Label("");
        statusbar.set_alignment(0, 0);
        refresh_status();
        top_table.attach(statusbar, 0, num_cols - button_width, row, row + 1, fill, fill, 6, 2);


        var main_vbox = new_vbox(0);

        var menubar = this.ui_manager.get_widget("/MenuBar");
        main_vbox.pack_start(menubar, false, false, 0);
        set_bg_color(menubar);
        main_vbox.pack_start(top_table, true, true, 0);

        add(main_vbox);
        main_vbox.show_all();

        if (!this.selection_in_progress())
            remember_identity_binding.hide();
    }

    internal bool selection_in_progress() {
        return !this.request_queue.is_empty();
    }

    private void set_atk_name_description(Widget widget, string name, string description)
    {
        var atk_widget = widget.get_accessible();

        atk_widget.set_name(name);
        atk_widget.set_description(description);
    }

    private void connect_signals()
    {
        this.destroy.connect(() => {
                logger.trace("Destroy event; calling Gtk.main_quit()");
                Gtk.main_quit();
            });
        this.identities_manager.card_list_changed.connect(this.on_card_list_changed);
        this.delete_event.connect(() => {return confirm_quit();});
    }

    private bool confirm_quit() {
        logger.trace("delete_event intercepted; selection_in_progress()=" + selection_in_progress().to_string());

        if (selection_in_progress()) {
            var result = WarningDialog.confirm(this,
                                               Markup.printf_escaped(
                                                   "<span font-weight='heavy'>" + _("Do you wish to exit without selecting an identity for the %s service?") + "</span>\n\n",
                                                   this.request_queue.peek_head().service)
                                               + _("If you do, Moonshot will not be used for this access, but you will still be prompted for future atempts.") + "\n\n"
                                               + _("If you want to prevent Moonshot from prompting you in the future for <b>this</b> service, please select 'No' and send the ID named '")
                                               + _("Do not use a Moonshot identity for this service") + _("' instead.") + "\n\n"
                                               + "If you want to prevent Moonshot from prompting you in the future for <b>any</b> service, please set the "
                                               + "NON_INTERACTIVE or DISABLED mode before exiting.",
                                                "close_moonshot_window_new");
            if (!result) {
                // Prevent other handlers from handling this event; this keeps the window open.
                return true;
            }
        }

        // Allow the window deletion to proceed.
        return false;
    }

    private static Widget make_rigid(Button button)
    {
        // Hack to prevent the button from growing vertically
        Box fixed_height = new_vbox(0);
        fixed_height.pack_start(button, false, false, 0);

        return fixed_height;
    }

    private void import_identities_cb() {
        var dialog = new FileChooserDialog(_("Import File"),
                                           this,
                                           FileChooserAction.OPEN,
                                           _("Cancel"),ResponseType.CANCEL,
                                           _("Open"), ResponseType.ACCEPT,
                                           null);

        if (import_directory != null) {
            dialog.set_current_folder(import_directory);
        }

        if (dialog.run() == ResponseType.ACCEPT)
        {
            // Save the parent directory to use as default for next save
            string filename = dialog.get_filename();
            var file  = File.new_for_path(filename);
            import_directory = file.get_parent().get_path();

            import_identities(filename, identities_manager, logger);
        }
        dialog.destroy();
    }

    private void export_identities_cb() {
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
        string default_filename = "credentials.xml";
        dialog.set_current_name(default_filename);
        if (dialog.run() == ResponseType.ACCEPT)
        {
            string filename = dialog.get_filename();
            Gee.List<IdCard> card_list = identities_manager.get_card_list();
            bool result = WebProvisioning.Writer.store(filename, card_list);
            if (!result)
                info_dialog("Error", "Could not save Identities file");
            var file  = File.new_for_path(filename);
            export_directory = file.get_parent().get_path();
        }
        dialog.destroy();
    }

}
