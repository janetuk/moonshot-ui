namespace Moonshot
{
  [DBus (name = "org.janet.Moonshot")]
  public interface MoonshotServer : Object
  {
      public async abstract bool get_identity (string nai,
                                               string password,
                                               string service,
                                               out string nai_out,
                                               out string password_out,
                                               out string server_certificate_hash,
                                               out string ca_certificate,
                                               out string subject_name_constraint,
                                               out string subject_alt_name_constraint)
                                               throws DBus.Error;

      public async abstract bool get_default_identity (out string nai_out,
                                                       out string password_out,
                                                       out string server_certificate_hash,
                                                       out string ca_certificate,
                                                       out string subject_name_constraint,
                                                       out string subject_alt_name_constraint)
                                                       throws DBus.Error;
      
      public async abstract bool install_id_card (string   display_name,
                                                  string   user_name,
                                                  string   password,
                                                  string   realm,
                                                  string[] rules_patterns,
                                                  string[] rules_always_confirm,
                                                  string[] services,
                                                  string   ca_cert,
                                                  string   subject,
                                                  string   subject_alt,
                                                  string   server_cert)
                                                  throws DBus.Error;
  }
}


namespace WebProvisioning
{ 
  IdCard card;
  IdCard[] cards;

  bool
  check_stack (SList<string> stack, string[] reference)
  {
    if (stack.length () < reference.length)
      return false;
    
    for (int i = 0; i<reference.length; i++)
    {
      if (stack.nth_data(i) != reference[i])
        return false;
    }

    return true;
  }

  bool
  always_confirm_handler (SList<string> stack)
  {
    string[] always_confirm_path = {"always-confirm", "rule", "selection-rules", "identity", "identities"};
    
    return check_stack (stack, always_confirm_path);
  }
  
  bool
  pattern_handler (SList<string> stack)
  {
    string[] pattern_path = {"pattern", "rule", "selection-rules", "identity", "identities"};
    
    return check_stack (stack, pattern_path);
  }

  bool
  server_cert_handler (SList<string> stack)
  {
    string[] server_cert_path = {"server-cert", "trust-anchor", "identity", "identities"};
    
    return check_stack (stack, server_cert_path);
  }

  bool
  subject_alt_handler (SList<string> stack)
  {
    string[] subject_alt_path = {"subject-alt", "trust-anchor", "identity", "identities"};
    
    return check_stack (stack, subject_alt_path);
  }

  bool
  subject_handler (SList<string> stack)
  {
    string[] subject_path = {"subject", "trust-anchor", "identity", "identities"};
    
    return check_stack (stack, subject_path);
  }
  
  bool
  ca_cert_handler (SList<string> stack)
  {
    string[] ca_path = {"ca-cert", "trust-anchor", "identity", "identities"};
    
    return check_stack (stack, ca_path);
  }

  bool
  realm_handler (SList<string> stack)
  {
    string[] realm_path = {"realm", "identity", "identities"};
    
    return check_stack (stack, realm_path);
  }

  bool
  password_handler (SList<string> stack)
  {
    string[] password_path = {"password", "identity", "identities"};
    
    return check_stack (stack, password_path);
  }

  bool
  user_handler (SList<string> stack)
  {
    string[] user_path = {"user", "identity", "identities"};
    
    return check_stack (stack, user_path);
  }

  bool
  display_name_handler (SList<string> stack)
  {
    string[] display_name_path = {"display-name", "identity", "identities"};
    
    return check_stack (stack, display_name_path);
  }
  
  public void
  start_element_func (MarkupParseContext context,
                      string element_name,
                      string[] attribute_names,
                      string[] attribute_values) throws MarkupError
  {
    if (element_name == "identity")
    {
      IdCard[] tmp_cards = cards;

      cards = new IdCard[tmp_cards.length + 1];
      for (int i=0; i<tmp_cards.length; i++)
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
      for (int i=0; i<tmp_rules.length; i++)
      {
        card.rules[i] = tmp_rules[i];
      }
      
      card.rules[tmp_rules.length] = Rule();
    }
  }

  public void
  text_element_func (MarkupParseContext context,
                     string             text,
                     size_t             text_len) throws MarkupError
  {
    unowned SList<string> stack = context.get_element_stack ();
    
    if (text_len < 1)
      return;
    
    if (stack.nth_data(0) == "display-name" && display_name_handler (stack))
    {
      card.display_name = text;
    }
    else if (stack.nth_data(0) == "user" && user_handler (stack))
    {
      card.username = text;
    }
    else if (stack.nth_data(0) == "password" && password_handler (stack))
    {
      card.password = text;
    }
    else if (stack.nth_data(0) == "realm" && realm_handler (stack))
    {
      card.issuer = text;
    }
    else if (stack.nth_data(0) == "service")
    {
      string[] services = card.services;
      card.services = new string[services.length + 1];
      for (int i = 0; i<services.length; i++)
      {
        card.services[i] = services[i];
      }
      card.services[services.length] = text;
    }
    /* Rules */
    else if (stack.nth_data(0) == "pattern" && pattern_handler (stack))
    {
      card.rules[card.rules.length - 1].pattern = text;
    }
    else if (stack.nth_data(0) == "always-confirm" && always_confirm_handler (stack))
    {
      if (text == "true" || text == "false")
        card.rules[card.rules.length - 1].always_confirm = text;
    }
    /*Trust anchor*/
    else if (stack.nth_data(0) == "ca-cert" && ca_cert_handler (stack))
    {
      card.trust_anchor.ca_cert = text;
    }
    else if (stack.nth_data(0) == "subject" && subject_handler (stack))
    {
      card.trust_anchor.subject = text;
    }
    else if (stack.nth_data(0) == "subject-alt" && subject_alt_handler (stack))
    {
      card.trust_anchor.subject_alt = text;
    }
    else if (stack.nth_data(0) == "server-cert" && server_cert_handler (stack))
    {
      card.trust_anchor.server_cert = text;
    }
  }

  class Parser
  {
    private MarkupParser parser;
    private string       text;
    private string       path;
    public Parser (string path)
    {
      text = "";
      this.path = path;

      var file = File.new_for_path (path);
    
      try
      {
        var dis = new DataInputStream (file.read ());
        string line;
        while ((line = dis.read_line (null)) != null)
          text += line;
      }
      catch (Error e)
      {
        error ("Could not retreive file size");
      }
      
      parser = {start_element_func, null, text_element_func, null, null};
    }
    
    public void
    parse ()
    {
      var ctx = new MarkupParseContext(parser, 0, null, null);
      
      try
      {
        ctx.parse (text, text.length);
      }
      catch (Error e)
      {
        error ("Could not parse %s, invalid content", path);
      } 
    }
  }

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
      try
      {
        var conn = DBus.Bus.get (DBus.BusType.SESSION);
        dynamic DBus.Object bus = conn.get_object ("org.janet.Moonshot",
                                                   "/org/janet/moonshot",
                                                   "org.janet.Moonshot");

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

        bus.install_id_card (card.display_name,
                             card.username,
                             card.password,
                             card.issuer,
                             rules_patterns,
                             rules_always_confirm,
                             card.services,
                             card.trust_anchor.ca_cert,
                             card.trust_anchor.subject,
                             card.trust_anchor.subject_alt,
                             card.trust_anchor.server_cert);
        
      }
      catch (Error e)
      {
        stderr.printf ("Error: %s", e.message);
        continue;
      }
    }
    
    return 0;
  }
}
