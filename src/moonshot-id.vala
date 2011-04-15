
class IdCard : Object {

    public string issuer { get; set; default = null; }
    public string username { get; set; default = null; }
    public string password { get; set; default = null; }
    public string[] services { get; set; default = null; }
    public int number { get; set; default = -1; }

}
