delegate void ReturnIdentityCallback (IdentityRequest request);

class IdentityRequest : Object {
    public IdCard? id_card = null;
    public bool complete = false;

    private MainWindow main_window;
    private string nai;
    private string password;
    private string certificate;

    // Only one of these is used, we must support two types for
    // the DBus and MSRPC servers.
    ReturnIdentityCallback return_identity_cb = null;
    SourceFunc source_func_cb = null;

    public IdentityRequest (MainWindow                   main_window,
                            string                       nai,
                            string                       password,
                            string                       certificate)
    {
        this.main_window = main_window;
        this.nai = nai;
        this.password = password;
        this.certificate = certificate;
    }

    public void set_return_identity_callback (owned ReturnIdentityCallback cb)
    {
#if VALA_0_12
        this.return_identity_cb = ((owned) cb);
#else
        this.return_identity_cb = ((IdCard) => cb (IdCard));
#endif
    }

    public void set_source_func_callback (owned SourceFunc cb)
    {
#if VALA_0_12
        this.source_func_cb = ((owned) cb);
#else
        this.source_func_cb = (() => cb ());
#endif
    }

    public void execute () {
        main_window.select_identity (this);
    }

    public void return_identity (IdCard? id_card) {
        this.id_card = id_card;
        this.complete = true;

        if (return_identity_cb != null)
            return_identity_cb (this);
        else if (source_func_cb != null)
            source_func_cb ();
        else
            warn_if_reached ();
    }
}
