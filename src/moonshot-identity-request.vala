delegate void ReturnIdentityCallback (IdentityRequest request);

class IdentityRequest : Object {
    public IdCard? id_card = null;
    public bool complete = false;
    public bool select_default = false;

    private MainWindow main_window;
    private string nai;
    private string password;
    private string certificate;

    ReturnIdentityCallback callback = null;

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

    public IdentityRequest.default (MainWindow main_window)
    {
        this.main_window = main_window;
        this.select_default = true;
    }

    public void set_callback (owned ReturnIdentityCallback cb)
    {
#if VALA_0_12
        this.callback = ((owned) cb);
#else
        this.callback = ((IdCard) => cb (IdCard));
#endif
    }

    public bool execute () {
        main_window.select_identity (this);

        /* This function works as a GSourceFunc, so it can be passed to
         * the main loop from other threads
         */
        return false;
    }

    public void return_identity (IdCard? id_card) {
        return_if_fail (callback != null);

        this.id_card = id_card;
        this.complete = true;

        callback (this);
    }

#if OS_WIN32
    /* For synchronisation between RPC thread and main loop. Because
     * these objects are not refcounted, it's best to tie them to the
     * lifecycle of the IdentityRequest object.
     */
    public Mutex mutex;
    public Cond cond;
#endif
}
