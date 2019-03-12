
using Gee;
using WebProvisioning;

public errordomain IdentityManagerError {
    KEYRING_LOCKED
}

public interface IdentityManagerInterface : Object {
    public abstract void queue_identity_request(IdentityRequest request);
    public abstract void make_visible();
    public abstract bool confirm_trust_anchor(IdCard card, TrustAnchorConfirmationRequest request);
    internal abstract void info_dialog(string title, string msg);
    internal abstract bool yesno_dialog(string title, string msg, bool default_true);
    internal abstract string? password_dialog(string title, string text, bool show_remember, out bool remember);

    /* Reports whether there are identities with ideantical NAI */
    internal void report_expired_trust_anchors(IdentityManagerModel model) {
        Gee.List<IdCard> card_list = model.get_card_list();
        foreach (IdCard id_card in card_list) {
            if (id_card.trust_anchor.is_expired()) {
                string message = _("Trust anchor for identity '%s' expired the %s.\n\n").printf(id_card.nai, id_card.trust_anchor.get_expiration_date())
                    + _("That means that any attempt to authenticate with that identity will fail. ")
                    + _("Please, ask your organisation to provide you with an updated credential.");
                info_dialog("Expired Trust Anchor", message);
            }
        }
    }

    /* Reports whether there are identities with ideantical NAI */
    internal void report_duplicate_nais(IdentityManagerModel model) {
        Gee.List<Gee.List<IdCard>> duplicates;
        model.find_duplicate_nai_sets(out duplicates);
        foreach (Gee.List<IdCard> list in duplicates) {
            string message = _("The following identities use the same Network Access Identifier (NAI),\n'%s'.").printf(list.get(0).nai)
                + _("\n\nDuplicate NAIs are not allowed. Please remove identities you don't need, or modify")
                + _(" user ID or issuer fields so that they are no longer the same NAI.");

            foreach (var card in list) {
                message += _("\n\nDisplay Name: '%s'\nServices:\n     %s").printf(card.display_name, card.get_services_string(",\n     "));
            }
            info_dialog("Duplicate NAIs", message);
        }
    }

    public bool add_identity(IdCard id_card, IdentityManagerModel identities_manager, bool force_flat_file_store)
    {
        bool dialog = false;
        IdCard? prev_id = identities_manager.find_id_card(id_card.nai, force_flat_file_store);
        if (prev_id != null) {
            int flags = prev_id.Compare(id_card);
            if (flags == 0) {
                return false;
            } else if ((flags & (1 << IdCard.DiffFlags.DISPLAY_NAME)) != 0) {
                dialog = yesno_dialog(
                    "Install ID Card",
                    "Would you like to update ID Card '%s' using nai '%s'?".printf(prev_id.display_name, prev_id.nai),
                    true);
            } else {
                dialog = yesno_dialog(
                    "Install ID Card",
                    "Would you like to replace ID Card '%s' using nai '%s' with the new ID Card '%s'?".printf(
                        prev_id.display_name, prev_id.nai, id_card.display_name),
                    true);
            }
        } else {
            dialog = yesno_dialog(
                "Install ID Card",
                "Would you like to add '%s' ID Card to the ID Card Organizer?".printf(id_card.display_name),
                true);
        }

        if (dialog) {
            identities_manager.add_card(id_card, force_flat_file_store);
            return true;
        }
        else {
            return false;
        }
    }

    internal bool id_matches_search(IdCard id_card, string entry_text, SList<IdCard>? candidates)
    {
        if (id_card == null)
            return false;

        if (candidates != null) {
            bool is_candidate = false;
            foreach (IdCard candidate in candidates) {
                if (candidate == id_card)
                    is_candidate = true;
            }
            if (!is_candidate)
                return false;
        }

        if (entry_text == "")
            return true;

        foreach (string search_text in entry_text.split(" ")) {
            if (search_text == "")
                continue;

            string search_text_casefold = search_text.casefold();

            if (id_card.issuer != null) {
                string issuer_casefold = id_card.issuer;
                if (issuer_casefold.contains(search_text_casefold))
                    return true;
            }

            if (id_card.display_name != null) {
                string display_name_casefold = id_card.display_name.casefold();
                if (display_name_casefold.contains(search_text_casefold))
                    return true;
            }

            if (id_card.services.size > 0) {
                foreach (string service in id_card.services) {
                    string service_casefold = service.casefold();
                    if (service_casefold.contains(search_text_casefold))
                        return true;
                }
            }
        }
        return false;
    }

    internal void import_identities(string filename, IdentityManagerModel identities_manager, MoonshotLogger logger)
    {
        int import_count = 0;
        var webp = new Parser(filename);
        if (!webp.parse()) {
            info_dialog("Import error", _("Could not parse identities file."));
        }
        else {
            logger.trace(@"import_identities_cb: Have $(webp.cards.length) IdCards");
            foreach (IdCard card in webp.cards) {
                if (card == null) {
                    logger.trace(@"import_identities_cb: Skipping null IdCard");
                    continue;
                }

                if (!card.trust_anchor.is_empty()) {
                    string ta_datetime_added = TrustAnchor.format_datetime_now();
                    card.trust_anchor.set_datetime_added(ta_datetime_added);
                    logger.trace("import_identities_cb : Set ta_datetime_added for '%s' to '%s'; ca_cert='%s'; server_cert='%s'"
                                 .printf(card.display_name, ta_datetime_added, card.trust_anchor.ca_cert, card.trust_anchor.server_cert));
                }

                bool result = add_identity(card, identities_manager, use_flat_file_store);
                if (result) {
                    logger.trace(@"import_identities_cb: Added or updated '$(card.display_name)'");
                    import_count++;
                }
                else {
                    logger.trace(@"import_identities_cb: Did not add or update '$(card.display_name)'");
                }
            }
            if (import_count == 0) {
                info_dialog("Import completed", "Import completed. No identities were added or updated.");
            }
        }
    }

    public IdCard check_add_password(IdCard identity, IdentityRequest request, IdentityManagerModel model)
    {
        IdCard retval = identity;
        bool idcard_has_pw = (identity.password != null) && (identity.password != "");
        bool request_has_pw = (request.password != null) && (request.password != "");
        if ((!idcard_has_pw) && (!identity.is_no_identity())) {
            if (request_has_pw) {
                identity.password = request.password;
                retval = model.update_card(identity);
            } else {
                bool remember = true;
                identity.password = password_dialog(
                    "Enter password", "Enter the password for:\n\nIdentity: %s\nNAI: %s".printf(identity.display_name, identity.nai),
                    true, out remember);
                identity.store_password = remember;
                if (remember)
                    identity.temporary = false;
                retval = model.update_card(identity);
            }
        }

        // check 2FA
        if (retval.has_2fa) {
            retval.mfa_code = password_dialog(
                "Enter 2FA", "Enter the 2FA for:\n\nIdentity: %s\nNAI: %s".printf(identity.display_name, identity.nai),
                false, null);
        }

        return retval;
    }
}
