using Gtk;

class CustomVBox : VBox
{
    public IdCardWidget current_idcard { get; set; default = null; }

    private ListStore listmodel;

    private enum Columns
    {
        IDCARD_COL,
        LOGO_COL,
        ISSUER_COL,
        USERNAME_COL,
        PASSWORD_COL,
        N_COLUMNS
    }

    private void setup_identities_list ()
    {
       this.listmodel = new ListStore (Columns.N_COLUMNS, typeof (IdCard),
                                                          typeof (Gdk.Pixbuf),
                                                          typeof (string),
                                                          typeof (string),
                                                          typeof (string));
    }

    public CustomVBox (bool homogeneous, int spacing)
    {
        this.set_homogeneous (homogeneous);
        this.set_spacing (spacing);

        setup_identities_list();
    }

    public void receive_expanded_event (IdCardWidget id_card_widget)
    {
        var list = this.get_children ();
        foreach (Widget id_card in list)
        {
            if (id_card != id_card_widget)
                ((IdCardWidget) id_card).collapse ();
        }
    }

    public void add_id_card_widget (IdCardWidget id_card_widget)
    {
        TreeIter iter;

        this.pack_start (id_card_widget, false, false);

        var id_card = id_card_widget.id_card;

        this.listmodel.append (out iter);
        listmodel.set (iter,
                       Columns.IDCARD_COL, id_card,
                       Columns.LOGO_COL, id_card.pixbuf,
                       Columns.ISSUER_COL, id_card.issuer,
                       Columns.USERNAME_COL, id_card.username,
                       Columns.PASSWORD_COL, id_card.password);
    }

    public void remove_id_card_widget (IdCardWidget id_card_widget)
    {
        TreeIter iter;
        string issuer;

        this.remove (id_card_widget);

        if (listmodel.get_iter_first (out iter))
        {
            do
            {
                listmodel.get (iter,
                               Columns.ISSUER_COL, out issuer);

                if (id_card_widget.id_card.issuer == issuer)
                {
                    listmodel.remove (iter);
                    break;
                }
            }
            while (listmodel.iter_next (ref iter));
        }
    }
}
