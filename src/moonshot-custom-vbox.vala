using Gtk;

class CustomVBox : VBox
{
    public CustomVBox (bool homogeneous, int spacing)
    {
        this.set_homogeneous (homogeneous);
        this.set_spacing (spacing);
    }

    public void receive_expanded_event ()
    {
        var id_cards = this.get_children ();
    }
}
