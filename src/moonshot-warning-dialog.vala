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

static const string GROUP_NAME="WarningDialogs";

// MessageDialog doesn't allow subclassing, so we merely wrap the
// constructor for it the dialog, and then run it, returning the result.
class WarningDialog 
{
    private static MoonshotLogger _logger = null;
    private static MoonshotLogger logger()
        {
            if (_logger == null) {
                _logger = get_logger("WarningDialog");
            }
            return _logger;
        }

    public static bool confirm(Window parent, string message, string dialog_name)
    {

        if (get_bool_setting(GROUP_NAME, dialog_name, false))
        {
            logger().trace(@"confirm: Settings group $GROUP_NAME has 'true' for key $dialog_name; skipping dialog and returning true.");
            return true;
        }

        Gdk.Color white = make_color(65535, 65535, 65535);

        MessageDialog dialog = new Gtk.MessageDialog(parent,
                                                     Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                                     Gtk.MessageType.WARNING,
                                                     Gtk.ButtonsType.YES_NO,
                                                     "");

        var content_area = dialog.get_content_area();
        CheckButton remember_checkbutton = null;

        if (dialog_name != null && dialog_name != "")
        {
            remember_checkbutton = new CheckButton.with_label(_("Do not show this message again"));
            // remember_checkbutton.set_focus_on_click(false);
            // remember_checkbutton.set_can_focus(false);
            // remember_checkbutton.has_focus = false;
            remember_checkbutton.set_receives_default(false);
            Container action_area = (Container) dialog.get_action_area();

            // This is awful, because it assumes the Yes button is first in the
            // children (and for that matter, it assumes there are no intermediate
            // containers.) But searching for "Yes" in the widget text would
            // cause localization problems.
            // TODO: Rewrite to use Dialog instead of MessageDialog?
            var yes_button = action_area.get_children().first().data;
            yes_button.grab_default();
            yes_button.grab_focus();

// Not sure if 0.26 is the minimum for MessageDialog.get_message_area. 0.16 sure isn't :-(
#if VALA_0_26
            var message_area = dialog.get_message_area();
            ((Box)message_area).pack_start(remember_checkbutton, false, false, 12);
#else
            HBox hbox = new HBox(false, 0);
            hbox.pack_start(new HBox(false, 0), true, true, 20);
            hbox.pack_start(remember_checkbutton, false, false, 12);
            ((Box)content_area).pack_start(hbox, true, true, 12);
#endif
        }

        // dialog.set_modal(true);
        dialog.set_title(_("Warning"));
        set_bg_color(dialog);

        // ((Box) content_area).set_spacing(12);
        set_bg_color(content_area);

        content_area.show_all();

        dialog.set_markup(message);

        var ret = dialog.run();

        if (ret == Gtk.ResponseType.YES && remember_checkbutton != null && remember_checkbutton.active)
        {
            set_bool_setting(GROUP_NAME, dialog_name, true);
        }

        dialog.destroy();
        return (ret == Gtk.ResponseType.YES);
    }
}
