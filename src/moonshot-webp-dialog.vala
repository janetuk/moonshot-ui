namespace WebProvisioning
{

  class ConfirmDialog: Gtk.Dialog
  {
    public ConfirmDialog (IdCard id_card)
    {
      add_button (_("Add"), Gtk.ResponseType.ACCEPT);
      add_button (_("Don't add"), Gtk.ResponseType.REJECT);
      
      Gtk.VBox vbox = (Gtk.VBox)get_child();
      vbox.set_spacing (6);
      var label = new Gtk.Label("");
      label.set_markup ("<b>" + _("Would you like to add '") + id_card.display_name + _("' ID Card to the ID Card Organizer?") + "</b>");
      vbox.add (label);
    }
  } 
}
