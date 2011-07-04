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
    if (args.length < 2)
    {
      error ("Usage %s [-a] WEB_PROVISIONING_FILE", args[0]);
    }
    
    if (!FileUtils.test (args[1], FileTest.EXISTS | FileTest.IS_REGULAR))
    {
      error ("Error: %s does not exist", args[1]);
    }
    
    return 0;
  }
}
