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
    private EventBox event_box;

    public signal void expanded ();
    public signal void remove_id ();
    public signal void details_id ();

    public void collapse ()
    {
        this.hbutton_box.set_visible (false);

        set_idcard_color ();
    }

    private bool button_press_cb ()
    {
        this.hbutton_box.set_visible (!hbutton_box.get_visible ());

        set_idcard_color ();

        if (hbutton_box.get_visible () == true)
          this.expanded ();

        return false;
    }

    private void delete_button_cb ()
    {
       this.remove_id ();
    }

    private void details_button_cb ()
    {
       this.details_id ();
    }

    private void set_idcard_color ()
    {
        var color = Gdk.Color ();

        if (hbutton_box.get_visible () == false)
        {
            color.red = 65535;
            color.green = 65535;
            color.blue = 65535;
        }
        else
        {
            color.red = 33333;
            color.green = 33333;
            color.blue = 60000;
        }
        var state = this.get_state ();
        this.event_box.modify_bg (state, color);
    }

    public IdCardWidget (IdCard id_card)
    {
        string services_text = "";
        this.id_card = id_card;

        var image = new Image.from_pixbuf (id_card.pixbuf);

        var issuer = Markup.printf_escaped ("<b>%s</b>", this.id_card.issuer);
        foreach (string service in id_card.services)
        {
            services_text = services_text + Markup.printf_escaped ("<i>%s, </i>", service);
        }
        var text = issuer + "\n" + services_text;

        var id_data_label = new Label (null);
        id_data_label.set_markup (text);
        id_data_label.set_alignment ((float) 0, (float) 0.5);

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

        delete_button.clicked.connect (delete_button_cb);
        details_button.clicked.connect (details_button_cb);

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

        set_idcard_color ();
    }
}
