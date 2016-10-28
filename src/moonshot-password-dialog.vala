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

class AddPasswordDialog : Dialog
{
    private static Gdk.Color white = make_color(65535, 65535, 65535);

    private Entry password_entry;
    private CheckButton remember_checkbutton;

    public string password {
        get { return password_entry.get_text(); }
    }

    /**
     * Don't leave passwords in memory longer than necessary.
     * This may not actually erase the password data bytes, but it seems to be the best we can do.
     */
    public void clear_password() {
        clear_password_entry(password_entry);
    }

    public bool remember {
        get { return remember_checkbutton.get_active(); }
    }

    public AddPasswordDialog(IdCard id_card, IdentityRequest? request)
    {
        this.set_title(_("Moonshot - Password"));
        this.set_modal(true);
        set_bg_color(this);

        this.add_buttons(_("Cancel"), ResponseType.CANCEL,
                         _("Connect"), ResponseType.OK);

        this.set_default_response(ResponseType.OK);

        var content_area = this.get_content_area();
        ((Box) content_area).set_spacing(12);
        set_bg_color(content_area);

        Label dialog_label = new Label(_("Enter the password for ") + id_card.display_name);
        dialog_label.set_alignment(0, 0);

        var nai_label = new Label(_("User (NAI):"));
        nai_label.set_alignment(0, 1);
        var nai_value = new Label(id_card.nai);
        nai_value.set_alignment(0, 0);

        var password_label = new Label(_("Password:"));
        password_label.set_alignment(0, (float) 1);
        this.password_entry = new Entry();
        password_entry.set_invisible_char('*');
        password_entry.set_visibility(false);
        password_entry.activates_default = true;
        remember_checkbutton = new CheckButton.with_label(_("Remember password"));

        set_atk_relation(password_label, password_entry, Atk.RelationType.LABEL_FOR);

        var table = new Table(6, 1, false);
        AttachOptions opts = AttachOptions.EXPAND | AttachOptions.FILL;
        int row = 0;
        table.set_col_spacings(6);
        table.set_row_spacings(0);
        table.attach(dialog_label, 0, 1, row, row + 1, opts, opts, 0, 2);
//            table.attach_defaults(service_value, 1, 2, row, row + 1);
        row++;

        VBox nai_vbox = new VBox(false, 0);
        nai_vbox.pack_start(nai_label, false, false, 0);
        nai_vbox.pack_start(nai_value, false, false, 0);
        table.attach(nai_vbox, 0, 1, row, row + 1, opts, opts, 0, 12);
        row++;

        VBox password_vbox = new VBox(false, 1);
        var empty_box2 = new VBox(false, 0);
        empty_box2.set_size_request(0, 0);
        password_vbox.pack_start(empty_box2, false, false, 3);
        password_vbox.pack_start(password_label, false, false, 0);
        password_vbox.pack_start(password_entry, false, false, 0);
        table.attach(password_vbox, 0, 1, row, row + 1, opts, opts, 0, 0);
        row++;

        table.attach(remember_checkbutton,  0, 1, row, row + 1, opts, opts, 20, 2);
        row++;

        var empty_box3 = new VBox(false, 0);
        empty_box3.set_size_request(0, 0);
        table.attach(empty_box3,  0, 1, row, row + 1, opts, opts, 0, 10);
        row++;

        var vbox = new VBox(false, 0);
        vbox.set_border_width(6);
        vbox.pack_start(table, false, false, 0);

        ((Container) content_area).add(vbox);

        this.set_border_width(6);
        //this.set_resizable(false);
        this.show_all();
    }
}
