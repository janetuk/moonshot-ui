[DBus (name = "org.janet.Moonshot")]
public class MoonshotServer : Object {

    private MainWindow main_window;

    public MoonshotServer (Gtk.Window window)
    {
        this.main_window = (MainWindow) window;
    }

    public async bool get_identity (string nai,
                                    string password,
                                    string service,
                                    out string nai_out,
                                    out string password_out,
                                    out string certificate_out)
    {
        bool has_service = false;

        nai_out = "";
        password_out = "";
        certificate_out = "";

        main_window.set_callback (get_identity.callback);
        yield;

        var id_card = this.main_window.selected_id_card_widget.id_card;

        foreach (string id_card_service in id_card.services)
        {
            if (id_card_service == service)
                has_service = true;
        }

        if (has_service)
        {
            nai_out = id_card.nai;
            password_out = id_card.password;
            certificate_out = "certificate";

            return true;
        }

        return false;
    }
}
