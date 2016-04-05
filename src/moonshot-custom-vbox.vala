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

class CustomVBox : VBox
{
    public IdCardWidget current_idcard { get; set; default = null; }
    private IdentityManagerView main_window; 

    public CustomVBox(IdentityManagerView window, bool homogeneous, int spacing)
    {
        main_window = window;
        set_homogeneous(homogeneous);
        set_spacing(spacing);
    }

    public void receive_expanded_event(IdCardWidget id_card_widget)
    {
        var list = get_children();
        foreach (Widget id_card in list)
        {
            if (id_card != id_card_widget)
                ((IdCardWidget) id_card).collapse();
        }
        current_idcard = id_card_widget;
        
        if (current_idcard != null && main_window.request_queue.length > 0)
            current_idcard.send_button.set_sensitive(true);
        check_resize();
    }

    public void add_id_card_widget(IdCardWidget id_card_widget)
    {
        pack_start(id_card_widget, false, false);
    }

    public void remove_id_card_widget(IdCardWidget id_card_widget)
    {
        remove(id_card_widget);
    }
}
