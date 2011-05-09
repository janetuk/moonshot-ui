[DBus (name = "org.janet.Moonshot")]
public class MoonshotServer : Object {
    private int counter;
    private MainWindow main_window;

    public MoonshotServer (Gtk.Window window)
    {
        this.main_window = (MainWindow) window;
    }

    public int ping (string msg)
    {
        stdout.printf ("%s\n", msg);
        return counter++;
    }

    public string[] get_identity (string identity,
                                  string password,
                                  string service)
    {
        string[3] information = new string[3];

        var id_card = this.main_window.selected_id_card_widget.id_card;

        information[0] = "identity";
        information[1] = id_card.password;
        information[2] = "certificate";

        return information;
    }
}
