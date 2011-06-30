[DBus (name = "org.janet.Moonshot")]
interface Moonshot : Object {
    public abstract bool get_identity (string nai, string password, string service,
                                       out string nai_out, out string password_out,
                                       out string server_certificate_hash, out string ca_certificate, out string subject_name_constraint, out string subject_alt_name_constraint) throws DBus.Error;
    public abstract bool get_default_identity (out string nai_out, out string password_out) throws DBus.Error;
}

void main () {
    try {
        string nai_out, password_out, certificate_out;
        string a, b, c;

        var conn = DBus.Bus.get (DBus.BusType.SESSION);
        var demo = (Moonshot) conn.get_object ("org.janet.Moonshot",
                                               "/org/janet/moonshot");


        if (demo.get_default_identity (out nai_out, out password_out))
        {
            stdout.printf ("default identity: %s %s\n", nai_out, password_out);
        }
        else
        {
            stdout.printf ("Unable to get default identity.\n");
        }


        if (demo.get_identity ("username@issuer",
                               "pass",
                               "",
                               out nai_out,
                               out password_out,
                               out certificate_out,
                               out a,
                               out b,
                               out c))
        {
            stdout.printf ("%s %s %s\n", nai_out, password_out, certificate_out);
        }
        else
        {
            stdout.printf ("The nai, password or service doesnt match the selected id_card\n");
        }

    } catch (DBus.Error e) {
        stderr.printf ("%s\n", e.message);
    }
}
