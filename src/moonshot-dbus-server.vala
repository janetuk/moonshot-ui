[DBus (name = "org.janet.Moonshot")]
public class MoonshotServer : Object {

    private MainWindow main_window;

    public MoonshotServer (Gtk.Window window)
    {
        this.main_window = (MainWindow) window;
    }

    /**
     * This is the function used by the GSS mechanism to get the NAI,
     * password and certificate of the ID card for the specificated service.
     *
     * The function will block until the user choose the ID card.
     *
     * @param nai NAI of the ID Card (optional)
     * @param password Password of the ID Card (optional)
     * @param service Service application request an ID Card for
     * @param nai_out NAI stored in the ID Card
     * @param password_out Password stored in the ID Card
     * @param certificate Certificate stored in th ID Card
     *
     * @return true if the user choose a correct ID card for that service,
     *         false otherwise.
     */
    public async bool get_identity (string nai,
                                    string password,
                                    string service,
                                    out string nai_out,
                                    out string password_out,
                                    out string certificate_out)
    {
        bool has_service = false;

        var request = new IdentityRequest (main_window,
                                           nai,
                                           password,
                                           service);
        request.set_source_func_callback (get_identity.callback);
        request.execute ();
        yield;

        nai_out = "";
        password_out = "";
        certificate_out = "";

        var id_card = request.id_card;

        if (id_card != null) {
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
        }

        return false;
    }
}
