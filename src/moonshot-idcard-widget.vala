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

class IdCardWidget : Box
{
    // static MoonshotLogger logger = get_logger("IdCardWidget");

    private static const ShadowType ARROW_SHADOW = ShadowType.NONE;

    private IdentityManagerView manager_view;

    public IdCard id_card { get; set; default = null; }
    private VBox main_vbox;
    private HBox hbox;
    private EventBox event_box;
    private bool   is_selected = false;
    private Arrow arrow;
    
    private VBox details;

    internal int _position = 0;
    internal int position {
        get {return _position;}
        set {_position = value; set_idcard_color();}
    }

    public signal void expanded();
    public signal void collapsed();

    internal void select()
    {
        expand();
        this.expanded();
    }

    internal void unselect()
    {
        collapse();
        this.collapsed();
    }

    public void expand()
    {
        is_selected = true;
        details.show_all();

        set_idcard_color();
        arrow.set(ArrowType.DOWN, ARROW_SHADOW);
    }

    public void collapse()
    {
        is_selected = false;
        details.hide();

        set_idcard_color();
        arrow.set(ArrowType.RIGHT, ARROW_SHADOW);
    }

    private bool button_press_cb()
    {
        if (is_selected)
            unselect();
        else
            select();

        return false;
    }

    private void set_idcard_color()
    {
        var color = Gdk.Color();

        if (is_selected)
        {
                color.red = 0xd9 << 8;
                color.green = 0xf7 << 8;
                color.blue = 65535;
        }
        else {
            if (position % 2 == 0)
            {
                color.red = color.green = color.blue = 0xf2 << 8;
            }
            else
            {
                color.red = 65535;
                color.green = 65535;
                color.blue = 65535;

            }
        }
        this.event_box.modify_bg(StateType.NORMAL, color);
        this.arrow.modify_bg(StateType.NORMAL, color);
    }
    
    private void
    make_id_card_label(Label label)
    {
        var display_name = (manager_view.selection_in_progress() && this.id_card.is_no_identity()
                            ? _("Do not use a Moonshot identity for this service") : this.id_card.display_name);
        var label_text = Markup.printf_escaped("<span rise='8000'><big>%s</big></span>", display_name);

        label.set_markup(label_text);
    }

    public IdCardWidget(IdCard id_card, IdentityManagerView manager_view)
    {
        this.id_card = id_card;
        this.manager_view = manager_view;

        var display_name_label = new Label(null);
        display_name_label.set_alignment((float) 0, (float) 0.5);
        display_name_label.set_ellipsize(Pango.EllipsizeMode.END);
        make_id_card_label(display_name_label);

        var details_wrapper = new VBox(false, 0);
        details_wrapper.pack_start(display_name_label, false, false, 0);
        this.details = new VBox(false, 0);
        details_wrapper.pack_start(details, false, false, 0);

        if (!this.id_card.is_no_identity()) {
            var upper_details_text = _("Username") + ":  " + id_card.username;
            upper_details_text += "\n" + _("Realm:") + "  " + id_card.issuer;
            if (!id_card.trust_anchor.is_empty()) {
                upper_details_text += "\n" + _("Trust anchor: Enterprise provisioned");
            }
            Label upper_details = new Label(upper_details_text);
            upper_details.set_alignment(0, 0);
            details.pack_start(upper_details);
        }
        var services_hbox = new HBox(false, 6);
        Label services_label = new Label(_("Services: "));
        services_label.set_alignment(0, 0);

        string services_text = this.id_card.get_services_string("\n");
        Label service_list = new Label(services_text);
        service_list.set_alignment(0, 0);
        service_list.set_ellipsize(Pango.EllipsizeMode.END);
        service_list.set_max_width_chars(50);
        services_hbox.pack_start(services_label, false, false, 0);
        services_hbox.pack_start(service_list, false, false, 0);
        details.pack_start(services_hbox);

        hbox = new Gtk.HBox(false, 6);
        var image = new Image.from_pixbuf(get_pixbuf(id_card));
        if (this.id_card.is_no_identity()) {
            image.clear();
            // Use padding to make the image size =  48x48 (size = 2x padding)
            image.set_padding(24, 24);
        }
        hbox.pack_start(image, false, false, 0);
        hbox.pack_start(details_wrapper, true, true, 0);
        this.arrow = new Arrow(ArrowType.RIGHT, ARROW_SHADOW);
        this.arrow.set_alignment((float) 0.5, (float) 0);
        hbox.pack_start(arrow, false, false);

        this.main_vbox = new VBox(false, 12);
        main_vbox.pack_start(hbox, true, true, 0);
        main_vbox.set_border_width(12);

        event_box = new EventBox();
        event_box.add(main_vbox);
        event_box.button_press_event.connect(button_press_cb);
        event_box.set_visible(false);
        this.pack_start(event_box, true, true);

        this.show_all();
        details.hide();

        set_idcard_color();
    }
}
