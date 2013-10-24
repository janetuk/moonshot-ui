using Gtk;

class CustomVBox : VBox
{
    public IdCardWidget current_idcard { get; set; default = null; }
    private IdentityManagerView main_window; 

    public CustomVBox (IdentityManagerView window, bool homogeneous, int spacing)
    {
        main_window = window;
        set_homogeneous (homogeneous);
        set_spacing (spacing);
    }

    public void receive_expanded_event (IdCardWidget id_card_widget)
    {
        var list = get_children ();
        foreach (Widget id_card in list)
        {
            if (id_card != id_card_widget)
                ((IdCardWidget) id_card).collapse ();
        }
        current_idcard = id_card_widget;
        
        if (current_idcard != null && main_window.request_queue.length > 0)
            current_idcard.send_button.set_sensitive (true);
        check_resize();
    }

    public void add_id_card_widget (IdCardWidget id_card_widget)
    {
        pack_start (id_card_widget, false, false);
    }

    public void remove_id_card_widget (IdCardWidget id_card_widget)
    {
        remove (id_card_widget);
    }
}
