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
  public string password { get; set; default = null; }

  public string issuer { get; set; default = ""; }
  
  public Rule[] rules {get; set; default = {};}
  public string[] services { get; set; default = {}; }

  public TrustAnchor trust_anchor  { get; set; default = new TrustAnchor (); }
  
  public Gdk.Pixbuf pixbuf { get; set; default = null; }    

  public unowned string nai { get {  _nai = username + "@" + issuer; return _nai;}}

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
}
