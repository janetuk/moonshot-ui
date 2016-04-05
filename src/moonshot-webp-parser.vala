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
using Moonshot;

namespace WebProvisioning
{ 


    public static int main(string[] args)
    {
        int arg_index = -1;
        int force_flat_file_store = 0;
        bool bad_switch = false;
        for (arg_index = 1; arg_index < args.length; arg_index++) {
            string arg = args[arg_index];
            unichar c = arg.get_char();
            if (c == '-') {
                arg = arg.next_char();
                c = arg.get_char();
                switch (c) {
                case 'f':
                    force_flat_file_store = 1;
                    break;
                default:
                    bad_switch = true;
                    break;
                }
            } else {
                break; // arg is not a switch; presume it's the file
            }
        }
        if (bad_switch || (arg_index != args.length - 1))
        {
            stdout.printf(_("Usage %s [-f] WEB_PROVISIONING_FILE\n -f: add identities to flat file store.\n"), args[0]);
            return -1;
        }
        string webp_file = args[arg_index];
    
        if (!FileUtils.test(webp_file, FileTest.EXISTS | FileTest.IS_REGULAR))
        {
            stdout.printf(_("%s does not exist\n"), webp_file);
            return -1;
        }
    
        var webp = new Parser(webp_file);
        webp.parse();
    
        foreach (IdCard card in cards)
        {
            Moonshot.Error error;
            string[] rules_patterns = {};
            string[] rules_always_confirm = {};
        
            /* use temp arrays to workaround centos array property bug */
            var rules = card.rules;
            var services = card.services;
            if (rules.length > 0)
            {
                int i = 0;
                rules_patterns = new string[rules.length];
                rules_always_confirm = new string[rules.length];
                foreach (Rule r in rules)
                {
                    rules_patterns[i] = r.pattern;
                    rules_always_confirm[i] = r.always_confirm;
                    i++;
                }
            }

            Moonshot.install_id_card(card.display_name,
                                     card.username,
                                     card.password,
                                     card.issuer,
                                     rules_patterns,
                                     rules_always_confirm,
                                     services,
                                     card.trust_anchor.ca_cert,
                                     card.trust_anchor.subject,
                                     card.trust_anchor.subject_alt,
                                     card.trust_anchor.server_cert,
                                     force_flat_file_store,
                                     out error);

            if (error != null)
            {
                stderr.printf("Error: %s", error.message);
                continue;
            }
        }
    
        return 0;
    }
}
