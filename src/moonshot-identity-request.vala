/*
 * Copyright (c) 2011-2016, JANET(UK)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of JANET(UK) nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
*/
public delegate void ReturnIdentityCallback(IdentityRequest request);

public class IdentityRequest : Object {
    static MoonshotLogger logger = get_logger("IdentityRequest");

    public IdCard? id_card = null;
    public bool complete = false;
    public bool select_default = false;

    private IdentityManagerApp parent_app;
    public string nai;
    public string password;
    public string service;
    public SList<IdCard> candidates;

    ReturnIdentityCallback callback = null;

    public IdentityRequest(IdentityManagerApp           app,
                           string                       nai,
                           string                       password,
                           string                       service)
    {
        this.parent_app = app;
        this.nai = nai;
        this.password = password;
        this.service = service;
    }

    public IdentityRequest.default(IdentityManagerApp app)
    {
        this.parent_app = app;
        this.select_default = true;
    }

    public void set_callback(owned ReturnIdentityCallback cb)
    {
        #if VALA_0_12
            this.callback = ((owned) cb);
        #else
            this.callback = ((IdCard) => cb(IdCard));
        #endif
    }

    public bool execute() {
        parent_app.select_identity(this);

        /* This function works as a GSourceFunc, so it can be passed to
         * the main loop from other threads
         */
        return false;
    }

    public void return_identity(IdCard? id_card, bool update_card = true) {
        this.id_card = id_card;
        this.complete = true;

        /* update id_card service list */
        if (update_card && id_card != null && this.service != null && this.service != "")
        {
            bool duplicate_service = id_card.services.contains(this.service);
            logger.trace("return_identity: duplicate_service=" + duplicate_service.to_string());
            if (duplicate_service == false)
            {
                logger.trace("return_identity: calling add_service");
                id_card.services.add(this.service);
                logger.trace("return_identity: back from add_service");

                this.id_card = this.parent_app.model.update_card(id_card);
            }
        }

        return_if_fail(callback != null);
        logger.trace("return_identity: invoking callback");
        callback(this);
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
