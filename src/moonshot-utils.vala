/*
 * Copyright (c) 2011-2014, JANET(UK)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of JANET(UK) nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
*/
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

public bool gtk_available = false;

public Gdk.Pixbuf? get_pixbuf(IdCard id)
{
    return find_icon("avatar-default", 48);
}

public Gdk.Pixbuf? find_icon (string name, int size)
{
    if (!gtk_available)
        return null;
    try
    {
#if OS_WIN32
        string? base_path = g_win32_get_package_installation_directory_of_module (null);

        // Hack to allow running within the source tree
        int last_dir_index = base_path.last_index_of_char ('\\');
        if (base_path.substring (last_dir_index) == "\\.libs" || base_path.substring (last_dir_index) == "src")
            base_path = base_path.slice(0, last_dir_index);

        string? filename = Path.build_filename (base_path, "share", "icons", "%s.png".printf (name));
        return new Gdk.Pixbuf.from_file_at_size (filename, size, size);

#else
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

public extern unowned string GetUserName();
public extern unowned string GetFlatStoreUsersFilePath();

public bool UserForcesFlatFileStore()
{
    string username = GetUserName();
    string flatstore_users_filename = GetFlatStoreUsersFilePath();
    FileStream flatstore_users = FileStream.open(flatstore_users_filename, "r");
    if (flatstore_users == null) {
        return false;
    }
    string? flatstore_username = null;
    while ((flatstore_username = flatstore_users.read_line()) != null) {
        if (username == flatstore_username) {
            return true;
        }
    }
    return false;
}
