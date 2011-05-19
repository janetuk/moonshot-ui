[DBus (name = "org.janet.Moonshot")]
public class MoonshotServer : Object {

    private MainWindow main_window;

    public MoonshotServer (Gtk.Window window)
    {
        this.main_window = (MainWindow) window;
    }

    public async string[] get_identity (string nai,
                                        string password,
                                        string service)
    {
        string[3] information = {"", "", ""};

        main_window.set_callback (get_identity.callback);
        yield;

        var id_card = this.main_window.selected_id_card_widget.id_card;

        if (id_card.nai == nai || id_card.password == password)
        {
            information[0] = id_card.nai;
            information[1] = id_card.password;
            information[2] = "certificate";
        }

        return information;
    }
}
