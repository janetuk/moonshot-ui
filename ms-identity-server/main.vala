/* ms-identity-server  Moonshot  library
 * Copyright (c) 2011, JANET(UK)
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
 *
 * Author: pete.fotheringham@codethink.co.uk>
 */

namespace MoonshotIdentityServer {
/**
 * get_identity:
 * @nai: Name and issuer constraint for the required identity, or %NULL.
 * @password: Password for the identity, or %NULL.
 * @service: Service constraint for the required identity, or %NULL.
 * @nai_out: A pointer to a string which receives the name and issuer of the
 *           selected identity.
 * @password_out: A pointer to a string which receives the password.
 * @server_certificate_hash_out: Receives a hash of the identity server's
 *                               certificate, or %NULL.
 * @ca_certificate_out: The CA certificate, if @server_certificate_hash was
 *                      %NULL.
 * @subject_name_constraint_out: Set if @ca_certificate is set, otherwise %NULL.
 * @subject_alt_name_constraint_out: Set if @ca_certificate is set, otherwise
 *                                   %NULL.
 * @error: Return location for a #MoonshotError.
 *
 * This function calls the Moonshot server to request an ID card. The server
 * will be activated if it is not already running. The user interface will be
 * displayed if there is more than one matching identity and the user will be
 * asked to select one.
 *
 * There are two types of trust anchor that may be returned. If
 * @server_certificate_hash is non-empty, the remaining parameters will be
 * empty. Otherwise, the @ca_certificate parameter and the subject name
 * constraints will be returned.
 *
 * Error reporting is handled by a simple mechanism similar to #GError. If
 * an error occurs, as well as returning %FALSE a #MoonshotError object will
 * be stored at *@error, with a code and message string. This must be freed
 * using moonshot_error_free().
 *
 * Return value: %TRUE if an identity was successfully selected, %FALSE on
 *               failure.
 */
  public async bool get_identity (string nai,
                                    string password,
                                    string service,
                                    out string nai_out,
                                    out string password_out,
                                    out string server_certificate_hash,
                                    out string ca_certificate,
                                    out string subject_name_constraint,
                                    out string subject_alt_name_constraint)
    {
        var request = new IdentityRequest (main_window,
                                           nai,
                                           password,
                                           service);
        request.set_callback ((IdentityRequest) => get_identity.callback());
        request.execute ();
        yield;

        nai_out = "";
        password_out = "";
        server_certificate_hash = "";
        ca_certificate = "";
        subject_name_constraint = "";
        subject_alt_name_constraint = "";

        var id_card = request.id_card;

        if (id_card != null) {
            nai_out = id_card.nai;
            password_out = id_card.password;

            server_certificate_hash = id_card.trust_anchor.server_cert;
            ca_certificate = id_card.trust_anchor.ca_cert;
            subject_name_constraint = id_card.trust_anchor.subject;
            subject_alt_name_constraint = id_card.trust_anchor.subject_alt;

            if (nai_out == null)
                nai_out = "";
            if (password_out == null)
                password_out = "";
            if (server_certificate_hash == null)
                server_certificate_hash = "";
            if (ca_certificate == null)
                ca_certificate = "";
            if (subject_name_constraint == null)
                subject_name_constraint = "";
            if (subject_alt_name_constraint == null)
                subject_alt_name_constraint = "";

            return true;
        }

        return false;
    }

/**
 * moonshot_get_default_identity:
 * @nai_out: A pointer to a string which receives the name and issuer of the
 *           identity.
 * @password_out: A pointer to a string which receives the password.
 * @server_certificate_hash_out: Receives a hash of the identity server's
 *                               certificate, or %NULL.
 * @ca_certificate_out: The CA certificate, if @server_certificate_hash was
 *                      %NULL.
 * @subject_name_constraint_out: Set if @ca_certificate is set, otherwise %NULL.
 * @subject_alt_name_constraint_out: Set if @ca_certificate is set, otherwise
 *                                   %NULL.
 * @error: Return location for a #MoonshotError.
 *
 * This function calls the Moonshot server to request the default identity
 * (the one most recently used). Its semantics are otherwise the same as
 * moonshot_get_identity().
 *
 * Return value: %TRUE if an identity was available, otherwise %FALSE.
 */
  public async bool get_default_identity (out string nai_out,
                                            out string password_out,
                                            out string server_certificate_hash,
                                            out string ca_certificate,
                                            out string subject_name_constraint,
                                            out string subject_alt_name_constraint)
    {
        var request = new IdentityRequest.default (main_window);
        request.set_callback ((IdentityRequest) => get_default_identity.callback());
        request.execute ();
        yield;

        nai_out = "";
        password_out = "";
        server_certificate_hash = "";
        ca_certificate = "";
        subject_name_constraint = "";
        subject_alt_name_constraint = "";

        if (request.id_card != null)
        {
            nai_out = request.id_card.nai;
            password_out = request.id_card.password;

            server_certificate_hash = request.id_card.trust_anchor.server_cert;
            ca_certificate = request.id_card.trust_anchor.ca_cert;
            subject_name_constraint = request.id_card.trust_anchor.subject;
            subject_alt_name_constraint = request.id_card.trust_anchor.subject_alt;

            if (nai_out == null)
                nai_out = "";
            if (password_out == null)
                password_out = "";
            if (server_certificate_hash == null)
                server_certificate_hash = "";
            if (ca_certificate == null)
                ca_certificate = "";
            if (subject_name_constraint == null)
                subject_name_constraint = "";
            if (subject_alt_name_constraint == null)
                subject_alt_name_constraint = "";

            return true;
        }

        return false;
    }

/**
 * moonshot_install_id_card:
 * @display_name: Display name of card
 * @user_name: Username for identity, or %NULL
 * @password: Password for identity, or %NULL
 * @realm: Realm for identity, or %NULL
 * @rules_patterns: Array of patterns for the service matching rules
 * @rules_patterns_length: Length of @rules_patterns and @rules_always_confirm arrays
 * @rules_always_confirm: Array of 'always confirm' flags corresponding to patterns
 * @rules_always_confirm_length: Length of @rules_patterns and @rules_always_confirm arrays
 * @services: Array of strings listing the services this identity provides
 * @services_length: Length of @services array
 * @ca_cert: The CA certificate, or %NULL
 * @subject: Subject name constraint for @ca_cert, or %NULL
 * @subject_alt: Subject alternative name constraint for @ca_cert, or %NULL
 * @server_cert: Hash of the server certificate; required if @ca_cert is %NULL
 * @error: Return location for a #MoonshotError.
 *
 * Calls the Moonshot server to add a new identity. The user will be prompted
 * if they would like to add the ID card.
 *
 * The values for @rules_patterns_length and @rules_always_confirm_length should
 * always be the same. They are present as separate parameters as a concession to
 * the Vala bindings.
 *
 * Return value: %TRUE if the ID card was successfully added, %FALSE otherwise
 */

    public bool install_id_card (string   display_name,
                                 string   user_name,
                                 string   password,
                                 string   realm,
                                 string[] rules_patterns,
                                 string[] rules_always_confirm,
                                 string[] services,
                                 string   ca_cert,
                                 string   subject,
                                 string   subject_alt,
                                 string   server_cert)
    {
      IdCard idcard = new IdCard ();

      idcard.display_name = display_name;
      idcard.username = user_name;
      idcard.password = password;
      idcard.issuer = realm;
      idcard.services = services;
      idcard.trust_anchor.ca_cert = ca_cert;
      idcard.trust_anchor.subject = subject;
      idcard.trust_anchor.subject_alt = subject_alt;
      idcard.trust_anchor.server_cert = server_cert;

      if (rules_patterns.length == rules_always_confirm.length)
      {
        idcard.rules = new Rule[rules_patterns.length];
         
        for (int i=0; i<idcard.rules.length; i++)
        { 
          idcard.rules[i].pattern = rules_patterns[i];
          idcard.rules[i].always_confirm = rules_always_confirm[i];
        }
      }

      return this.main_window.add_identity (idcard);
    }
}





















///**
// * moonshot_free:
// * @pointer: pointer to be freed
// *
// * All the strings returned by the get_identity() functions must be
// * freed using this function when they are no longer needed.
// *
// * @pointer may be %NULL, in which case no action is taken.
// */
//void moonshot_free (void *data);
//
//typedef enum {
//    MOONSHOT_ERROR_UNABLE_TO_START_SERVICE,
//    MOONSHOT_ERROR_NO_IDENTITY_SELECTED,
//    MOONSHOT_ERROR_INSTALLATION_ERROR,
//    MOONSHOT_ERROR_OS_ERROR,
//    MOONSHOT_ERROR_IPC_ERROR
//} MoonshotErrorCode;
//
//typedef struct {
//    int   code;    /* A MoonshotErrorCode */
//    char *message;
//} MoonshotError;
//
///**
// * moonshot_error_free:
// * @error: A #MoonshotError
// *
// * Releases the memory used by @error. This function must be called if
// * a function has returned an error, once it has been reported.
// */
//void moonshot_error_free (MoonshotError *error);
//
///**
// * moonshot_get_identity:
// * @nai: Name and issuer constraint for the required identity, or %NULL.
// * @password: Password for the identity, or %NULL.
// * @service: Service constraint for the required identity, or %NULL.
// * @nai_out: A pointer to a string which receives the name and issuer of the
// *           selected identity.
// * @password_out: A pointer to a string which receives the password.
// * @server_certificate_hash_out: Receives a hash of the identity server's
// *                               certificate, or %NULL.
// * @ca_certificate_out: The CA certificate, if @server_certificate_hash was
// *                      %NULL.
// * @subject_name_constraint_out: Set if @ca_certificate is set, otherwise %NULL.
// * @subject_alt_name_constraint_out: Set if @ca_certificate is set, otherwise
// *                                   %NULL.
// * @error: Return location for a #MoonshotError.
// *
// * This function calls the Moonshot server to request an ID card. The server
// * will be activated if it is not already running. The user interface will be
// * displayed if there is more than one matching identity and the user will be
// * asked to select one.
// *
// * There are two types of trust anchor that may be returned. If
// * @server_certificate_hash is non-empty, the remaining parameters will be
// * empty. Otherwise, the @ca_certificate parameter and the subject name
// * constraints will be returned.
// *
// * Error reporting is handled by a simple mechanism similar to #GError. If
// * an error occurs, as well as returning %FALSE a #MoonshotError object will
// * be stored at *@error, with a code and message string. This must be freed
// * using moonshot_error_free().
// *
// * Return value: %TRUE if an identity was successfully selected, %FALSE on
// *               failure.
// */
//int moonshot_get_identity (const char     *nai,
//                           const char     *password,
//                           const char     *service,
//                           char          **nai_out,
//                           char          **password_out,
//                           char          **server_certificate_hash_out,
//                           char          **ca_certificate_out,
//                           char          **subject_name_constraint_out,
//                           char          **subject_alt_name_constraint_out,
//                           MoonshotError **error);
//
///**
// * moonshot_get_default_identity:
// * @nai_out: A pointer to a string which receives the name and issuer of the
// *           identity.
// * @password_out: A pointer to a string which receives the password.
// * @server_certificate_hash_out: Receives a hash of the identity server's
// *                               certificate, or %NULL.
// * @ca_certificate_out: The CA certificate, if @server_certificate_hash was
// *                      %NULL.
// * @subject_name_constraint_out: Set if @ca_certificate is set, otherwise %NULL.
// * @subject_alt_name_constraint_out: Set if @ca_certificate is set, otherwise
// *                                   %NULL.
// * @error: Return location for a #MoonshotError.
// *
// * This function calls the Moonshot server to request the default identity
// * (the one most recently used). Its semantics are otherwise the same as
// * moonshot_get_identity().
// *
// * Return value: %TRUE if an identity was available, otherwise %FALSE.
// */
//int moonshot_get_default_identity (char          **nai_out,
//                                   char          **password_out,
//                                   char          **server_certificate_hash_out,
//                                   char          **ca_certificate_out,
//                                   char          **subject_name_constraint_out,
//                                   char          **subject_alt_name_constraint_out,
//                                   MoonshotError **error);
//
//
///**
// * moonshot_install_id_card:
// * @display_name: Display name of card
// * @user_name: Username for identity, or %NULL
// * @password: Password for identity, or %NULL
// * @realm: Realm for identity, or %NULL
// * @rules_patterns: Array of patterns for the service matching rules
// * @rules_patterns_length: Length of @rules_patterns and @rules_always_confirm arrays
// * @rules_always_confirm: Array of 'always confirm' flags corresponding to patterns
// * @rules_always_confirm_length: Length of @rules_patterns and @rules_always_confirm arrays
// * @services: Array of strings listing the services this identity provides
// * @services_length: Length of @services array
// * @ca_cert: The CA certificate, or %NULL
// * @subject: Subject name constraint for @ca_cert, or %NULL
// * @subject_alt: Subject alternative name constraint for @ca_cert, or %NULL
// * @server_cert: Hash of the server certificate; required if @ca_cert is %NULL
// * @error: Return location for a #MoonshotError.
// *
// * Calls the Moonshot server to add a new identity. The user will be prompted
// * if they would like to add the ID card.
// *
// * The values for @rules_patterns_length and @rules_always_confirm_length should
// * always be the same. They are present as separate parameters as a concession to
// * the Vala bindings.
// *
// * Return value: %TRUE if the ID card was successfully added, %FALSE otherwise
// */
//int moonshot_install_id_card (const char     *display_name,
//                              const char     *user_name,
//                              const char     *password,
//                              const char     *realm,
//                              char           *rules_patterns[],
//                              int             rules_patterns_length,
//                              char           *rules_always_confirm[],
//                              int             rules_always_confirm_length,
//                              char           *services[],
//                              int             services_length,
//                              const char     *ca_cert,
//                              const char     *subject,
//                              const char     *subject_alt,
//                              const char     *server_cert,
//                              MoonshotError **error);
//                             
}