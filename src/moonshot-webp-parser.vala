namespace WebProvisioning
{
  class WebProvisionParser
  {
    public WebProvisionParser (string path)
    {
      
    }
  }
  
  public void start_element_func (MarkupParseContext context,
                             string             element_name,
                             string[]           attribute_names,
                             string[]           attribute_values) throws MarkupError
  {
    debug ("Start: %s", element_name);
  }

  public void end_element_func (MarkupParseContext context,
                           string             element_name) throws MarkupError
  {
    debug ("End: %s", element_name);
  }
  
  public void text_element_func (MarkupParseContext context,
                            string text,
                            size_t text_len) throws MarkupError
  {
    debug ("Text element: %s", text); 
/*    for (string i in context.get_element_stack ())
    {
      stdout.printf("%s\n", i);
    }*/
  }
  
  public void parser_error (MarkupParseContext context,
                            Error              error)
  {
    debug ("error");
  }

  public static int main (string[] args)
  {
    string text = "";
    if (args.length < 2)
    {
      error ("Usage %s [-a] WEB_PROVISIONING_FILE", args[0]);
    }
    
    if (!FileUtils.test (args[1], FileTest.EXISTS | FileTest.IS_REGULAR))
    {
      error ("%s does not exist", args[1]);
    }
    
    var file = File.new_for_path (args[1]);
    
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
    
    MarkupParser parser = {start_element_func, end_element_func, text_element_func, null, parser_error};
    
    
    return 0;
  }
}
