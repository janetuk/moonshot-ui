using Moonshot;

namespace WebProvisioning
{ 


  public static int main (string[] args)
  {
    int arg_index = -1;
    int force_flat_file_store = 0;
    bool bad_switch = false;
    for (arg_index = 1; arg_index < args.length; arg_index++) {
      string arg = args[arg_index];
      unichar c = arg.get_char();
      if (c=='-') {
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
      stdout.printf (_("Usage %s [-f] WEB_PROVISIONING_FILE\n -f: add identities to flat file store.\n"), args[0]);
      return -1;
    }
    string webp_file = args[arg_index];
    
    if (!FileUtils.test (webp_file, FileTest.EXISTS | FileTest.IS_REGULAR))
    {
      stdout.printf (_("%s does not exist\n"), webp_file);
      return -1;
    }
    
    var webp = new Parser (webp_file);
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
                                force_flat_file_store,
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
