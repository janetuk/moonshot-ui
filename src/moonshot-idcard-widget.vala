using Gtk;

class IdCardWidget : Box
{
    public IdCard id_card { get; set; default = null; }

    private VBox main_vbox;
    private HBox table;
    public Button delete_button { get; private set; default = null; }
    public Button details_button { get; private set; default = null; }
    public Button send_button { get; private set; default = null; }
    private HButtonBox hbutton_box;
    private EventBox event_box;
    
    private Label label;

    public signal void expanded ();
    public signal void remove_id ();
    public signal void details_id ();
    public signal void send_id ();

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

    private void send_button_cb ()
    {
       this.send_id ();
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
    
    public void
    update_id_card_label ()
    {
        string services_text = "";

        var display_name = Markup.printf_escaped ("<b>%s</b>", this.id_card.display_name);
        for (int i=0; i<id_card.services.length; i++)
        {
            var service = id_card.services[i];
            
            if (i == (id_card.services.length - 1))
              services_text = services_text + Markup.printf_escaped ("<i>%s</i>", service);
            else
              services_text = services_text + Markup.printf_escaped ("<i>%s, </i>", service);
        }
        label.set_markup (display_name + "\n" + services_text);
    }

    public IdCardWidget (IdCard id_card)
    {
        this.id_card = id_card;

        var image = new Image.from_pixbuf (id_card.get_data ("pixbuf"));

        label = new Label (null);
        label.set_alignment ((float) 0, (float) 0.5);
        label.set_ellipsize (Pango.EllipsizeMode.END);
        update_id_card_label();

        table = new Gtk.HBox (false, 6);
        table.pack_start (image, false, false, 0);
        table.pack_start (label, true, true, 0);

        this.delete_button = new Button.with_label (_("Delete"));
        this.details_button = new Button.with_label (_("View details"));
        this.send_button = new Button.with_label (_("Send"));
        set_atk_name_description (delete_button, _("Delete"), _("Delete this ID Card"));
        set_atk_name_description (details_button, _("Details"), _("View the details of this ID Card"));
        set_atk_name_description (send_button, _("Send"), _("Send this ID Card"));
        this.hbutton_box = new HButtonBox ();
        hbutton_box.pack_end (delete_button);
        hbutton_box.pack_end (details_button);
        hbutton_box.pack_end (send_button);
        send_button.set_sensitive (false);

        delete_button.clicked.connect (delete_button_cb);
        details_button.clicked.connect (details_button_cb);
        send_button.clicked.connect (send_button_cb);

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

    private void set_atk_name_description (Widget widget, string name, string description)
    {
       var atk_widget = widget.get_accessible ();

       atk_widget.set_name (name);
       atk_widget.set_description (description);
    }
}
