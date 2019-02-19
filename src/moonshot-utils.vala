/*
 * Copyright (c) 2011-2016, JANET(UK)
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

using Gtk;
using Pango;

#if OS_WIN32
extern string? g_win32_get_package_installation_directory_of_module(void *module);
#endif

public Gdk.Pixbuf? find_icon_sized(string name, Gtk.IconSize icon_size)
{
    int width, height;
    Gtk.icon_size_lookup(icon_size, out width, out height);
    return find_icon(name, width);
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

public Gdk.Pixbuf? find_icon(string name, int size)
{
    if (!gtk_available)
        return null;
    try
    {
#if OS_WIN32
        string? base_path = g_win32_get_package_installation_directory_of_module(null);

        // Hack to allow running within the source tree
        int last_dir_index = base_path.last_index_of_char('\\');
        if (base_path.substring(last_dir_index) == "\\.libs" || base_path.substring(last_dir_index) == "src")
            base_path = base_path.slice(0, last_dir_index);

        string? filename = Path.build_filename(base_path, "share", "icons", "%s.png".printf(name));
        return new Gdk.Pixbuf.from_file_at_size(filename, size, size);

#else
        var icon_theme = Gtk.IconTheme.get_default();
        return icon_theme.load_icon(name, size, Gtk.IconLookupFlags.FORCE_SIZE);
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

internal Gdk.Color make_color(uint16 red, uint16 green, uint16 blue)
{
    Gdk.Color color = Gdk.Color();
    color.red = red;
    color.green = green;
    color.blue = blue;

    return color;
}

internal void set_atk_relation(Widget widget, Widget target_widget, Atk.RelationType relationship)
{
    var atk_widget = widget.get_accessible();
    var atk_target_widget = target_widget.get_accessible();

    atk_widget.add_relationship(relationship, atk_target_widget);
}


internal Widget make_ta_fingerprint_widget(string server_cert, string? label_text = null, bool do_colonize=true)
{
    var fingerprint_label = new Label(label_text ?? _("SHA-256 fingerprint:"));
    fingerprint_label.set_alignment(0, 0.5f);

    var fingerprint = new TextView();
    var fontdesc = FontDescription.from_string("monospace 10");
    fingerprint.modify_font(fontdesc);
    fingerprint.set_editable(false);
    fingerprint.set_left_margin(3);
    var buffer = fingerprint.get_buffer();
    if (do_colonize)
        buffer.set_text(colonize(server_cert, 16), -1);
    else
        buffer.set_text(server_cert, -1);
    fingerprint.wrap_mode = Gtk.WrapMode.WORD_CHAR;

    set_atk_relation(fingerprint_label, fingerprint, Atk.RelationType.LABEL_FOR);

    var fingerprint_width_constraint = new ScrolledWindow(null, null);
    fingerprint_width_constraint.set_policy(PolicyType.NEVER, PolicyType.NEVER);
    fingerprint_width_constraint.set_shadow_type(ShadowType.IN);
    fingerprint_width_constraint.set_size_request(400, 30);
    fingerprint_width_constraint.add_with_viewport(fingerprint);

    var vbox = new_vbox(0);
    vbox.pack_start(fingerprint_label, true, true, 2);
    vbox.pack_start(fingerprint_width_constraint, true, true, 2);
    return vbox;
}

    // Yeah, it doesn't mean "colonize" the way you might think... :-)
internal static string colonize(string input, int bytes_per_line) {
    return_if_fail(input.length % 2 == 0);

    string result = "";
    int i = 0;
    int line_bytes = 0;
    while (i < input.length) {
        if (line_bytes == bytes_per_line) {
            result += "\n";
            line_bytes = 0;
        }
        else if (i > 0) {
            result += ":";
        }
        result += input[i : i + 2];
        i += 2;
        line_bytes++;
    }
    return result;
}

internal static void clear_password_entry(Entry entry) {

    // Overwrite the entry with random data
    var len = entry.get_text().length;
    var random_chars = new char[len + 1];
    for (int i = 0; i < len; i++) {
        random_chars[i] = (char) Random.int_range(40, 127);
    }
    random_chars[len] = 0;
    string r = (string) random_chars;
    var buf = entry.get_buffer();
#if VALA_0_12
    // Not sure if this works in 12; it definitely doesn't work in 10.
    buf.set_text(r.data);

    // Now delete the data
    buf.delete_text(0, len);
#else
    string[] a = new string[1];
    a[0] = r;
    buf.set_text(a);

    // Now delete the data
    buf.delete_text(0, (int) len);
#endif
}

static void set_bg_color(Widget w)
{
#if OS_WIN32

    static Gdk.Color white;
    if (white == null) {
        white = make_color(65535, 65535, 65535);
    }

    w.modify_bg(StateType.NORMAL, white);

#endif
}

static Box new_vbox(int spacing)
{
    return new VBox(false, spacing);
}

static Box new_hbox(int spacing)
{
    return new HBox(false, spacing);
}
