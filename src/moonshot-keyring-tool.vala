#if GNOME_KEYRING || LIBSECRET_KEYRING

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
        create <name>
        set_default <keyring_name>
        delete <keyring_name>
        unlock <keyring_name>
        change_pwd <keyring_name>
""";
    if (args.length < 2) {
        stdout.printf(usage);
        return 1;
    }

    if (args[1] == "list") {
        string default_keyring;
        GnomeKeyring.get_default_keyring_sync(out default_keyring);

        List<string> keyrings;
        if (check_rv(GnomeKeyring.list_keyring_names_sync(out keyrings)) > 0)
            return 1;
        foreach(unowned string name in keyrings) {
            unowned GnomeKeyring.Info info;
            if (check_rv(GnomeKeyring.get_info_sync(null, out info)) > 0)
                return 1;
            info.get_is_locked();
            stdout.printf("%s %s %s\n".printf(name, name == default_keyring ? "[DEFAULT]" : "", info.get_is_locked() ? "[Locked]" : "[Unlocked]" ));
        }
        return 0;
    }

    else if (args[1] == "create"){
        if (args.length == 3) {
            string password = Posix.getpass("Password: ");
            return check_rv(GnomeKeyring.create_sync(args[2], password));
        }
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
        if (args.length == 3) {
            string old_password = Posix.getpass("Old password: ");
            string new_password = Posix.getpass("New password: ");
            return check_rv(GnomeKeyring.change_password_sync(args[2], old_password, new_password));
        }
    }

    else if (args[1] == "unlock"){
        if (args.length == 3){
            string password = Posix.getpass("Password: ");
            return check_rv(GnomeKeyring.unlock_sync(args[2], password));
        }
    }

    stdout.printf(usage);
    return 1;
}
#else
public static int main(string[] args) {
    stdout.printf("The UI has been built without GNOME_KEYRING support.");
    return 1;
}
#endif
