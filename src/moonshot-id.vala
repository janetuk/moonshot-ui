public class TrustAnchor : Object
{
  public string ca_cert {get; set; default = "";}
  public string subject {get; set; default = "";}
  public string subject_alt  {get; set; default = "";}
  public string server_cert  {get; set; default = "";}
}

public struct Rule
{
  public string pattern;
  public string always_confirm;
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

  public TrustAnchor trust_anchor  { get; set; default = new TrustAnchor (); }
  
  public unowned string nai { get {  _nai = username + "@" + issuer; return _nai;}}

  public bool store_password { get; set; default = false; }

  public bool IsNoIdentity() 
  {
    return (display_name == NO_IDENTITY);
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
