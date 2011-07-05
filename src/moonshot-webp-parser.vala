namespace WebProvisioning
{ 
  public IdCard card;

  public void text_element_func (MarkupParseContext context,
                                 string text,
                                 size_t text_len) throws MarkupError
  {
    unowned SList<string> stack = context.get_element_stack ();
    
    if (stack.nth_data(0) == "display-name")
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
    
    var webp = new WebProvisionParser (args[1]);

    return 0;
  }
}
