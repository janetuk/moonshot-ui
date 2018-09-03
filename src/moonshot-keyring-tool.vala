#if GNOME_KEYRING
using GnomeKeyring;
using GLib;

int check_rv(GnomeKeyring.Result rv) {
    if (rv != GnomeKeyring.Result.OK) {
        stdout.printf("Error found: CODE=%d\n", rv);
        return 1;
    }
    return 0;
}

public static int main(string[] args) {
    string usage =
"""Usage: moonshot-keyring-tool <ACTION>
    Where <ACTION> can be any of:
        list
        create <name> <password>
        set_default <keyring_name>
        delete <keyring_name>
        change_pwd <keyring_name> <original_pwd> <new_pwd>
""";
    if (args.length < 2) {
        stdout.printf(usage);
        return 1;
    }

    if (args[1] == "list") {
        string default_keyring;
        GnomeKeyring.get_default_keyring_sync(out default_keyring);

        List<string> keyrings;
        GnomeKeyring.Result rv = GnomeKeyring.list_keyring_names_sync(out keyrings);
        foreach(unowned string name in keyrings) {
            stdout.printf("%s %s\n".printf(name, name == default_keyring ? "[DEFAULT]" : "" ));
        }

        return check_rv(rv);
    }

    else if (args[1] == "create"){
        if (args.length == 4)
            return check_rv(GnomeKeyring.create_sync(args[2], args[3]));
    }

    else if (args[1] == "set_default"){
        if (args.length == 3)
            return check_rv(GnomeKeyring.set_default_keyring_sync(args[2]));
    }

    else if (args[1] == "delete"){
        if (args.length == 3)
            return check_rv(GnomeKeyring.delete_sync(args[2]));
    }

    else if (args[1] == "change_pwd"){
        if (args.length == 5)
            return check_rv(GnomeKeyring.change_password_sync(args[2], args[3], args[4]));
    }

    stdout.printf(usage);
    return 1;
}
#endif
