/*
 * Copyright (c) 2011-2014, JANET(UK)
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

public class Password {
#if GNOME_KEYRING
    private unowned string _password;
    public string password {
        get {
            return _password;
        }
        set {
            if (_password != null) {
                GnomeKeyring.memory_free((void *)_password);
                _password = null;
            }
            if (value != null)
                _password = GnomeKeyring.memory_strdup(value); 
        }
    }
#else
    public string password { get; set; default = null; }
#endif

    public Password(string in_password) {
        password = in_password;
    }

    ~Password() {
        password = null;
    }
}

public class PasswordHashTable : Object {
    private HashTable<string, Password> password_table;

    private static string ComputeHashKey(IdCard card, IIdentityCardStore store) {
        return "%s_store_%d".printf( card.display_name, store.get_store_type() );
    }

    public void CachePassword(IdCard card, IIdentityCardStore store) {
        password_table.replace(ComputeHashKey(card, store), new Password(card.password));
    }

    public void RemovePassword(IdCard card, IIdentityCardStore store) {
        password_table.remove(ComputeHashKey(card, store));
    }
    public void RetrievePassword(IdCard card, IIdentityCardStore store) {
        weak Password password = password_table.lookup(ComputeHashKey(card, store));
        if (password != null) {
            card.password = password.password;
        }
    }
    public PasswordHashTable() {
        password_table = new HashTable<string, Password>(GLib.str_hash, GLib.str_equal);
    }
}

public class IdentityManagerModel : Object {
    private const string FILE_NAME = "identities.txt";
    private PasswordHashTable password_table;
    private IIdentityCardStore store;
    public LinkedList<IdCard>  get_card_list() {
        var identities = store.get_card_list();
        identities.sort((a, b) => {
                IdCard id_a = (IdCard )a;
                IdCard id_b = (IdCard )b;
                if (id_a.IsNoIdentity() && !id_b.IsNoIdentity()) {
                    return -1;
                } else if (id_b.IsNoIdentity() && !id_a.IsNoIdentity()) {
                    return 1;
                }
                return strcmp(id_a.display_name, id_b.display_name);
            });
        if (identities.is_empty || !identities[0].IsNoIdentity())
            identities.insert(0, IdCard.NewNoIdentity());
        foreach (IdCard id_card in identities) {
            if (!id_card.store_password) {
                password_table.RetrievePassword(id_card, store);
            }
        }
        return identities;
    }
    public signal void card_list_changed();

    /* This method finds a valid display name */
    public bool display_name_is_valid(string name,
                                      out string? candidate)
    {
        if (&candidate != null)
            candidate = null;
        foreach (IdCard id_card in this.store.get_card_list())
        {
            if (id_card.display_name == name)
            {
                if (&candidate != null)
                {
                    for (int i = 0; i < 1000; i++)
                    {
                        string tmp = "%s %d".printf(name, i);
                        if (display_name_is_valid(tmp, null))
                        {
                            candidate = tmp;
                            break;
                        }
                    }
                }
                return false;
            }
        }
        return true;
    }

    private bool remove_duplicates(IdCard card)
    {
        bool duplicate_found = false;
        bool found = false;
        do {
            var cards = this.store.get_card_list();
            found = false;
            foreach (IdCard id_card in cards) {
                if ((card != id_card) && (id_card.nai == card.nai)) {
                    stdout.printf("removing duplicate id for '%s'\n", card.nai);
                    remove_card_internal(id_card);
                    found = duplicate_found = true;
                    break;
                }
            }
        } while (found);
        return duplicate_found;
    }

    public IdCard? find_id_card(string nai, bool force_flat_file_store) {
        IdCard? retval = null;
        IIdentityCardStore.StoreType saved_store_type = get_store_type();
        if (force_flat_file_store)
            set_store_type(IIdentityCardStore.StoreType.FLAT_FILE);

        foreach (IdCard id in get_card_list()) {
            if (id.nai == nai) {
                retval = id;
                break;
            }
        }
        set_store_type(saved_store_type);
        if (force_flat_file_store && 
            (saved_store_type != IIdentityCardStore.StoreType.FLAT_FILE))
            card_list_changed();
        return retval;
    }

    public void add_card(IdCard card, bool force_flat_file_store) {
        if (card.temporary)
            return;

        string candidate;
        IIdentityCardStore.StoreType saved_store_type = get_store_type();

        if (force_flat_file_store)
            set_store_type(IIdentityCardStore.StoreType.FLAT_FILE);

        remove_duplicates(card);

        if (!display_name_is_valid(card.display_name, out candidate))
        {
            card.display_name = candidate;
        }

        if (!card.store_password)
            password_table.CachePassword(card, store);
        store.add_card(card);
        set_store_type(saved_store_type);
        card_list_changed();
    }

    public IdCard update_card(IdCard card) {
        IdCard retval;
        if (card.temporary) {
            retval = card;
            return retval;
        }
            
        if (!card.store_password)
            password_table.CachePassword(card, store);
        else
            password_table.RemovePassword(card, store);
        retval = store.update_card(card);
        card_list_changed();
        return retval;
    }

    private bool remove_card_internal(IdCard card) {
        if (card.temporary)
            return false;
        password_table.RemovePassword(card, store);
        return store.remove_card(card);
    }

    public bool remove_card(IdCard card) {
        if (remove_card_internal(card)) {
            card_list_changed();
            return true;
        }
        return false;
    }

    public void set_store_type(IIdentityCardStore.StoreType type) {
        if ((store != null) && (store.get_store_type() == type))
            return;
        switch (type) {
            #if GNOME_KEYRING
        case IIdentityCardStore.StoreType.KEYRING:
            store = new KeyringStore();
            break;
            #endif
        case IIdentityCardStore.StoreType.FLAT_FILE:
        default:
            store = new LocalFlatFileStore();
            break;
        }
    }

    public IIdentityCardStore.StoreType get_store_type() {
        return store.get_store_type();
    }

    public bool HasNonTrivialIdentities() {
        foreach (IdCard card in this.store.get_card_list()) {
            // The 'NoIdentity' card is non-trivial if it has services or rules.
            // All other cards are automatically non-trivial.
            if ((!card.IsNoIdentity()) || 
                (card.services.length > 0) ||
                (card.rules.length > 0)) {
                return true;
            }
        }
        return false;
    }


    private IdentityManagerApp parent;

    public IdentityManagerModel(IdentityManagerApp parent_app, IIdentityCardStore.StoreType store_type) {
        parent = parent_app;
        password_table = new PasswordHashTable();
        set_store_type(store_type);
    }
}
