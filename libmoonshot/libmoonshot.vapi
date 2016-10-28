/* Vala binding between libmoonshot helper library */

[CCode (cheader_filename = "libmoonshot.h")]
namespace Moonshot {
    [Compact]
    [CCode (cname = "MoonshotError", free_function = "moonshot_error_free")]
    public class Error {
        public int code;
        public string message;
    }

    /* A service matching rule; duplicated in moonshot-id.vala */
    [CCode (cname = "MoonshotServiceRule")]
    public struct ServiceRule {
        public string pattern;
        public string always_confirm;
    }

    [CCode (cname = "moonshot_get_identity")]
    public bool get_identity (string nai,
                              string password,
                              string service,
                              out string nai_out,
                              out string password_out,
                              out string server_certificate_hash_out,
                              out string ca_certificate_out,
                              out string subject_name_constraint_out,
                              out string subject_alt_name_constraint_out,
                              out Moonshot.Error error);

    [CCode (cname = "moonshot_get_default_identity")]
    public bool get_default_identity (out string nai_out,
                                      out string password_out,
                                      out string server_certificate_hash_out,
                                      out string ca_certificate_out,
                                      out string subject_name_constraint_out,
                                      out string subject_alt_name_constraint_out,
                                      out Moonshot.Error error);

    [CCode (cname = "moonshot_install_id_card")]
    public bool install_id_card (string display_name,
                                 string? user_name,
                                 string? password,
                                 string? realm,
                                 string rules_patterns[],
                                 string rules_always_confirm[],
                                 string services[],
                                 string? ca_cert,
                                 string? subject,
                                 string? subject_alt,
                                 string? server_cert,
                                 int force_flat_file_store,
                                 out Moonshot.Error error);

    [CCode (cname = "moonshot_confirm_ca_certificate")]
    public bool moonshot_confirm_ca_certificate (string identity_name,
                                                 string realm,
                                                 string ca_hash,
                                                 out uint32 confirmed,
                                                 out Moonshot.Error error);
}
