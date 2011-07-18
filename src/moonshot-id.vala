public class TrustAnchor : Object
{
  public string ca_cert {get; set; default = null;}
  public string subject {get; set; default = null;}
  public string subject_alt  {get; set; default = null;}
  public string server_cert  {get; set; default = null;}
}

public struct Rule
{
  public string pattern;
  public string always_confirm;
}

public class IdCard : Object
{
  private string _nai;
  
  public string display_name { get; set; default = null; }
  
  public string username { get; set; default = null; }
  public string password { get; set; default = null; }

  public string issuer { get; set; default = null; }
  
  public Rule[] rules {get; set; default = {};}
  public string[] services { get; set; default = {}; }


  public TrustAnchor trust_anchor  { get; set; default = new TrustAnchor (); }
  
  //TODO: Set the getter and remove the setter/default
  public unowned string nai { get {  _nai = username + "@" + password; return _nai;}}
}
