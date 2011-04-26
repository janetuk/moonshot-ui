using Gtk;

class CustomVBox : VBox
{
    public IdCardWidget current_idcard { get; set; default = null; }

    private ListStore listmodel;
    private TreeModelFilter filter;

    private string search_text;

    private enum Columns
    {
        IDCARD_COL,
        LOGO_COL,
        ISSUER_COL,
        USERNAME_COL,
        PASSWORD_COL,
        N_COLUMNS
    }

    private bool visible_func (TreeModel model, TreeIter iter)
    {
        string issuer;
        string issuer_casefold;
        string search_text_casefold;

        model.get (iter,
                   Columns.ISSUER_COL, out issuer);

        if (issuer == null || this.search_text == null)
            return false;

        issuer_casefold = issuer.casefold ();
        search_text_casefold = search_text.casefold ();

        if (issuer_casefold.contains (search_text_casefold))
            return true;

        return false;
    }

    private void setup_identities_list ()
    {
       this.listmodel = new ListStore (Columns.N_COLUMNS, typeof (IdCard),
                                                          typeof (Gdk.Pixbuf),
                                                          typeof (string),
                                                          typeof (string),
                                                          typeof (string));
      this.filter = new TreeModelFilter (listmodel, null);

      filter.set_visible_func (visible_func);
    }

    public CustomVBox (bool homogeneous, int spacing)
    {
        this.set_homogeneous (homogeneous);
        this.set_spacing (spacing);

        setup_identities_list();
    }

    public void new_text_in_search_entry (string search_text)
    {
        this.search_text = search_text;

        filter.refilter ();
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
