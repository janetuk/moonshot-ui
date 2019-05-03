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

using Markup;

namespace WebProvisioning
{
    bool check_stack(SList<string> stack, string[] reference) {

        if (stack.length() < reference.length)
            return false;

        for (int i = 0; i < reference.length; i++)
        {
            if (stack.nth_data(i) != reference[i])
                return false;
        }

        return true;
    }

    bool always_confirm_handler(SList<string> stack)
    {
        string[] always_confirm_path = {"always-confirm", "rule", "selection-rules", "identity", "identities"};

        return check_stack(stack, always_confirm_path);
    }

    bool
    pattern_handler(SList<string> stack)
    {
        string[] pattern_path = {"pattern", "rule", "selection-rules", "identity", "identities"};

        return check_stack(stack, pattern_path);
    }

    bool server_cert_handler(SList<string> stack)
    {
        string[] server_cert_path = {"server-cert", "trust-anchor", "identity", "identities"};

        return check_stack(stack, server_cert_path);
    }

    bool subject_alt_handler(SList<string> stack)
    {
        string[] subject_alt_path = {"subject-alt", "trust-anchor", "identity", "identities"};

        return check_stack(stack, subject_alt_path);
    }

    bool subject_handler(SList<string> stack)
    {
        string[] subject_path = {"subject", "trust-anchor", "identity", "identities"};

        return check_stack(stack, subject_path);
    }

    bool ca_cert_handler(SList<string> stack)
    {
        string[] ca_path = {"ca-cert", "trust-anchor", "identity", "identities"};

        return check_stack(stack, ca_path);
    }

    bool realm_handler(SList<string> stack)
    {
        string[] realm_path = {"realm", "identity", "identities"};

        return check_stack(stack, realm_path);
    }

    bool password_handler(SList<string> stack)
    {
        string[] password_path = {"password", "identity", "identities"};

        return check_stack(stack, password_path);
    }

    bool has2fa_handler(SList<string> stack)
    {
        string[] has2fa_path = {"has2fa", "identity", "identities"};

        return check_stack(stack, has2fa_path);
    }

    bool user_handler(SList<string> stack)
    {
        string[] user_path = {"user", "identity", "identities"};

        return check_stack(stack, user_path);
    }

    bool display_name_handler(SList<string> stack)
    {
        string[] display_name_path = {"display-name", "identity", "identities"};

        return check_stack(stack, display_name_path);
    }

    public class Parser : Object
    {
        private static MoonshotLogger logger = new MoonshotLogger("WebProvisioning");

        private void start_element_func(MarkupParseContext context,
                                        string element_name,
                                        string[] attribute_names,
                                        string[] attribute_values) throws MarkupError
        {
            if (element_name == "identity")
            {
                card = new IdCard();
                _cards += card;

                ta_ca_cert = "";
                ta_server_cert = "";
                ta_subject = "";
                ta_subject_alt = "";
            }
            else if (element_name == "rule")
            {
                card.add_rule(Rule());
            }
        }

        private void end_element_func(MarkupParseContext context,
                                      string element_name) throws MarkupError
        {
            if (element_name == "identity")
            {
                if (ta_ca_cert != "" || ta_server_cert != "") {
                    var ta = new TrustAnchor(ta_ca_cert,
                                             ta_server_cert,
                                             ta_subject,
                                             ta_subject_alt);
                    // Set the datetime_added in moonshot-server.vala, since it doesn't get sent via IPC
                    card.set_trust_anchor_from_store(ta);
                }
            }
        }

        private void
        text_element_func(MarkupParseContext context,
                          string             text,
                          size_t             text_len) throws MarkupError {
            unowned SList<string> stack = context.get_element_stack();

            if (text_len < 1)
                return;

            if (stack.nth_data(0) == "display-name" && display_name_handler(stack))
            {
                card.display_name = text;
            }
            else if (stack.nth_data(0) == "user" && user_handler(stack))
            {
                card.username = text;
            }
            else if (stack.nth_data(0) == "password" && password_handler(stack))
            {
                card.password = text;
				if ((card.password != null) && (card.password != ""))
					card.store_password = true;
            }
            else if (stack.nth_data(0) == "realm" && realm_handler(stack))
            {
                card.issuer = text;
            }
            else if (stack.nth_data(0) == "service")
            {
                card.services.add(text);
            }
            else if (stack.nth_data(0) == "has2fa" && has2fa_handler(stack))
            {
                if (text == "true" || text == "yes")
                    card.has_2fa = true;
                else
                    card.has_2fa = false;
            }

            /* Rules */
            else if (stack.nth_data(0) == "pattern" && pattern_handler(stack))
            {
                /* use temp array to workaround valac 0.10 bug accessing array property length */
                var temp = card.rules;
                card.rules[temp.length - 1].pattern = text;
            }
            else if (stack.nth_data(0) == "always-confirm" && always_confirm_handler(stack))
            {
                if (text == "true" || text == "false") {
                    /* use temp array to workaround valac 0.10 bug accessing array property length*/
                    var temp = card.rules;
                    card.rules[temp.length - 1].always_confirm = text;
                }
            }
            else if (stack.nth_data(0) == "ca-cert" && ca_cert_handler(stack))
            {
                ta_ca_cert = text ?? "";
            }
            else if (stack.nth_data(0) == "server-cert" && server_cert_handler(stack))
            {
                ta_server_cert = text ?? "";
            }
            else if (stack.nth_data(0) == "subject" && subject_handler(stack))
            {
                ta_subject = text;
            }
            else if (stack.nth_data(0) == "subject-alt" && subject_alt_handler(stack))
            {
                ta_subject_alt = text;
            }
        }

        private const MarkupParser parser = {
            start_element_func, end_element_func, text_element_func, null, null
        };

        private MarkupParseContext ctx;

        private string       text;
        private string       path;

        private string ta_ca_cert;
        private string ta_server_cert;
        private string ta_subject;
        private string ta_subject_alt;

        private IdCard card;
        private IdCard[] _cards = {};

        public IdCard[] cards {
            get {return _cards;}
            private set {_cards = value ?? new IdCard[0] ;}
        }

        public Parser(string path) {

            ctx = new MarkupParseContext(parser, 0, this, null);

            text = "";
            this.path = path;

            var file = File.new_for_path(path);

            try
            {
                var dis = new DataInputStream(file.read());
                string line;
                while ((line = dis.read_line(null)) != null) {
                    text += line;

                    // Preserve newlines.
                    //
                    // This may add an extra newline at EOF. Maybe use
                    // dis.read_upto("\n", ...) followed by dis.read_byte() instead?
                    text += "\n";
                }
            }
            catch(GLib.Error e)
            {
                logger.error("Could not retreive file size");
            }
        }

        public bool parse() {
            try
            {
                ctx.parse(text, text.length);
                return true;
            }
            catch(GLib.Error e)
            {
                logger.error("Could not parse %s, invalid content".printf(path));
                return false;
            }
        }
    }

    public class Writer : Object
    {
        protected static string write_identity(IdCard card) {
            string result = "  <identity>\n";
            result += "    <display-name>%s</display-name>\n".printf(escape_text(card.display_name));
            result += "    <user>%s</user>\n".printf(escape_text(card.username));
            result += "    <password>%s</password>\n".printf(escape_text(card.password));
            result += "    <realm>%s</realm>\n".printf(escape_text(card.issuer));
            result += "    <has2fa>%s</has2fa>\n".printf(card.has_2fa ? "true" : "false");
            if (card.services.size > 0) {
                result += "    <services>\n";
                foreach (string service in card.services)
                    result += "      <service>%s</service>\n".printf(escape_text(service));
                result += "    </services>\n";
            }
            if (card.rules.length > 0) {
                result += "    <selection-rules>\n";
                for(int i = 0; i < card.rules.length; i++) {
                    Rule rule = card.rules[i];
                    result += "      <rule>\n";
                    result += "        <pattern>%s</pattern>\n".printf(escape_text(rule.pattern));
                    result += "        <always-confirm>%s</always-confirm>\n".printf(rule.always_confirm);
                    result += "      </rule>\n";
                }
                result += "    </selection-rules>\n";
            }
            result += "    <trust-anchor>\n";
            if (card.trust_anchor.ca_cert != "") {
                result += "      <ca-cert>\n";
                result += card.trust_anchor.ca_cert + "\n";
                result += "      </ca-cert>\n";
            }
            if (card.trust_anchor.subject != "")
                result += "      <subject>%s</subject>\n".printf(escape_text(card.trust_anchor.subject));
            if (card.trust_anchor.subject_alt != "")
                result += "      <subject-alt>%s</subject-alt>\n".printf(escape_text(card.trust_anchor.subject_alt));
            if (card.trust_anchor.server_cert != "")
                result += "      <server-cert>%s</server-cert>\n".printf(card.trust_anchor.server_cert);
            result += "    </trust-anchor>\n";
            result += "  </identity>\n";
            return result;
        }

        public static string write(Gee.List<IdCard> cards) {
            string result = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
            result += "<identities>\n";
            foreach (IdCard card in cards) {
                if (!card.is_no_identity())
                    result += write_identity(card);
            }
            result += "</identities>\n";
            return result;
        }

        public static bool store(string filename, Gee.List<IdCard> cards) {
            string result = write(cards);
            try {
                FileStream stream = FileStream.open(filename, "wt");
                if (stream == null)
                    return false;
                // workaround old VALA error
                var towrite = result.data;
                stream.write(towrite, 1);
            }
            catch (GLib.Error e)  {
                stdout.printf("Error:  %s\n", e.message);
                return false;
            }
            return true;
        }
    }
}
