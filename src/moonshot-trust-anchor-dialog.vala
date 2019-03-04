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

extern int parse_hex_certificate(char* hex_str, char *sha256_hex_fingerprint,
                                 char* cert_text, int cert_text_len);


public delegate void TrustAnchorConfirmationCallback(TrustAnchorConfirmationRequest request);

public class TrustAnchorConfirmationRequest : GLib.Object {
    static MoonshotLogger logger = get_logger("TrustAnchorConfirmationRequest");

    IdentityManagerApp parent_app;
    public string userid;
    public string realm;
    public string fingerprint;
    public string cert_text;
    public string issuer;
    public string subject;
    public string expiration_date;

    public bool confirmed = false;

    TrustAnchorConfirmationCallback callback = null;

    public TrustAnchorConfirmationRequest(IdentityManagerApp parent_app,
                                          string userid,
                                          string realm,
                                          string cert_data)
    {
        this.parent_app = parent_app;
        this.userid = userid;
        this.realm = realm;
        this.fingerprint = "Not available";
        this.cert_text = "Not available";

        uint8 finger[65], cert_text[4096];
        int rv = parse_hex_certificate(cert_data, finger, cert_text, 4096);
        if (rv > 0) {
            this.fingerprint = (string) finger;
            this.cert_text = (string) cert_text;
        }
        else {
            this.fingerprint = cert_data;
        }
    }

    public void set_callback(owned TrustAnchorConfirmationCallback cb)
    {
#if VALA_0_12
            this.callback = ((owned) cb);
#else
           this.callback = ((IdCard) => cb(IdCard));
#endif
    }

    public bool execute() {
        string nai = userid + "@" + realm;
        IdCard? card = parent_app.model.find_id_card(nai, parent_app.use_flat_file_store);
        if (card == null)
            card = parent_app.model.find_decorated_id_card(userid, realm, parent_app.use_flat_file_store);

        if (card == null) {
            logger.warn(@"execute: Could not find ID card for NAI $nai; returning false.");
            return_confirmation(false);
            return false;
        }

        if (!(card.trust_anchor.is_empty() || card.trust_anchor.get_anchor_type() == TrustAnchor.TrustAnchorType.SERVER_CERT)) {
            logger.warn(@"execute: Trust anchor type for NAI $nai is not empty or SERVER_CERT; returning true.");
            return_confirmation(true);
            return false;
        }

        logger.trace("execute: expected cert='%s'; fingerprint='%s'".printf(card.trust_anchor.server_cert, fingerprint));
        if (card.trust_anchor.server_cert.up() == fingerprint.up()) {
            logger.trace(@"execute: Fingerprint for $nai matches stored value; returning true.");
            return_confirmation(true);
            return false;
        }

        if (parent_app.view == null) {
            logger.trace(@"execute: Running in headless mode; returning false.");
            return_confirmation(false);
            return false;
        }

        bool is_confirmed = parent_app.view.confirm_trust_anchor(card, this);
        if (is_confirmed) {
            logger.trace(@"execute: Fingerprint confirmed; updating stored value.");

            card.trust_anchor.update_server_fingerprint(fingerprint);
            parent_app.model.update_card(card);
        }

        return_confirmation(is_confirmed);

        /* This function works as a GSourceFunc, so it can be passed to
         * the main loop from other threads
         */
        return false;
    }

    private void return_confirmation(bool confirmed) {
        return_if_fail(callback != null);

        this.confirmed = confirmed;
        logger.trace(@"return_confirmation: confirmed=$confirmed");

        // Send back the confirmation (we can't directly run the
        // callback because we may be being called from a 'yield')
        GLib.Idle.add(
            () => {
                logger.trace("return_confirmation[Idle handler]: invoking callback");
                callback(this);
                return false;
            }
        );
    }
}



class TrustAnchorDialog : Dialog
{
    public bool complete = false;
    private TrustAnchorConfirmationRequest request;

    public TrustAnchorDialog(IdCard card, TrustAnchorConfirmationRequest request)
    {
        string server_ta_label_text = _("Server's trust anchor certificate (SHA-256 fingerprint):");
        this.request = request;
        this.set_title(_("Trust Anchor"));
        this.set_modal(true);
//        this.set_transient_for(parent);
        set_bg_color(this);

        this.add_buttons(_("Cancel"), ResponseType.CANCEL,
                         _("Confirm"), ResponseType.OK);

        this.set_default_response(ResponseType.CANCEL);

        var content_area = this.get_content_area();
        ((Box) content_area).set_spacing(12);
        set_bg_color(content_area);

        Label dialog_label = new Label("");
        dialog_label.set_alignment(0, 0);

        string label_markup;
        if (card.trust_anchor.server_cert == "") {
            label_markup = "<span font-weight='heavy'>"
            + _("You are using this identity for the first time with the following trust anchor:") + "</span>";
        }
        else {
            // The server's fingerprint isn't what we're expecting this server to provide.
            label_markup = "<span font-weight='heavy'>" +
            _("WARNING: The certificate we received for the authentication server for %s").printf(card.issuer)
            + _(" is different than expected.\nEither the server certificate has changed, or an")
            + _(" attack may be underway.\nIf you proceed to the wrong server, your login credentials may be compromised.")
            + "</span>";
        }

        dialog_label.set_markup(label_markup);
        dialog_label.set_line_wrap(true);
        dialog_label.set_width_chars(60);

        var user_label = new Label(_("Username: ") + request.userid);
        user_label.set_alignment(0, 0.5f);

        var realm_label = new Label(_("Realm: ") + request.realm);
        realm_label.set_alignment(0, 0.5f);

        string confirm_text = _("\nPlease check with your realm administrator for the correct fingerprint")
        + _(" for your authentication server.\nIf it matches the above fingerprint,")
        + _(" confirm the change.  If not, then cancel.");

        Label confirm_label = new Label(confirm_text);
        confirm_label.set_alignment(0, 0.5f);
        confirm_label.set_line_wrap(true);
        confirm_label.set_width_chars(60);

        var view_button = new Button.with_label(_("View Server Certificate"));
        view_button.clicked.connect((w) => {view_certificate();});

        var trust_anchor_display = make_ta_fingerprint_widget(request.fingerprint, server_ta_label_text);

        var vbox = new_vbox(0);
        vbox.set_border_width(6);
        vbox.pack_start(dialog_label, true, true, 12);
        vbox.pack_start(user_label, true, true, 2);
        vbox.pack_start(realm_label, true, true, 2);
        vbox.pack_start(trust_anchor_display, true, true, 0);
        var hbox = new_hbox(0);
        hbox.pack_start(view_button, false, false, 0);
        vbox.pack_start(hbox, false, false, 0);
        vbox.pack_start(confirm_label, true, true, 12);

        ((Container) content_area).add(vbox);

        this.set_border_width(6);
        this.set_resizable(false);

        this.response.connect(on_response);
        this.show_all();
    }

    private void view_certificate()
    {
        string message = "Could not load certificate!";
        if (this.request.cert_text != "")
            message = (string) this.request.cert_text;
        var dialog = new Gtk.MessageDialog(this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                           Gtk.MessageType.INFO, Gtk.ButtonsType.OK,
                                           "The following is the information extracted from the Server certificate.");
        Box content = (Box) dialog.get_content_area();
        content.add(make_ta_fingerprint_widget(message, "", false, 400, true));
        dialog.set_size_request(700, -1);
        dialog.show_all();
        dialog.run();
        dialog.destroy();
    }

    private void on_response(Dialog source, int response_id)
    {
        switch (response_id) {
        case ResponseType.OK:
            complete = true;
            break;
        case ResponseType.CANCEL:
            complete = true;
            break;
        }
    }
}
