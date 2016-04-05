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

class IdCardWidget : Box
{
    public IdCard id_card { get; set; default = null; }

    private VBox main_vbox;
    private HBox table;
    public Button delete_button { get; private set; default = null; }
    public Button details_button { get; private set; default = null; }
    public Button send_button { get; private set; default = null; }
    private HButtonBox hbutton_box;
    private EventBox event_box;
    
    private Label label;

    public signal void expanded();
    public signal void remove_id();
    public signal void details_id();
    public signal void send_id();

    public void collapse()
    {
        this.hbutton_box.set_visible(false);

        set_idcard_color();
    }

    public void expand()
    {
        this.hbutton_box.set_visible(true);

        set_idcard_color();
        this.expanded();
    }

    private bool button_press_cb()
    {
        if (hbutton_box.get_visible())
            collapse();
        else
            expand();

        return false;
    }

    private void delete_button_cb()
    {
        this.remove_id();
    }

    private void details_button_cb()
    {
        this.details_id();
    }

    private void send_button_cb()
    {
        this.send_id();
    }

    private void set_idcard_color()
    {
        var color = Gdk.Color();

        if (hbutton_box.get_visible() == false)
        {
            color.red = 65535;
            color.green = 65535;
            color.blue = 65535;
        }
        else
        {
            color.red = 33333;
            color.green = 33333;
            color.blue = 60000;
        }
        var state = this.get_state();
        this.event_box.modify_bg(state, color);
    }
    
    public void
    update_id_card_label()
    {
        string services_text = "";

        var display_name = Markup.printf_escaped("<big>%s</big>", this.id_card.display_name);
        for (int i = 0; i < id_card.services.length; i++)
        {
            var service = id_card.services[i];
            
            if (i == (id_card.services.length - 1))
                services_text = services_text + Markup.printf_escaped("<i>%s</i>", service);
            else
                services_text = services_text + Markup.printf_escaped("<i>%s, </i>", service);
        }
        label.set_markup(display_name + "\n" + services_text);
    }

    public IdCardWidget(IdCard id_card)
    {
        this.id_card = id_card;

        var image = new Image.from_pixbuf(get_pixbuf(id_card));

        label = new Label(null);
        label.set_alignment((float) 0, (float) 0.5);
        label.set_ellipsize(Pango.EllipsizeMode.END);
        update_id_card_label();

        table = new Gtk.HBox(false, 6);
        table.pack_start(image, false, false, 0);
        table.pack_start(label, true, true, 0);

        this.delete_button = new Button.with_label(_("Delete"));
        this.details_button = new Button.with_label(_("View details"));
        this.send_button = new Button.with_label(_("Send"));
        set_atk_name_description(delete_button, _("Delete"), _("Delete this ID Card"));
        set_atk_name_description(details_button, _("Details"), _("View the details of this ID Card"));
        set_atk_name_description(send_button, _("Send"), _("Send this ID Card"));
        this.hbutton_box = new HButtonBox();
        hbutton_box.pack_end(delete_button);
        hbutton_box.pack_end(details_button);
        hbutton_box.pack_end(send_button);
        send_button.set_sensitive(false);

        delete_button.clicked.connect(delete_button_cb);
        details_button.clicked.connect(details_button_cb);
        send_button.clicked.connect(send_button_cb);

        this.main_vbox = new VBox(false, 12);
        main_vbox.pack_start(table, true, true, 0);
        main_vbox.pack_start(hbutton_box, false, false, 0);
        main_vbox.set_border_width(12);

        event_box = new EventBox();
        event_box.add(main_vbox);
        event_box.button_press_event.connect(button_press_cb);
        this.pack_start(event_box, true, true);

        this.show_all();
        this.hbutton_box.hide();

        set_idcard_color();
    }

    private void set_atk_name_description(Widget widget, string name, string description)
    {
        var atk_widget = widget.get_accessible();

        atk_widget.set_name(name);
        atk_widget.set_description(description);
    }
}
