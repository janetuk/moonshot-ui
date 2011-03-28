using Gtk;

class MainWindow : Window
{
    public MainWindow()
    {
        destroy.connect(Gtk.main_quit);
    }

    public static int main(string[] args)
    {
        Gtk.init(ref args);

        var window = new MainWindow();
        window.show();

        Gtk.main();

        return 0;
    }
}
