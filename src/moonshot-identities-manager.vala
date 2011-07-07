class IdentitiesManager : Object {

    public SList<IdCard> id_card_list;

    private const string FILE_NAME = "identities.txt";

    public IdentitiesManager ()
    {
        var key_file = new KeyFile ();

        var path = get_data_dir ();
        var filename = Path.build_filename (path, FILE_NAME);

        try
        {
            key_file.load_from_file (filename, KeyFileFlags.NONE);
        }
        catch (Error e)
        {
            stdout.printf("Error: %s\n", e.message);
        }

        var identities_uris = key_file.get_groups ();
        foreach (string identity in identities_uris)
        {
            try
            {
                IdCard id_card = new IdCard ();

                id_card.issuer = key_file.get_string (identity, "Issuer");
                id_card.username = key_file.get_string (identity, "Username");
                id_card.password = key_file.get_string (identity, "Password");
                id_card.services = key_file.get_string_list (identity, "Services");

                id_card_list.prepend (id_card);
            }
            catch (Error e)
            {
                stdout.printf ("Error:  %s\n", e.message);
            }
        }
    }

    public void store_id_cards ()
    {
        var key_file = new KeyFile ();

        foreach (IdCard id_card in this.id_card_list)
        {
            key_file.set_string (id_card.issuer, "Issuer", id_card.issuer);
            key_file.set_string (id_card.issuer, "Username", id_card.username);
            key_file.set_string (id_card.issuer, "Password", id_card.password);
            key_file.set_string_list (id_card.issuer, "Services", id_card.services);
        }

        var text = key_file.to_data (null);

        try
        {
            var path = get_data_dir ();
            var filename = Path.build_filename (path, FILE_NAME);
            FileUtils.set_contents (filename, text, -1);
        }
        catch (Error e)
        {
            stdout.printf ("Error:  %s\n", e.message);
        }
    }

    private string get_data_dir()
    {
        string path;

        path = Path.build_filename (Environment.get_user_data_dir (),
                                    Config.PACKAGE_TARNAME);
        if (!FileUtils.test (path, FileTest.EXISTS))
        {
            DirUtils.create (path, 0700);
        }

        return path;
    }

    public IdCard? load_gss_eap_id_file ()
    {
        IdCard id_card = new IdCard();
        string text;
        string id_card_data[2];

        var filename = Path.build_filename (Environment.get_home_dir (),
                                            ".gss_eap_id");
        try {
            FileUtils.get_contents (filename, out text, null);
        }
        catch (Error e)
        {
            return null;
        }

        if (text == "")
            return null;

        id_card_data = text.split ("\n", 2);
        if (id_card_data[1] != "")
            id_card.password = id_card_data[1];
        id_card_data = id_card_data[0].split ("@", 2);
        id_card.username = id_card_data[0];
        id_card.issuer = id_card_data[1];
        id_card.services = {};
        id_card.pixbuf = find_icon ("avatar-default", 48);

        return id_card;
    }

    public void store_gss_eap_id_file (IdCard ?id_card)
    {
        string text = "";

        if (id_card != null)
            text = id_card.username + "@" + id_card.issuer + "\n" + id_card.password;

        var filename = Path.build_filename (Environment.get_home_dir (),
                                            ".gss_eap_id");
        try
        {
            FileUtils.set_contents (filename, text, -1);
        }
        catch (Error e)
        {
            stdout.printf ("Error:  %s\n", e.message);
        }
    }
}
