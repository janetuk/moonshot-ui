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
  public string display_name { get; set; default = null; }
  
  public string username { get; set; default = null; }
  public string password { get; set; default = null; }

  public string issuer { get; set; default = null; }
  
  public Rule[] rules {get; set; default = {};}
  public string[] services { get; set; default = {}; }


  public TrustAnchor trust_anchor  { get; set; default = new TrustAnchor (); }
  
  public Gdk.Pixbuf pixbuf { get; set; default = null; }    

  //TODO: Set the getter and remove the setter/default
  public string nai { get; set; default = null; }
}
