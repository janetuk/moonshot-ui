#if OS_WIN32
extern string? g_win32_get_package_installation_directory_of_module (void *module);
#endif

public Gdk.Pixbuf? find_icon_sized (string name, Gtk.IconSize icon_size)
{
    int width, height;
    Gtk.icon_size_lookup (icon_size, out width, out height);
    return find_icon (name, width);
}

/* Portability hack: making Gtk icon themes work on Windows is
 * difficult; let's just bundle the icons that are necessary and
 * load them manually.
 */

public Gdk.Pixbuf? find_icon (string name, int size)
{
    try
    {
#if OS_WIN32
print("Windows\n");
        string? base_path = g_win32_get_package_installation_directory_of_module (null);

        // Hack to allow running within the source tree
        int last_dir_index = base_path.last_index_of_char ('\\');
        if (base_path.substring (last_dir_index) == "\\.libs" || base_path.substring (last_dir_index) == "src")
            base_path = base_path.slice(0, last_dir_index);

        string? filename = Path.build_filename (base_path, "share", "icons", "%s.png".printf (name));
        return new Gdk.Pixbuf.from_file_at_size (filename, size, size);
//#elif OS_MACOS
/*
print("MacOS\n");
        string? base_path = " /Users/pete/moonshot-ui";
         string? filename = Filename.display_name(Path.build_filename (base_path, "share", "icons", "%s.png".printf (name)));
print("%s\n".printf(filename));
        return new Gdk.Pixbuf.from_file (filename);
//        return new Gdk.Pixbuf.from_file_at_size (filename, -1, -1);
*/
#else
print("Linux\n");
        var icon_theme = Gtk.IconTheme.get_default ();
        return icon_theme.load_icon (name, size, Gtk.IconLookupFlags.FORCE_SIZE);
#endif
    }
    catch (Error e)
    {
        stdout.printf("Error loading icon '%s': %s\n", name, e.message);
        return null;
    }
}
