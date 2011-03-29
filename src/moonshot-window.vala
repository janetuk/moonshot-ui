using Gtk;

class MainWindow : Window
{

    private Entry search_entry;
    private TextView text_view;

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

        this.text_view = new TextView ();
        this.text_view.editable = true;
        this.text_view.cursor_visible = true;

        var scroll = new ScrolledWindow (null, null);
        scroll.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
        scroll.add (this.text_view);

        var button_add = new Button.from_stock ("gtk-add");
        var button_remove = new Button.from_stock ("gtk-remove");
        var button_box = new HButtonBox ();
        button_box.set_layout (ButtonBoxStyle.SPREAD);
        button_box.pack_start (button_add, false, false, 0);
        button_box.pack_start (button_remove, false, false, 0);

        var vbox = new VBox (false, 0);
        vbox.pack_start (toolbar, false, true, 0);
        vbox.pack_start (search_entry, false, true, 0);
        vbox.pack_start (scroll, true, true, 0);
        vbox.pack_start (button_box, false, false, 0);
        add (vbox);
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
