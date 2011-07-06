namespace WebProvisioning
{ 
  public IdCard card;

  

  bool
  display_name_handler (SList<string> stack)
  {
    string[] display_name_path = {"display-name", "identity", "identities"};
    
    if (stack.length () != display_name_path.length)
      return false;
    
    for (int i = 0; i<display_name_path.length; i++)
    {
      if (stack.nth_data(i) != display_name_path[i])
        return false;
    }
    
    return true;
  }

  public void text_element_func (MarkupParseContext context,
                                 string text,
                                 size_t text_len) throws MarkupError
  {
    unowned SList<string> stack = context.get_element_stack ();
    
    if (text_len < 1)
      return;
    
    if (stack.nth_data(0) == "display-name" && display_name_handler (stack))
    {
      card.display_name = text;
    }
    else if (stack.nth_data(0) == "user")
    {
    }
    else if (stack.nth_data(0) == "password")
    {
    }
    else if (stack.nth_data(0) == "realm")
    {
    }
    else if (stack.nth_data(0) == "service")
    {
    }
    else if (stack.nth_data(0) == "pattern")
    {
    }
    else if (stack.nth_data(0) == "always_confirm")
    {
    }
    
    /*Trust anchor*/
    else if (stack.nth_data(0) == "ca-cert")
    {
    }
    else if (stack.nth_data(0) == "subject")
    {
    }
    else if (stack.nth_data(0) == "ca-cert")
    {
    }
  }

  class WebProvisionParser
  {
    public WebProvisionParser (string path)
    {
      string text = "";
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
      
      MarkupParser parser = {null, null, text_element_func, null, null};
      
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
    
    card = new IdCard();
    
    var webp = new WebProvisionParser (args[1]);
    
    debug ("%s", card.display_name);

    return 0;
  }
}
