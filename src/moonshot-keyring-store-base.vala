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
using Gee;

#if GNOME_KEYRING || LIBSECRET_KEYRING
public abstract class KeyringStoreBase : Object, IIdentityCardStore {
    protected static MoonshotLogger logger = get_logger("KeyringStore");

    protected LinkedList<IdCard> id_card_list;
    protected const string keyring_store_attribute = "Moonshot";
    protected const string keyring_store_version = "1.0";

    public void add_card(IdCard card) {
        logger.trace("add_card: Adding card '%s' with services: '%s'"
                     .printf(card.display_name, card.get_services_string("; ")));

        id_card_list.add(card);
        store_id_cards();
    }

    public IdCard? update_card(IdCard card) {
        logger.trace("update_card");

        id_card_list.remove(card);
        id_card_list.add(card);

        store_id_cards();
        foreach (IdCard idcard in id_card_list) {
            if (idcard.display_name == card.display_name) {
                return idcard;
            }
        }

        logger.error(@"update_card: card '$(card.display_name)' was not found after re-loading!");
        return null;
    }

    public bool remove_card(IdCard card) {
        bool retval = id_card_list.remove(card);
        if (retval)
            store_id_cards();
        return retval;
    }

    public IIdentityCardStore.StoreType get_store_type() {
        return IIdentityCardStore.StoreType.KEYRING;
    }

    public LinkedList<IdCard> get_card_list() {
        return id_card_list;
    }

    protected abstract void clear_keyring();     
    protected abstract void load_id_cards();
    internal abstract void store_id_cards();
    


    public KeyringStoreBase() {
        id_card_list = new LinkedList<IdCard>();
        load_id_cards();
    }
}

#endif
