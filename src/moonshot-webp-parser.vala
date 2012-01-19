using Moonshot;

namespace WebProvisioning
{ 


  public static int main (string[] args)
  {
    if (args.length < 2)
    {
      error ("Usage %s [-a] WEB_PROVISIONING_FILE", args[0]);
    }
    
    if (!FileUtils.test (args[1], FileTest.EXISTS | FileTest.IS_REGULAR))
    {
      error ("%s does not exist", args[1]);
    }
    
    var webp = new Parser (args[1]);
    webp.parse();
    
    foreach (IdCard card in cards)
    {
      Moonshot.Error error;
      string[] rules_patterns = {};
      string[] rules_always_confirm = {};
        
      if (card.rules.length > 0)
      {
        int i = 0;
        rules_patterns = new string[card.rules.length];
        rules_always_confirm = new string[card.rules.length];
        foreach (Rule r in card.rules)
        {
          rules_patterns[i] = r.pattern;
          rules_always_confirm[i] = r.always_confirm;
          i++;
        }
      }

      Moonshot.install_id_card (card.display_name,
                                card.username,
                                card.password,
                                card.issuer,
                                rules_patterns,
                                rules_always_confirm,
                                card.services,
                                card.trust_anchor.ca_cert,
                                card.trust_anchor.subject,
                                card.trust_anchor.subject_alt,
                                card.trust_anchor.server_cert,
                                out error);

      if (error != null)
      {
        stderr.printf ("Error: %s", error.message);
        continue;
      }
    }
    
    return 0;
  }
}
