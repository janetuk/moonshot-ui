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

using Gee;

extern char* get_cert_valid_before(uchar* inbuf, int inlen, char* outbuf, int outlen);


// A TrustAnchor object can be imported or installed via the API, but cannot
// be modified by the user, other than being cleared. Hence the fields are read-only.
public class TrustAnchor : Object
{
    private static const string CERT_HEADER = "-----BEGIN CERTIFICATE-----";
    private static const string CERT_FOOTER = "-----END CERTIFICATE-----";

    public enum TrustAnchorType {
        EMPTY,
        CA_CERT,
        SERVER_CERT
    }
 
    private string _ca_cert = "";
    private string _subject = "";
    private string _subject_alt = "";
    private string _server_cert = "";
    private string _datetime_added = "";

    private static string fixup (string s) {
        return (s == null ? "" : s.strip());
    }

    public TrustAnchor(string ca_cert, string server_cert, string subject, string subject_alt) {
        _ca_cert = fixup(ca_cert);
        _server_cert = fixup(server_cert);
        _subject = fixup(subject);
        _subject_alt = fixup(subject_alt);

        // If we're reading from store, this will be overridden (see set_datetime_added)
        _datetime_added = "";
    }

    public TrustAnchor.empty() {
    }


    public string ca_cert {
        get {
            return _ca_cert;
        }
    }

    public string subject {
        get {
            return _subject;
        }
    }

    public string subject_alt  {
        get {
            return _subject_alt;
        }
    }


    public string server_cert {
        get {
            return _server_cert;
        }
    }

    public string datetime_added {
        get {
            return _datetime_added;
        }
    }

    public bool is_empty() {
        return ca_cert == "" && server_cert == "";
    }

    public TrustAnchorType get_anchor_type() {
        return (server_cert != "" ? TrustAnchorType.SERVER_CERT 
                : (ca_cert != "" ? TrustAnchorType.CA_CERT : TrustAnchorType.EMPTY));
    }

    internal void set_datetime_added(string datetime) {
        _datetime_added = fixup(datetime);
    }

    internal static string format_datetime_now() {
        DateTime now = new DateTime.now_utc();
        string dt = now.format("%b %d %T %Y %Z");
        return dt;
    }

    internal void update_server_fingerprint(string fingerprint) {
        this._server_cert = fingerprint;
        string ta_datetime_added = TrustAnchor.format_datetime_now();
        this.set_datetime_added(ta_datetime_added);
    }

    public int Compare(TrustAnchor other)
    {
        if (this.ca_cert != other.ca_cert) {
            // IdCard.logger.trace("TrustAnchor.Compare: this.ca_cert='%s'; other.ca_cert='%s'".printf(this.ca_cert, other.ca_cert));
            return 1;
        }
        if (this.subject != other.subject) {
            // IdCard.logger.trace("TrustAnchor.Compare: this.subject='%s'; other.subject='%s'".printf(this.subject, other.subject));
            return 1;
        }
        if (this.subject_alt != other.subject_alt) {
            // IdCard.logger.trace("TrustAnchor.Compare: this.subject_alt='%s'; other.subject_alt='%s'".printf(this.subject_alt, other.subject_alt));
            return 1;
        }
        if (this.server_cert != other.server_cert) {
            // IdCard.logger.trace("TrustAnchor.Compare: this.server_cert=%s'; other.server_cert='%s'".printf(this.server_cert, other.server_cert));
            return 1;
        }

        // Do not compare the datetime_added fields; it's not essential.

        return 0;
    }

    public string? get_expiration_date(out string? err_out=null)
    {
        if (&err_out != null) {
            err_out = null;
        }

        if (this.ca_cert == "") {
            if (&err_out != null) {
                err_out = "Trust anchor does not have a ca_certificate";
                return null;
            }
        }

        string cert = this.ca_cert;
        cert.chomp();

        uchar[] binary = Base64.decode(cert);
        IdCard.logger.trace("get_expiration_date: encoded length=%d; decoded length=%d".printf(cert.length, binary.length));

        char buf[64];
        string err = (string) get_cert_valid_before(binary, binary.length, buf, 64);
        if (err != "") {
            IdCard.logger.error(@"get_expiration_date: get_cert_valid_before returned '$err'");
            if (&err_out != null) {
                err_out = err;
            }
            return null;
        }
            
        string date = (string) buf;
        IdCard.logger.trace(@"get_expiration_date: get_cert_valid_before returned '$date'");

        return date;
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
    internal static MoonshotLogger logger = get_logger("IdCard");

    public const string NO_IDENTITY = "No Identity";

    private string _username = "";
    private string _issuer = "";

    public string display_name { get; set; default = ""; }
  
    public string username { 
        public get {
            return _username;
        }
        public set {
            _username = value;
            update_nai();
        }
    }

    public string issuer { 
        public get {
            return _issuer;
        }
        public set {
            _issuer = value;
            update_nai();
        }
    }

    private void update_nai() {
        _nai = username + "@" + issuer;
    }

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

    private Rule[] _rules = new Rule[0];
    public Rule[] rules {
        get {return _rules;}
        internal set {_rules = value ?? new Rule[0] ;}
    }

    private ArrayList<string> _services = new ArrayList<string>();

    internal ArrayList<string> services {
         get {return  _services;}
    }

    // Returns the list of services as a string, using the given separator.
    internal string get_services_string(string sep) {
        if (_services.is_empty) {
            return "";
        }

        // ArrayList.to_array() seems to be unreliable -- it causes segfaults 
        // semi-randomly. (Possibly because it returns an unowned ref?)
        // return string.joinv(sep, _services.to_array());
        // 
        // This problem may be related to the one noted elsewhere as the
        // "Centos vala array property bug".

        string[] svcs = new string[_services.size];
        for (int i = 0; i < _services.size; i++) {
            svcs[i] = _services[i];
        }

        return string.joinv(sep, svcs);
    }

    internal void update_services(string[] services) {
        _services.clear();

        // Doesn't exist in older versions of libgee:
        // _services.add_all_array(services);

        if (services != null) {
            foreach (string s in services) {
                _services.add(s);
            }
        }
    } 

    internal void update_services_from_list(ArrayList<string> services) {
        if (services == this._services) {
            // Don't try to update from self.
            return;
        }

        _services.clear();

        if (services != null) {
            _services.add_all(services);
        }
    } 


    public bool temporary {get; set; default = false; }

    private TrustAnchor _trust_anchor = new TrustAnchor.empty();
    public TrustAnchor trust_anchor  { 
        get {
            return _trust_anchor;
        }
    }

    // For use by storage implementations.
    internal void set_trust_anchor_from_store(TrustAnchor ta) {
        _trust_anchor = ta;
    }

    internal void clear_trust_anchor() {
        _trust_anchor = new TrustAnchor.empty();
    }
  
    public string nai { public get; private set;}

    public bool store_password { get; set; default = false; }

    // uuid is currently used only for debugging. Must be unique, even between cards with same nai and display name.
    public string uuid {
        public get {return _uuid;}
    }
    private string _uuid = generate_uuid();

    internal static string generate_uuid() {
        uint32 rand1 = Random.next_int();
        uint32 rand2 = Random.next_int();
        return "%08X.%08X::%s".printf(rand1, rand2, TrustAnchor.format_datetime_now());
    }

    public bool is_no_identity() 
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

        if (CompareStringArrayList(this._services, other._services)!=0)
            diff |= 1 << DiffFlags.SERVICES;

        if (this.trust_anchor.Compare(other.trust_anchor)!=0)
            diff |= 1 << DiffFlags.TRUST_ANCHOR;

        // stdout.printf("Diff Flags: %x\n", diff);
        if (this.display_name == other.display_name && diff != 0) {
            logger.trace("Compare: Two IDs with display_name '%s', but diff_flags=%0x".printf(this.display_name, diff));
        }
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

    internal void add_rule(Rule rule) {
        _rules += rule;
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

public int CompareStringArrayList(ArrayList<string> a, ArrayList<string> b)
{
    if (a.size != b.size) {
        return 1;
    }

    for (int i = 0; i < a.size; i++) {
        if (a[i] != b[i]) {
            return 1;
        }
    }
    return 0;
}
