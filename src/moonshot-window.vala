using Gtk;

class MainWindow : Window
{

    private Entry search_entry;
    private TreeView identities_list;

    public MainWindow()
    {
        this.title = "Moonshoot";
        this.position = WindowPosition.CENTER;
        set_default_size (400, 300);

        build_ui();
        connect_signals();
    }

    private void search_entry_icon_press_cb ()
    {
        print ("Search entry icon pressed\n");
    }

    private void search_entry_text_changed_cb ()
    {
        var has_text = this.search_entry.get_text_length () > 0;
        this.search_entry.set_icon_sensitive (EntryIconPosition.SECONDARY, has_text);
    }

    private void setup_identities_list ()
    {
        var listmodel = new ListStore (1, typeof (string)); //TODO
        this.identities_list.set_model (listmodel);

        var cell = new CellRendererText ();
        cell.set ("foreground_set", true);

        this.identities_list.insert_column_with_attributes (-1, "Identities", cell, "text", 0);
    }

    private void add_identity_cb ()
    {
        ListStore listmodel;
        TreeIter iter;

        listmodel = (ListStore) this.identities_list.get_model ();

        listmodel.append (out iter);
        listmodel.set (iter, 0, "Identity 1");
    }

    private void remove_identity_cb ()
    {
        TreeModel model;
        TreeIter iter;

        var selection = identities_list.get_selection ();

        if (selection.get_selected (out model, out iter))
        {
            ((ListStore) model).remove (iter);
        }
    }

    private void build_ui()
    {
        var toolbar = new Toolbar ();
        var open_button = new ToolButton (null, "Open"); //.from_stock (Stock.OPEN);
        open_button.is_important = true;
        toolbar.add (open_button);
        //open_button.clicked.connect (on_open_clicked);

        this.search_entry = new Entry();
        this.search_entry.set_icon_from_icon_name (EntryIconPosition.SECONDARY, "system-search");
        this.search_entry.set_icon_sensitive (EntryIconPosition.SECONDARY, false);
        this.search_entry.set_icon_tooltip_text (EntryIconPosition.SECONDARY,
                                                 "Search identity or service");
        this.search_entry.icon_press.connect (search_entry_icon_press_cb);
        this.search_entry.notify["text"].connect (search_entry_text_changed_cb);

        this.identities_list = new TreeView ();
        this.identities_list.set_headers_visible (false);
        setup_identities_list ();

        var scroll = new ScrolledWindow (null, null);
        scroll.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
        scroll.set_shadow_type (ShadowType.IN);
        scroll.add (this.identities_list);

        var button_add = new Button.from_stock ("gtk-add");
        button_add.clicked.connect (add_identity_cb);
        var button_remove = new Button.from_stock ("gtk-remove");
        button_remove.clicked.connect (remove_identity_cb);
        var button_box = new HButtonBox ();
        button_box.set_layout (ButtonBoxStyle.SPREAD);
        button_box.pack_start (button_add, false, false, 0);
        button_box.pack_start (button_remove, false, false, 0);

        var vbox_left = new VBox (false, 0);
        vbox_left.pack_start (search_entry, false, true, 0);
        vbox_left.pack_start (scroll, true, true, 0);
        vbox_left.pack_start (button_box, false, false, 0);

        var login_vbox_title = new Label ("Login: ");
        login_vbox_title.set_alignment (0, 0);
        var username_label = new Label ("Username:");
        var username_entry = new Entry ();
        var password_label = new Label ("Password:");
        var password_entry = new Entry ();
        var remember_checkbutton = new CheckButton.with_label ("Remember password");
        var login_table = new Table (3, 3, false);
        login_table.set_col_spacings (6);
        login_table.attach_defaults (username_label, 0, 1, 0, 1);
        login_table.attach_defaults (username_entry, 1, 2, 0, 1);
        login_table.attach_defaults (password_label, 0, 1, 1, 2);
        login_table.attach_defaults (password_entry, 1, 2, 1, 2);
        login_table.attach_defaults (remember_checkbutton,  0, 2, 2, 3);
        var login_vbox_alignment = new Alignment (0, 0, 0, 0);
        login_vbox_alignment.set_padding (0, 0, 12, 0);
        login_vbox_alignment.add (login_table);
        var login_vbox = new VBox (false, 6);
        login_vbox.pack_start (login_vbox_title, false, true, 0);
        login_vbox.pack_start (login_vbox_alignment, false, true, 0);

        var services_vbox_title = new Label ("Services:");
        services_vbox_title.set_alignment (0, 0);
        var email_label = new Label ("Email");
        var email_remove_button = new Button.from_stock (Stock.REMOVE);
        var im_label = new Label ("IM");
        var im_remove_button = new Button.from_stock (Stock.REMOVE);
        var services_table = new Table (2, 2, false);
        services_table.set_col_spacings (6);
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

        var vbox_rigth = new VBox (false, 18);
        vbox_rigth.pack_start (login_vbox, false, true, 0);
        vbox_rigth.pack_start (services_vbox, false, true, 0);

        var hbox = new HBox (false, 0);
        hbox.pack_start (vbox_left, true, true, 12);
        hbox.pack_start (vbox_rigth, true, true, 12);

        var main_vbox = new VBox (false, 12);
        main_vbox.pack_start (toolbar, false, true, 0);
        main_vbox.pack_start (hbox, true, true, 0);
        add (main_vbox);
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
        window.show_all();

        Gtk.main();

        return 0;
    }
}
