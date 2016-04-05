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

namespace WebProvisioning
{ 
    IdCard card;
    IdCard[] cards;

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
  
    public void start_element_func(MarkupParseContext context,
                                   string element_name,
                                   string[] attribute_names,
                                   string[] attribute_values) throws MarkupError
    {
        if (element_name == "identity")
        {
            IdCard[] tmp_cards = cards;

            cards = new IdCard[tmp_cards.length + 1];
            for (int i = 0; i < tmp_cards.length; i++)
            {
                cards[i] = tmp_cards[i];
            }
            card = new IdCard();
            cards[tmp_cards.length] = card;
        }
        else if (element_name == "rule")
        {
            Rule[] tmp_rules = card.rules;
            card.rules = new Rule[tmp_rules.length + 1];
            for (int i = 0; i < tmp_rules.length; i++)
            {
                card.rules[i] = tmp_rules[i];
            }
      
            card.rules[tmp_rules.length] = Rule();
        }
    }

    public void
    text_element_func(MarkupParseContext context,
                      string             text,
                      size_t             text_len) throws MarkupError
    {
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
        }
        else if (stack.nth_data(0) == "realm" && realm_handler(stack))
        {
            card.issuer = text;
        }
        else if (stack.nth_data(0) == "service")
        {
            string[] services = card.services;
            card.services = new string[services.length + 1];
            for (int i = 0; i < services.length; i++)
            {
                card.services[i] = services[i];
            }
            card.services[services.length] = text;
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
        /*Trust anchor*/
        else if (stack.nth_data(0) == "ca-cert" && ca_cert_handler(stack))
        {
            card.trust_anchor.ca_cert = text;
        }
        else if (stack.nth_data(0) == "subject" && subject_handler(stack))
        {
            card.trust_anchor.subject = text;
        }
        else if (stack.nth_data(0) == "subject-alt" && subject_alt_handler(stack))
        {
            card.trust_anchor.subject_alt = text;
        }
        else if (stack.nth_data(0) == "server-cert" && server_cert_handler(stack))
        {
            card.trust_anchor.server_cert = text;
        }
    }

    class Parser
    {
        private MarkupParser parser;
        private string       text;
        private string       path;
        public Parser(string path) {
            text = "";
            this.path = path;

            var file = File.new_for_path(path);
    
            try
            {
                var dis = new DataInputStream(file.read());
                string line;
                while ((line = dis.read_line(null)) != null)
                    text += line;
            }
            catch(GLib.Error e)
            {
                error("Could not retreive file size");
            }
      
            parser = {start_element_func, null, text_element_func, null, null};
        }
    
        public void parse() {
            var ctx = new MarkupParseContext(parser, 0, null, null);
      
            try
            {
                ctx.parse(text, text.length);
            }
            catch(GLib.Error e)
            {
                error("Could not parse %s, invalid content", path);
            } 
        }
    }
}
