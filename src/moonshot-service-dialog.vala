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

class AddServiceDialog : Dialog
{
    private Entry service_entry;

    public string service {
        get { return service_entry.get_text(); }
    }

    public AddServiceDialog(Gtk.Window parent)
    {
        this.set_title(_("Moonshot - Service"));
        this.set_modal(true);
        set_bg_color(this);
        set_transient_for(parent);

        this.add_buttons(_("Cancel"), ResponseType.CANCEL,
                         _("Add"), ResponseType.OK);

        this.set_default_response(ResponseType.OK);

        var content_area = this.get_content_area();
        ((Box) content_area).set_spacing(12);
        set_bg_color(content_area);

        var service_label = new Label(_("Add the name of the service you want to associate to this identity:"));
        service_label.set_alignment(0, (float) 1);
        this.service_entry = new Entry();
        service_entry.activates_default = true;
        set_atk_relation(service_label, service_entry, Atk.RelationType.LABEL_FOR);

        var table = new Table(6, 1, false);
        AttachOptions opts = AttachOptions.EXPAND | AttachOptions.FILL;
        int row = 0;
        table.set_col_spacings(6);
        table.set_row_spacings(0);
        row++;

        Box service_vbox = new_vbox(1);
        var empty_box2 = new_vbox(0);
        empty_box2.set_size_request(0, 0);
        service_vbox.pack_start(empty_box2, false, false, 3);
        service_vbox.pack_start(service_label, false, false, 0);
        service_vbox.pack_start(service_entry, false, false, 0);
        table.attach(service_vbox, 0, 1, row, row + 1, opts, opts, 0, 0);
        row++;

        var vbox = new_vbox(0);
        vbox.set_border_width(6);
        vbox.pack_start(table, false, false, 0);

        ((Container) content_area).add(vbox);

        this.set_border_width(6);
        //this.set_resizable(false);
        this.show_all();
    }
}

