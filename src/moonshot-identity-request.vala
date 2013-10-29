public delegate void ReturnIdentityCallback (IdentityRequest request);

public class IdentityRequest : Object {
    public IdCard? id_card = null;
    public bool complete = false;
    public bool select_default = false;

    private IdentityManagerApp parent_app;
    public string nai;
    public string password;
    public string service;
    public SList<IdCard> candidates;

    ReturnIdentityCallback callback = null;

    public IdentityRequest (IdentityManagerApp           app,
                            string                       nai,
                            string                       password,
                            string                       service)
    {
        this.parent_app = app;
        this.nai = nai;
        this.password = password;
        this.service = service;
    }

    public IdentityRequest.default (IdentityManagerApp app)
    {
        this.parent_app = app;
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
        parent_app.select_identity (this);

        /* This function works as a GSourceFunc, so it can be passed to
         * the main loop from other threads
         */
        return false;
    }

    public void return_identity (IdCard? id_card) {
        this.id_card = id_card;
        this.complete = true;

        /* update id_card service list */
        if (id_card != null && this.service != null && this.service != "")
        {
            bool duplicate_service = false;

            foreach (string service in id_card.services)
            {
                if (service == this.service)
                    duplicate_service = true;
            }
            if (duplicate_service == false)
            {
                string[] services = new string[id_card.services.length + 1];

                for (int i = 0; i < id_card.services.length; i++)
                    services[i] = id_card.services[i];

                services[id_card.services.length] = this.service;
                id_card.services = services;

                this.id_card = this.parent_app.model.update_card (id_card);
            }
        }

        return_if_fail (callback != null);
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
