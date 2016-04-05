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
using Gtk;

class AddPasswordDialog : Dialog
{
    private Entry password_entry;
    private CheckButton remember_checkbutton;

    public string password {
        get { return password_entry.get_text(); }
    }

    public bool remember {
        get { return remember_checkbutton.get_active(); }
    }

    public AddPasswordDialog(IdCard id_card, IdentityRequest? request)
    {
        this.set_title(_("Please enter password for ") + id_card.display_name);
        this.set_modal(true);

        if (request != null) {
            this.add_buttons(_("Send"), ResponseType.OK,
                             _("Return to application"), ResponseType.CANCEL);
        } else {
            this.add_buttons(_("Done"), ResponseType.OK,
                             _("Cancel"), ResponseType.CANCEL);
        }
        this.set_default_response(ResponseType.OK);

        var content_area = this.get_content_area();
        ((Box) content_area).set_spacing(12);
        Label service_label = null;
        Label service_value = null;
        if (request != null) {
            service_label = new Label(_("for use with:"));
            service_label.set_alignment(1, (float) 0.5);
            service_value = new Label(request.service);
            service_value.set_alignment(0, (float) 0.5);
        }

        var nai_label = new Label(_("Network Access Identifier:"));
        nai_label.set_alignment(1, (float) 0.5);
        var nai_value = new Label(id_card.nai);
        nai_value.set_alignment(0, (float) 0.5);

        var password_label = new Label(_("Password:"));
        password_label.set_alignment(1, (float) 0.5);
        this.password_entry = new Entry();
        password_entry.set_invisible_char('*');
        password_entry.set_visibility(false);
        password_entry.activates_default = true;
        remember_checkbutton = new CheckButton.with_label(_("Remember password"));

        set_atk_relation(password_entry, password_entry, Atk.RelationType.LABEL_FOR);

        var table = new Table(4, 2, false);
        int row = 0;
        table.set_col_spacings(10);
        table.set_row_spacings(10);
        if (request != null) {
            table.attach_defaults(service_label, 0, 1, row, row + 1);
            table.attach_defaults(service_value, 1, 2, row, row + 1);
            row++;
        }
        table.attach_defaults(nai_label, 0, 1, row, row+1);
        table.attach_defaults(nai_value, 1, 2, row, row+1);
        row++;
        table.attach_defaults(password_label, 0, 1, row, row+1);
        table.attach_defaults(password_entry, 1, 2, row, row+1);
        row++;
        table.attach_defaults(remember_checkbutton,  1, 2, row, row+1);

        var vbox = new VBox(false, 0);
        vbox.set_border_width(6);
        vbox.pack_start(table, false, false, 0);

        ((Container) content_area).add(vbox);

        this.set_border_width(6);
        //this.set_resizable(false);
        this.show_all();
    }

    private void set_atk_relation(Widget widget, Widget target_widget, Atk.RelationType relationship)
    {
        var atk_widget = widget.get_accessible();
        var atk_target_widget = target_widget.get_accessible();

        atk_widget.add_relationship(relationship, atk_target_widget);
    }
}
