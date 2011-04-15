using Gtk;

class IdCardWidget : Box
{
    public IdCard id_card { get; set; default = null; }

    private VBox main_vbox;
    private Table table;
    public Button delete_button { get; private set; default = null; }
    public Button details_button { get; private set; default = null; }
    public Button send_button { get; private set; default = null; }
    private HButtonBox hbutton_box;
    public EventBox event_box;

    private bool button_press_cb ()
    {
        this.hbutton_box.set_visible (!hbutton_box.get_visible ());

        return false;
    }

    public IdCardWidget ()
    {
        Gdk.Pixbuf pixbuf;

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
        var image = new Image.from_pixbuf (pixbuf);

        var issuer = Markup.printf_escaped ("<b>%s</b>", "University");
        var services = Markup.printf_escaped ("<i>%s</i>", "Send Email, Connect to jabber");
        var text = issuer + "\n" + services;

        var id_data_label = new Label (null);
        id_data_label.set_markup (text);

        this.table = new Table (1, 2, false);
        table.attach_defaults (image, 0, 1, 0, 1);
        table.attach_defaults (id_data_label, 1, 2, 0, 1);

        this.delete_button = new Button.with_label ("Delete");
        this.details_button = new Button.with_label ("View details");
        this.send_button = new Button.with_label ("Send");
        this.hbutton_box = new HButtonBox ();
        hbutton_box.pack_end (delete_button);
        hbutton_box.pack_end (details_button);
        hbutton_box.pack_end (send_button);

        this.main_vbox = new VBox (false, 12);
        main_vbox.pack_start (table, true, true, 0);
        main_vbox.pack_start (hbutton_box, false, false, 0);
        main_vbox.set_border_width (12);

        event_box = new EventBox ();
        event_box.add (main_vbox);
        event_box.button_press_event.connect (button_press_cb);
        this.pack_start (event_box, true, true);

        this.show_all ();
        this.hbutton_box.hide ();
    }
}
