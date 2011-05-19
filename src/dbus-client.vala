[DBus (name = "org.janet.Moonshot")]
interface Moonshot : Object {
    public abstract string[] get_identity (string identity, string username, string password) throws DBus.Error;
}

void main () {
    try {
        var conn = DBus.Bus.get (DBus.BusType.SESSION);
        var demo = (Moonshot) conn.get_object ("org.janet.Moonshot",
                                               "/org/janet/moonshot");

        var text = demo.get_identity ("username@issuer", "pass", "service");
        stdout.printf ("%s %s %s\n", text[0], text[1], text[2]);

    } catch (DBus.Error e) {
        stderr.printf ("%s\n", e.message);
    }
}
