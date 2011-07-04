namespace WebProvisioning
{
  class WebProvisionParser
  {
    public WebProvisionParser (string path)
    {
      
    }
  }

  public static int main (string[] args)
  {
    int64 size;
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
      var info = file.query_info ("standard::size", FileQueryInfoFlags.NONE);
      size = info.get_size();
    }
    catch (Error e)
    {
      error ("Could not retreive file size");
    }
    
    return 0;
  }
}
