using Gtk;

class AddIdentityDialog : Dialog
{
    public string issuer { get; set; default = null; }
    public string username { get; set; default = null; }
    public string password { get; set; default = null; }

    public AddIdentityDialog ()
    {
        this.set_title (_("Add ID Card"));
        this.set_modal (true);

        this.add_buttons (_("Add ID Card"), ResponseType.OK,
                          Stock.CANCEL, ResponseType.CANCEL);

        var content_area = this.get_content_area ();
        ((Box) content_area).set_spacing (12);

        var issuer_label = new Label (_("Issuer:"));
        issuer_label.set_alignment (1, (float) 0.5);
        var issuer_entry = new Entry ();
        var username_label = new Label (_("Username:"));
        username_label.set_alignment (1, (float) 0.5);
        var username_entry = new Entry ();
        var password_label = new Label (_("Password:"));
        password_label.set_alignment (1, (float) 0.5);
        var password_entry = new Entry ();
        password_entry.set_invisible_char ('*');
        password_entry.set_visibility (false);
        var remember_checkbutton = new CheckButton.with_label (_("Remember password"));
        var table = new Table (4, 4, false);
        table.set_col_spacings (10);
        table.set_row_spacings (10);
        table.attach_defaults (issuer_label, 0, 1, 0, 1);
        table.attach_defaults (issuer_entry, 1, 2, 0, 1);
        table.attach_defaults (username_label, 0, 1, 1, 2);
        table.attach_defaults (username_entry, 1, 2, 1, 2);
        table.attach_defaults (password_label, 0, 1, 2, 3);
        table.attach_defaults (password_entry, 1, 2, 2, 3);
        table.attach_defaults (remember_checkbutton,  1, 2, 3, 4);

        var vbox = new VBox (false, 0);
        vbox.set_border_width (6);
        vbox.pack_start (table, false, false, 0);

        ((Container) content_area).add (vbox);

        this.set_border_width (6);
        this.set_resizable (false);
        this.show_all ();
    }
}
