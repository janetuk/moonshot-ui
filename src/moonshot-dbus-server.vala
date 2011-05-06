[DBus (name = "org.janet.Moonshot")]
public class MoonshotServer : Object {
    private int counter;

    public int ping (string msg)
    {
        stdout.printf ("%s\n", msg);
        return counter++;
    }

    public string[] get_identity (string identity,
                                  string password,
                                  string service)
    {
        string[3] information = {"identity", "password", "certificate"};

        return information;
    }
}
