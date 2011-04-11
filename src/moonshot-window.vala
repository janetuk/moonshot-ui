using Gtk;

class MainWindow : Window
{

    private Entry search_entry;
    private TreeView identities_list;
    private VBox vbox_rigth;

    private enum Columns
    {
        IDCARD_COL,
        LOGO_COL,
        NAME_COL,
        N_COLUMNS
    }

    public MainWindow()
    {
        this.title = "Moonshoot";
        this.position = WindowPosition.CENTER;
        set_default_size (400, 500);

        build_ui();
        connect_signals();
    }

    private void search_entry_icon_press_cb (EntryIconPosition pos, Gdk.Event event)
    {
	if (pos == EntryIconPosition.PRIMARY)
        {
            print ("Search entry icon pressed\n");
        }
        else
        {
            this.search_entry.set_text ("");
        }
    }

    private void search_entry_text_changed_cb ()
    {
        var has_text = this.search_entry.get_text_length () > 0;
        this.search_entry.set_icon_sensitive (EntryIconPosition.PRIMARY, has_text);
        this.search_entry.set_icon_sensitive (EntryIconPosition.SECONDARY, has_text);
    }

    private bool search_entry_key_press_event_cb (Gdk.EventKey e)
    {
        if(Gdk.keyval_name(e.keyval) == "Escape")
           this.search_entry.set_text("");

        // Continue processing this event, since the
        // text entry functionality needs to see it too.
        return false;
    }

    private void selected_idcard_changed (TreeSelection selection)
    {
        this.vbox_rigth.show ();
    }

    private void setup_identities_list ()
    {
        var listmodel = new ListStore (Columns.N_COLUMNS, typeof (IdCard),
                                                          typeof (Gdk.Pixbuf),
                                                          typeof (string));
        this.identities_list.set_model (listmodel);

        var column = new TreeViewColumn ();
        var cell_logo = new CellRendererPixbuf ();
        column.pack_start (cell_logo, false);
        column.add_attribute (cell_logo, "pixbuf", Columns.LOGO_COL);
        cell_logo.set ("stock-size", IconSize.MENU);

        var cell_name = new CellRendererText ();
        column.pack_start (cell_name, false);
        column.add_attribute (cell_name, "markup", Columns.NAME_COL);
        cell_name.set ("wrap-width", 300,
                       "wrap-mode", WrapMode.WORD);

        this.identities_list.append_column (column);

        var selection = this.identities_list.get_selection ();
        selection.set_mode (SelectionMode.BROWSE);
        selection.changed.connect (selected_idcard_changed);
    }

    private void add_identity ()
    {
        ListStore listmodel;
        TreeIter iter;
        Gdk.Pixbuf pixbuf;
        string services = "";

        var icon_theme = IconTheme.get_default ();

        try
        {
            pixbuf = icon_theme.load_icon ("avatar-default",
                                           48,
                                           IconLookupFlags.FORCE_SIZE);
        }
        catch (Error e)
        {
            pixbuf = null;
            stdout.printf("Error: %s\n", e.message);
        }

        var id_card = new IdCard ();
        id_card.issuer = "University";
        id_card.services = new string[3];
        id_card.services[0] = "Sending emails";
        id_card.services[1] = "Connect to IRC";
        id_card.services[2] = "Connect to jabber";
        id_card.number = 123;

        for (int i = 0; i < id_card.services.length - 1; i++)
        {
            services = services + "<i>" + id_card.services[i] + "</i>, ";
        }
        services = services + "<i>" + id_card.services[id_card.services.length - 1] + "</i>";
        var text = "<b>" + id_card.issuer + "</b>\n" + services;

        listmodel = (ListStore) this.identities_list.get_model ();
        listmodel.append (out iter);
        listmodel.set (iter,
                       Columns.IDCARD_COL, id_card,
                       Columns.LOGO_COL, pixbuf,
                       Columns.NAME_COL, text);
    }

    private void add_identity_cb ()
    {
        var dialog = new AddIdentityDialog ();
        var result = dialog.run ();

        switch (result) {
        case ResponseType.OK:
            add_identity ();
            break;
        default:
            break;
        }
        dialog.destroy ();
    }

    private IdCard* get_selected_idcard ()
    {
        TreeModel model;
        TreeIter iter;
        IdCard id_card;

        var selection = this.identities_list.get_selection ();

        if (selection.get_selected (out model, out iter))
        {
            model.get (iter, Columns.IDCARD_COL, out id_card);
            return id_card;
        }

        return null;
    }

    private void remove_identity (IdCard id_card)
    {
        TreeModel model;
        TreeIter iter;
        IdCard id_card_list;

        var selection = this.identities_list.get_selection ();

        if (selection.get_selected (out model, out iter))
        {
            model.get (iter, Columns.IDCARD_COL, out id_card_list);
            if (id_card_list != null && id_card_list.issuer == id_card.issuer)
            {
                ((ListStore) model).remove (iter);
            }
        }
    }

    private void remove_identity_cb ()
    {
        var id_card = get_selected_idcard ();
        if (id_card == null)
        {
            return;
        }
	else
	{
            var dialog = new MessageDialog (null,
                                            DialogFlags.DESTROY_WITH_PARENT,
                                            MessageType.INFO,
                                            Gtk.ButtonsType.YES_NO,
                                            _("Are you sure you want to delete this ID Card?"));
            var result = dialog.run ();
            switch (result) {
            case ResponseType.YES:
                remove_identity (id_card);
                break;
            default:
                break;
            }
            dialog.destroy ();
        }
    }

    private void label_make_bold (Label label)
    {
        var font_desc = new Pango.FontDescription ();

        font_desc.set_weight (Pango.Weight.BOLD);

        /* This will only affect the weight of the font, the rest is
         * from the current state of the widget, which comes from the
         * theme or user prefs, since the font desc only has the
         * weight flag turned on.
         */
        label.modify_font (font_desc);
    }

    private void build_ui()
    {
        var toolbar = new Toolbar ();
        var open_button = new ToolButton (null, "Open"); //.from_stock (Stock.OPEN);
        open_button.is_important = true;
        toolbar.add (open_button);
        //open_button.clicked.connect (on_open_clicked);

        this.search_entry = new Entry();

        this.search_entry.set_icon_from_icon_name (EntryIconPosition.PRIMARY,
                                                   "edit-find-symbolic");
        this.search_entry.set_icon_sensitive (EntryIconPosition.PRIMARY, false);
        this.search_entry.set_icon_tooltip_text (EntryIconPosition.PRIMARY,
                                                 _("Search identity or service"));

        this.search_entry.set_icon_from_icon_name (EntryIconPosition.SECONDARY,
                                                   "edit-clear-symbolic");
        this.search_entry.set_icon_sensitive (EntryIconPosition.SECONDARY, false);
        this.search_entry.set_icon_tooltip_text (EntryIconPosition.SECONDARY,
                                                 _("Clear the current search"));

        this.search_entry.icon_press.connect (search_entry_icon_press_cb);
        this.search_entry.notify["text"].connect (search_entry_text_changed_cb);
        this.search_entry.key_press_event.connect(search_entry_key_press_event_cb);

        this.identities_list = new TreeView ();
        this.identities_list.set_headers_visible (false);
        setup_identities_list ();

        var scroll = new ScrolledWindow (null, null);
        scroll.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
        scroll.set_shadow_type (ShadowType.IN);
        scroll.add (this.identities_list);

        var button_add = new ToolButton (null, null);
        button_add.set_icon_name ("list-add-symbolic");
        button_add.clicked.connect (add_identity_cb);
        var button_remove = new ToolButton (null, null);
        button_remove.set_icon_name ("list-remove-symbolic");
        button_remove.clicked.connect (remove_identity_cb);
        var button_toolbar = new Toolbar ();
        button_toolbar.insert (button_add, 0);
        button_toolbar.insert (button_remove, 1);

        var vbox_left = new VBox (false, 0);
        vbox_left.pack_start (search_entry, false, false, 6);
        vbox_left.pack_start (scroll, true, true, 0);
        vbox_left.pack_start (button_toolbar, false, false, 0);

        var login_vbox_title = new Label (_("Login: "));
        label_make_bold (login_vbox_title);
        login_vbox_title.set_alignment (0, (float) 0.5);
        var username_label = new Label (_("Username:"));
        username_label.set_alignment (1, (float) 0.5);
        var username_entry = new Entry ();
        var password_label = new Label (_("Password:"));
        password_label.set_alignment (1, (float) 0.5);
        var password_entry = new Entry ();
        password_entry.set_invisible_char ('*');
        password_entry.set_visibility (false);
        var remember_checkbutton = new CheckButton.with_label (_("Remember password"));
        var login_table = new Table (3, 3, false);
        login_table.set_col_spacings (10);
        login_table.set_row_spacings (10);
        login_table.attach_defaults (username_label, 0, 1, 0, 1);
        login_table.attach_defaults (username_entry, 1, 2, 0, 1);
        login_table.attach_defaults (password_label, 0, 1, 1, 2);
        login_table.attach_defaults (password_entry, 1, 2, 1, 2);
        login_table.attach_defaults (remember_checkbutton,  1, 2, 2, 3);
        var login_vbox_alignment = new Alignment (0, 0, 0, 0);
        login_vbox_alignment.set_padding (0, 0, 12, 0);
        login_vbox_alignment.add (login_table);
        var login_vbox = new VBox (false, 6);
        login_vbox.pack_start (login_vbox_title, false, true, 0);
        login_vbox.pack_start (login_vbox_alignment, false, true, 0);

        var services_vbox_title = new Label (_("Services:"));
        label_make_bold (services_vbox_title);
        services_vbox_title.set_alignment (0, (float) 0.5);
        var email_label = new Label (_("Email"));
        var email_remove_button = new Button.from_stock (Stock.REMOVE);
        var im_label = new Label (_("IM"));
        var im_remove_button = new Button.from_stock (Stock.REMOVE);
        var services_table = new Table (2, 2, false);
        services_table.set_col_spacings (10);
        services_table.set_row_spacings (10);
        services_table.attach_defaults (email_label, 0, 1, 0, 1);
        services_table.attach_defaults (email_remove_button, 1, 2, 0, 1);
        services_table.attach_defaults (im_label, 0, 1, 1, 2);
        services_table.attach_defaults (im_remove_button, 1, 2, 1, 2);
        var services_vbox_alignment = new Alignment (0, 0, 0, 0);
        services_vbox_alignment.set_padding (0, 0, 12, 0);
        services_vbox_alignment.add (services_table);
        var services_vbox = new VBox (false, 6);
        services_vbox.pack_start (services_vbox_title, false, true, 0);
        services_vbox.pack_start (services_vbox_alignment, false, true, 0);

        this.vbox_rigth = new VBox (false, 18);
        vbox_rigth.pack_start (login_vbox, false, true, 0);
        vbox_rigth.pack_start (services_vbox, false, true, 0);

        var hbox = new HBox (false, 12);
        hbox.pack_start (vbox_left, true, true, 0);
        hbox.pack_start (vbox_rigth, true, true, 0);

        var send_button = new Button.with_label ("Send");
        var hbox_send_button = new HBox (false, 0);
        hbox_send_button.pack_end (send_button, false, false, 0);

        var main_vbox = new VBox (false, 12);
        main_vbox.pack_start (toolbar, false, true, 0);
        main_vbox.pack_start (hbox, true, true, 0);
        main_vbox.pack_start (hbox_send_button, false, false, 0);
        main_vbox.set_border_width (12);
        add (main_vbox);

        main_vbox.show_all();
        this.vbox_rigth.hide ();
    }

    private void connect_signals()
    {
        this.destroy.connect (Gtk.main_quit);
    }

    public static int main(string[] args)
    {
        Gtk.init(ref args);

        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);

        var window = new MainWindow();
        window.show ();

        Gtk.main();

        return 0;
    }
}
