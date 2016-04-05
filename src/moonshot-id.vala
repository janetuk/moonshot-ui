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
public class TrustAnchor : Object
{
    public string ca_cert {get; set; default = "";}
    public string subject {get; set; default = "";}
    public string subject_alt  {get; set; default = "";}
    public string server_cert  {get; set; default = "";}
    public int Compare(TrustAnchor other)
    {
        if (this.ca_cert != other.ca_cert)
            return 1;
        if (this.subject != other.subject)
            return 1;
        if (this.subject_alt != other.subject_alt)
            return 1;
        if (this.server_cert != other.server_cert)
            return 1;
        return 0;
    }
}

public struct Rule
{
    public string pattern;
    public string always_confirm;
    public int Compare(Rule other) {
        if (this.pattern != other.pattern)
            return 1;
        if (this.always_confirm != other.always_confirm)
            return 1;
        return 0;
    }
}

public class IdCard : Object
{
    public const string NO_IDENTITY = "No Identity";

    private string _nai;
  
    public string display_name { get; set; default = ""; }
  
    public string username { get; set; default = ""; }
    #if GNOME_KEYRING
        private unowned string _password;
    public string password {
        get {
            return (_password!=null) ? _password : "";
        }
        set {
            if (_password != null) {
                GnomeKeyring.memory_free((void *)_password);
                _password = null;
            }
            if (value != null)
                _password = GnomeKeyring.memory_strdup(value); 
        }
    }
    #else
        public string password { get; set; default = null; }
    #endif

        public string issuer { get; set; default = ""; }
  
    public Rule[] rules {get; set; default = {};}
    public string[] services { get; set; default = {}; }
    public bool temporary {get; set; default = false; }

    public TrustAnchor trust_anchor  { get; set; default = new TrustAnchor (); }
  
    public unowned string nai { get {  _nai = username + "@" + issuer; return _nai;}}

    public bool store_password { get; set; default = false; }

    public bool IsNoIdentity() 
    {
        return (display_name == NO_IDENTITY);
    }

    public enum DiffFlags {
        DISPLAY_NAME,
        USERNAME,
        PASSWORD,
        ISSUER,
        RULES,
        SERVICES,
        TRUST_ANCHOR;
    }

    public int Compare(IdCard other)
    {
        int diff = 0;
        if (this.display_name != other.display_name)
            diff |= 1 << DiffFlags.DISPLAY_NAME;

        if (this.username != other.username)
            diff |= 1 << DiffFlags.USERNAME;

        if (this.password != other.password)
            diff |= 1 << DiffFlags.PASSWORD;

        if (this.issuer != other.issuer)
            diff |= 1 << DiffFlags.ISSUER;

        if (CompareRules(this.rules, other.rules)!=0)
            diff |= 1 << DiffFlags.RULES;

        if (CompareStringArray(this.services, other.services)!=0)
            diff |= 1 << DiffFlags.SERVICES;

        if (this.trust_anchor.Compare(other.trust_anchor)!=0)
            diff |= 1 << DiffFlags.TRUST_ANCHOR;

        stdout.printf("Diff Flags: %x\n", diff);
        return diff;
    }

    public static IdCard NewNoIdentity() 
    { 
        IdCard card = new IdCard();
        card.display_name = NO_IDENTITY;
        return card;
    }

    ~IdCard() {
        password = null;
    }
}

public int CompareRules(Rule[] a, Rule[] b)
{
    if (a.length != b.length) {
        return 1;
    }

    for (int i = 0; i < a.length; i++) {
        if (a[i].Compare(b[i]) != 0) {
            return 1;
        }
    }
    return 0;
}

public int CompareStringArray(string[] a, string [] b)
{
    if (a.length != b.length) {
        return 1;
    }

    for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) {
            return 1;
        }
    }
    return 0;
}
