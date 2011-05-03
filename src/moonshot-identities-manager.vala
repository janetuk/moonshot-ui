class IdentitiesManager : Object {

    public SList<IdCard> id_card_list;

    private const string FILE_NAME = "identities.txt";

    public IdentitiesManager ()
    {
        var key_file = new KeyFile ();

        try
        {
            key_file.load_from_file (FILE_NAME, KeyFileFlags.NONE);
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

    public void store_id_cards (SList<IdCard> id_card_list)
    {
        var key_file = new KeyFile ();

        foreach (IdCard id_card in id_card_list)
        {
            key_file.set_string (id_card.issuer, "Issuer", id_card.issuer);
            key_file.set_string (id_card.issuer, "Username", id_card.username);
            key_file.set_string (id_card.issuer, "Password", id_card.password);
            key_file.set_string_list (id_card.issuer, "Services", id_card.services);
        }

        var text = key_file.to_data (null);

        try
        {
            FileUtils.set_contents (FILE_NAME, text, -1);
        }
        catch (Error e)
        {
            stdout.printf ("Error:  %s\n", e.message);
        }
    }

}
