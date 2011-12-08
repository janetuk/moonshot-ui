using Gtk;

class IdentityManagerApp : Window {
    private MainWindow main_window;
    
    public IdentityManagerApp () {
        main_window = new MainWindow();
        main_window.show();
    }
    
/*    public int run(string[] args){
        GLib.Application.run(args);
     }*/
    public static int main(string[] args)
    {
        Gtk.init(ref args);

#if OS_WIN32
        // Force specific theme settings on Windows without requiring a gtkrc file
        Gtk.Settings settings = Gtk.Settings.get_default ();
        settings.set_string_property ("gtk-theme-name", "ms-windows", "moonshot");
        settings.set_long_property ("gtk-menu-images", 0, "moonshot");
#endif

        Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
        Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (Config.GETTEXT_PACKAGE);
        
        var app = new IdentityManagerApp();
        
//        app.show();
 
        Gtk.main();

        return 0;
    }
}

