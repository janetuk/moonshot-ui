using Gtk;

class MoonshotWindow
{
    private Gtk.Window window;

    public MoonshotWindow()
    {
        window = new Gtk.Window();
        window.destroy.connect(Gtk.main_quit);
    }

    public void show()
    {
        window.show();
    }

    public static int main(string[] args)
    {
        Gtk.init(ref args);

        var window = new MoonshotWindow();
        window.show ();

        Gtk.main();

        return 0;
    }
}
