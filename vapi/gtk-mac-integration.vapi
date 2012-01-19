/*
 * Vala Bindings for gtk-mac-integration-1.0.1
 *
 */
    [CCode(cheader_filename="gtkosxapplication.h")]
	public class Gtk.OSXApplication : GLib.Object {
		[CCode(cname="GTK_TYPE_OSX_APPLICATION")]
		public static GLib.Type GTK_TYPE_OSX_APPLICATION;

		public static Gtk.OSXApplication get_instance() {
			return (Gtk.OSXApplication) GLib.Object.new(GTK_TYPE_OSX_APPLICATION);
		}
		
	    [CCode(cname="gtk_osxapplication_ready")]
	    public void ready();
	    
    /*Menu functions*/
	
	    [CCode(cname="gtk_osxapplication_set_menu_bar")]
	    public void set_menu_bar(Gtk.MenuShell shell);

	    [CCode(cname="gtk_osxapplication_sync_menubar")]
	    public void sync_menu_bar();
	
	    [CCode(cname="gtk_osxapplication_insert_app_menu_item")]
	    public void insert_app_menu_item(Gtk.Widget menu_item, int index);

        	[CCode(cname="gtk_osxapplication_set_window_menu")]
        	public void set_window_menu (Gtk.MenuItem menu_item);

        [CCode(cname="gtk_osxapplication_set_help_menu")]
        public void set_help_menu (Gtk.MenuItem menu_item);

	/*Accelerator functions*/
	
	    [CCode(cname="gtk_osxapplication_set_use_quartz_accelerators")]
	    public void set_use_quartz_accelerators(bool use_quartz_accelerators);
	
	    [CCode(cname="gtk_osxapplication_use_quartz_accelerators")]
	    public bool use_quartz_accelerators();

    /* Signals */

       [CCode(cname="NSApplicationOpenFile")]
        public signal bool ns_application_open_file(string file_name);
    }

