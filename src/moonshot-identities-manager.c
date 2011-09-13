/* moonshot-identities-manager.c generated by valac 0.10.4, the Vala compiler
 * generated from moonshot-identities-manager.vala, do not modify */


#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <gdk-pixbuf/gdk-pixdata.h>
#include <glib/gstdio.h>
#include <config.h>


#define TYPE_IDENTITIES_MANAGER (identities_manager_get_type ())
#define IDENTITIES_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_IDENTITIES_MANAGER, IdentitiesManager))
#define IDENTITIES_MANAGER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_IDENTITIES_MANAGER, IdentitiesManagerClass))
#define IS_IDENTITIES_MANAGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_IDENTITIES_MANAGER))
#define IS_IDENTITIES_MANAGER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_IDENTITIES_MANAGER))
#define IDENTITIES_MANAGER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_IDENTITIES_MANAGER, IdentitiesManagerClass))

typedef struct _IdentitiesManager IdentitiesManager;
typedef struct _IdentitiesManagerClass IdentitiesManagerClass;
typedef struct _IdentitiesManagerPrivate IdentitiesManagerPrivate;

#define TYPE_ID_CARD (id_card_get_type ())
#define ID_CARD(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_ID_CARD, IdCard))
#define ID_CARD_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_ID_CARD, IdCardClass))
#define IS_ID_CARD(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_ID_CARD))
#define IS_ID_CARD_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_ID_CARD))
#define ID_CARD_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_ID_CARD, IdCardClass))

typedef struct _IdCard IdCard;
typedef struct _IdCardClass IdCardClass;
#define __g_slist_free_g_object_unref0(var) ((var == NULL) ? NULL : (var = (_g_slist_free_g_object_unref (var), NULL)))
#define _g_error_free0(var) ((var == NULL) ? NULL : (var = (g_error_free (var), NULL)))
#define _g_free0(var) (var = (g_free (var), NULL))
#define _g_key_file_free0(var) ((var == NULL) ? NULL : (var = (g_key_file_free (var), NULL)))
#define _g_object_unref0(var) ((var == NULL) ? NULL : (var = (g_object_unref (var), NULL)))

#define TYPE_RULE (rule_get_type ())
typedef struct _Rule Rule;

#define TYPE_TRUST_ANCHOR (trust_anchor_get_type ())
#define TRUST_ANCHOR(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_TRUST_ANCHOR, TrustAnchor))
#define TRUST_ANCHOR_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_TRUST_ANCHOR, TrustAnchorClass))
#define IS_TRUST_ANCHOR(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_TRUST_ANCHOR))
#define IS_TRUST_ANCHOR_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_TRUST_ANCHOR))
#define TRUST_ANCHOR_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_TRUST_ANCHOR, TrustAnchorClass))

typedef struct _TrustAnchor TrustAnchor;
typedef struct _TrustAnchorClass TrustAnchorClass;

struct _IdentitiesManager {
	GObject parent_instance;
	IdentitiesManagerPrivate * priv;
	GSList* id_card_list;
};

struct _IdentitiesManagerClass {
	GObjectClass parent_class;
};

struct _Rule {
	char* pattern;
	char* always_confirm;
};


static gpointer identities_manager_parent_class = NULL;

GType identities_manager_get_type (void) G_GNUC_CONST;
GType id_card_get_type (void) G_GNUC_CONST;
enum  {
	IDENTITIES_MANAGER_DUMMY_PROPERTY
};
static void _g_slist_free_g_object_unref (GSList* self);
#define IDENTITIES_MANAGER_FILE_NAME "identities.txt"
IdentitiesManager* identities_manager_new (void);
IdentitiesManager* identities_manager_construct (GType object_type);
static char* identities_manager_get_data_dir (IdentitiesManager* self);
IdCard* id_card_new (void);
IdCard* id_card_construct (GType object_type);
void id_card_set_issuer (IdCard* self, const char* value);
void id_card_set_username (IdCard* self, const char* value);
void id_card_set_password (IdCard* self, const char* value);
void id_card_set_services (IdCard* self, char** value, int value_length1);
void id_card_set_display_name (IdCard* self, const char* value);
GdkPixbuf* find_icon (const char* name, gint size);
GType rule_get_type (void) G_GNUC_CONST;
Rule* rule_dup (const Rule* self);
void rule_free (Rule* self);
void rule_copy (const Rule* self, Rule* dest);
void rule_destroy (Rule* self);
void id_card_set_rules (IdCard* self, Rule* value, int value_length1);
static void _vala_Rule_array_free (Rule* array, gint array_length);
GType trust_anchor_get_type (void) G_GNUC_CONST;
TrustAnchor* id_card_get_trust_anchor (IdCard* self);
void trust_anchor_set_ca_cert (TrustAnchor* self, const char* value);
void trust_anchor_set_subject (TrustAnchor* self, const char* value);
void trust_anchor_set_subject_alt (TrustAnchor* self, const char* value);
void trust_anchor_set_server_cert (TrustAnchor* self, const char* value);
void identities_manager_store_id_cards (IdentitiesManager* self);
Rule* id_card_get_rules (IdCard* self, int* result_length1);
const char* id_card_get_issuer (IdCard* self);
const char* id_card_get_display_name (IdCard* self);
const char* id_card_get_username (IdCard* self);
const char* id_card_get_password (IdCard* self);
char** id_card_get_services (IdCard* self, int* result_length1);
static char** _vala_array_dup3 (char** self, int length);
const char* trust_anchor_get_ca_cert (TrustAnchor* self);
const char* trust_anchor_get_subject (TrustAnchor* self);
const char* trust_anchor_get_subject_alt (TrustAnchor* self);
const char* trust_anchor_get_server_cert (TrustAnchor* self);
static void identities_manager_finalize (GObject* obj);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);



static void _g_slist_free_g_object_unref (GSList* self) {
	g_slist_foreach (self, (GFunc) g_object_unref, NULL);
	g_slist_free (self);
}


static void _vala_Rule_array_free (Rule* array, gint array_length) {
	if (array != NULL) {
		int i;
		for (i = 0; i < array_length; i = i + 1) {
			rule_destroy (&array[i]);
		}
	}
	g_free (array);
}


static gpointer _g_object_ref0 (gpointer self) {
	return self ? g_object_ref (self) : NULL;
}


IdentitiesManager* identities_manager_construct (GType object_type) {
	IdentitiesManager * self = NULL;
	GSList* _tmp0_;
	GKeyFile* key_file;
	char* path;
	char* filename;
	gint identities_uris_length1;
	gint _identities_uris_size_;
	char** _tmp2_;
	gsize _tmp1_;
	char** identities_uris;
	GError * _inner_error_ = NULL;
	self = (IdentitiesManager*) g_object_new (object_type, NULL);
	self->id_card_list = (_tmp0_ = NULL, __g_slist_free_g_object_unref0 (self->id_card_list), _tmp0_);
	key_file = g_key_file_new ();
	path = identities_manager_get_data_dir (self);
	filename = g_build_filename (path, IDENTITIES_MANAGER_FILE_NAME, NULL);
	{
		g_key_file_load_from_file (key_file, filename, G_KEY_FILE_NONE, &_inner_error_);
		if (_inner_error_ != NULL) {
			goto __catch0_g_error;
		}
	}
	goto __finally0;
	__catch0_g_error:
	{
		GError * e;
		e = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stdout, "Error: %s\n", e->message);
			_g_error_free0 (e);
			_g_free0 (filename);
			_g_free0 (path);
			_g_key_file_free0 (key_file);
			return self;
		}
	}
	__finally0:
	if (_inner_error_ != NULL) {
		_g_free0 (filename);
		_g_free0 (path);
		_g_key_file_free0 (key_file);
		g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
		g_clear_error (&_inner_error_);
		return NULL;
	}
	identities_uris = (_tmp2_ = g_key_file_get_groups (key_file, &_tmp1_), identities_uris_length1 = _tmp1_, _identities_uris_size_ = identities_uris_length1, _tmp2_);
	{
		char** identity_collection;
		int identity_collection_length1;
		int identity_it;
		identity_collection = identities_uris;
		identity_collection_length1 = identities_uris_length1;
		for (identity_it = 0; identity_it < identities_uris_length1; identity_it = identity_it + 1) {
			char* identity;
			identity = g_strdup (identity_collection[identity_it]);
			{
				{
					IdCard* id_card;
					char* _tmp3_;
					char* _tmp4_;
					char* _tmp5_;
					char* _tmp6_;
					char* _tmp7_;
					char* _tmp8_;
					gint _tmp10__length1;
					gint __tmp10__size_;
					char** _tmp11_;
					gsize _tmp9_;
					char** _tmp10_;
					char** _tmp12_;
					gint _tmp12__length1;
					char** _tmp13_;
					char* _tmp14_;
					char* _tmp15_;
					gboolean _tmp16_ = FALSE;
					gboolean _tmp17_;
					char* _tmp28_;
					char* _tmp29_;
					char* _tmp30_;
					char* _tmp31_;
					char* _tmp32_;
					char* _tmp33_;
					char* _tmp34_;
					char* _tmp35_;
					id_card = id_card_new ();
					_tmp3_ = g_key_file_get_string (key_file, identity, "Issuer", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					id_card_set_issuer (id_card, _tmp4_ = _tmp3_);
					_g_free0 (_tmp4_);
					_tmp5_ = g_key_file_get_string (key_file, identity, "Username", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					id_card_set_username (id_card, _tmp6_ = _tmp5_);
					_g_free0 (_tmp6_);
					_tmp7_ = g_key_file_get_string (key_file, identity, "Password", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					id_card_set_password (id_card, _tmp8_ = _tmp7_);
					_g_free0 (_tmp8_);
					_tmp10_ = (_tmp11_ = g_key_file_get_string_list (key_file, identity, "Services", &_tmp9_, &_inner_error_), _tmp10__length1 = _tmp9_, __tmp10__size_ = _tmp10__length1, _tmp11_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					_tmp13_ = (_tmp12_ = _tmp10_, _tmp12__length1 = _tmp10__length1, _tmp12_);
					id_card_set_services (id_card, _tmp13_, _tmp10__length1);
					_tmp12_ = (_vala_array_free (_tmp12_, _tmp12__length1, (GDestroyNotify) g_free), NULL);
					_tmp14_ = g_key_file_get_string (key_file, identity, "DisplayName", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					id_card_set_display_name (id_card, _tmp15_ = _tmp14_);
					_g_free0 (_tmp15_);
					g_object_set_data_full ((GObject*) id_card, "pixbuf", find_icon ("avatar-default", 48), g_object_unref);
					_tmp17_ = g_key_file_has_key (key_file, identity, "Rules-Patterns", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					if (_tmp17_) {
						gboolean _tmp18_;
						_tmp18_ = g_key_file_has_key (key_file, identity, "Rules-AlwaysConfirm", &_inner_error_);
						if (_inner_error_ != NULL) {
							_g_object_unref0 (id_card);
							goto __catch1_g_error;
						}
						_tmp16_ = _tmp18_;
					} else {
						_tmp16_ = FALSE;
					}
					if (_tmp16_) {
						gint rules_patterns_length1;
						gint _rules_patterns_size_;
						char** _tmp20_;
						gsize _tmp19_;
						char** rules_patterns;
						gint rules_always_conf_length1;
						gint _rules_always_conf_size_;
						char** _tmp22_;
						gsize _tmp21_;
						char** rules_always_conf;
						rules_patterns = (_tmp20_ = g_key_file_get_string_list (key_file, identity, "Rules-Patterns", &_tmp19_, &_inner_error_), rules_patterns_length1 = _tmp19_, _rules_patterns_size_ = rules_patterns_length1, _tmp20_);
						if (_inner_error_ != NULL) {
							_g_object_unref0 (id_card);
							goto __catch1_g_error;
						}
						rules_always_conf = (_tmp22_ = g_key_file_get_string_list (key_file, identity, "Rules-AlwaysConfirm", &_tmp21_, &_inner_error_), rules_always_conf_length1 = _tmp21_, _rules_always_conf_size_ = rules_always_conf_length1, _tmp22_);
						if (_inner_error_ != NULL) {
							rules_patterns = (_vala_array_free (rules_patterns, rules_patterns_length1, (GDestroyNotify) g_free), NULL);
							_g_object_unref0 (id_card);
							goto __catch1_g_error;
						}
						if (rules_patterns_length1 == rules_always_conf_length1) {
							gint rules_length1;
							gint _rules_size_;
							Rule* _tmp23_;
							Rule* rules;
							Rule* _tmp27_;
							rules = (_tmp23_ = g_new0 (Rule, rules_patterns_length1), rules_length1 = rules_patterns_length1, _rules_size_ = rules_length1, _tmp23_);
							{
								gint i;
								i = 0;
								{
									gboolean _tmp24_;
									_tmp24_ = TRUE;
									while (TRUE) {
										Rule _tmp25_ = {0};
										Rule _tmp26_;
										if (!_tmp24_) {
											i++;
										}
										_tmp24_ = FALSE;
										if (!(i < rules_patterns_length1)) {
											break;
										}
										rules[i] = (_tmp26_ = (_tmp25_.pattern = g_strdup (rules_patterns[i]), _tmp25_.always_confirm = g_strdup (rules_always_conf[i]), _tmp25_), rule_destroy (&rules[i]), _tmp26_);
									}
								}
							}
							_tmp27_ = rules;
							id_card_set_rules (id_card, _tmp27_, rules_length1);
							rules = (_vala_Rule_array_free (rules, rules_length1), NULL);
						}
						rules_always_conf = (_vala_array_free (rules_always_conf, rules_always_conf_length1, (GDestroyNotify) g_free), NULL);
						rules_patterns = (_vala_array_free (rules_patterns, rules_patterns_length1, (GDestroyNotify) g_free), NULL);
					}
					_tmp28_ = g_key_file_get_string (key_file, identity, "CA-Cert", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					trust_anchor_set_ca_cert (id_card_get_trust_anchor (id_card), _tmp29_ = _tmp28_);
					_g_free0 (_tmp29_);
					_tmp30_ = g_key_file_get_string (key_file, identity, "Subject", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					trust_anchor_set_subject (id_card_get_trust_anchor (id_card), _tmp31_ = _tmp30_);
					_g_free0 (_tmp31_);
					_tmp32_ = g_key_file_get_string (key_file, identity, "SubjectAlt", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					trust_anchor_set_subject_alt (id_card_get_trust_anchor (id_card), _tmp33_ = _tmp32_);
					_g_free0 (_tmp33_);
					_tmp34_ = g_key_file_get_string (key_file, identity, "ServerCert", &_inner_error_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch1_g_error;
					}
					trust_anchor_set_server_cert (id_card_get_trust_anchor (id_card), _tmp35_ = _tmp34_);
					_g_free0 (_tmp35_);
					self->id_card_list = g_slist_prepend (self->id_card_list, _g_object_ref0 (id_card));
					_g_object_unref0 (id_card);
				}
				goto __finally1;
				__catch1_g_error:
				{
					GError * e;
					e = _inner_error_;
					_inner_error_ = NULL;
					{
						fprintf (stdout, "Error:  %s\n", e->message);
						_g_error_free0 (e);
					}
				}
				__finally1:
				if (_inner_error_ != NULL) {
					_g_free0 (identity);
					identities_uris = (_vala_array_free (identities_uris, identities_uris_length1, (GDestroyNotify) g_free), NULL);
					_g_free0 (filename);
					_g_free0 (path);
					_g_key_file_free0 (key_file);
					g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
					g_clear_error (&_inner_error_);
					return NULL;
				}
				_g_free0 (identity);
			}
		}
	}
	identities_uris = (_vala_array_free (identities_uris, identities_uris_length1, (GDestroyNotify) g_free), NULL);
	_g_free0 (filename);
	_g_free0 (path);
	_g_key_file_free0 (key_file);
	return self;
}


IdentitiesManager* identities_manager_new (void) {
	return identities_manager_construct (TYPE_IDENTITIES_MANAGER);
}


static char** _vala_array_dup3 (char** self, int length) {
	char** result;
	int i;
	result = g_new0 (char*, length + 1);
	for (i = 0; i < length; i++) {
		result[i] = g_strdup (self[i]);
	}
	return result;
}


void identities_manager_store_id_cards (IdentitiesManager* self) {
	GKeyFile* key_file;
	char* text;
	GError * _inner_error_ = NULL;
	g_return_if_fail (self != NULL);
	key_file = g_key_file_new ();
	{
		GSList* id_card_collection;
		GSList* id_card_it;
		id_card_collection = self->id_card_list;
		for (id_card_it = id_card_collection; id_card_it != NULL; id_card_it = id_card_it->next) {
			IdCard* id_card;
			id_card = _g_object_ref0 ((IdCard*) id_card_it->data);
			{
				gint rules_patterns_length1;
				gint _rules_patterns_size_;
				char** _tmp1_;
				gint _tmp0_;
				char** rules_patterns;
				gint rules_always_conf_length1;
				gint _rules_always_conf_size_;
				char** _tmp3_;
				gint _tmp2_;
				char** rules_always_conf;
				char* _tmp10_;
				char* _tmp12_;
				char* _tmp14_;
				char* _tmp16_;
				gint _tmp20__length1;
				gint __tmp20__size_;
				char** _tmp21_;
				gint _tmp18_;
				char** _tmp19_;
				char** _tmp20_;
				gint _tmp24_;
				char* _tmp25_;
				char* _tmp27_;
				char* _tmp29_;
				char* _tmp31_;
				rules_patterns = (_tmp1_ = g_new0 (char*, _tmp0_ + 1), rules_patterns_length1 = _tmp0_, _rules_patterns_size_ = rules_patterns_length1, _tmp1_);
				rules_always_conf = (_tmp3_ = g_new0 (char*, _tmp2_ + 1), rules_always_conf_length1 = _tmp2_, _rules_always_conf_size_ = rules_always_conf_length1, _tmp3_);
				{
					gint i;
					i = 0;
					{
						gboolean _tmp4_;
						_tmp4_ = TRUE;
						while (TRUE) {
							gint _tmp5_;
							gint _tmp6_;
							char* _tmp7_;
							gint _tmp8_;
							char* _tmp9_;
							if (!_tmp4_) {
								i++;
							}
							_tmp4_ = FALSE;
							if (!(i < _tmp5_)) {
								break;
							}
							rules_patterns[i] = (_tmp7_ = g_strdup (id_card_get_rules (id_card, &_tmp6_)[i].pattern), _g_free0 (rules_patterns[i]), _tmp7_);
							rules_always_conf[i] = (_tmp9_ = g_strdup (id_card_get_rules (id_card, &_tmp8_)[i].always_confirm), _g_free0 (rules_always_conf[i]), _tmp9_);
						}
					}
				}
				_tmp10_ = g_strdup (id_card_get_issuer (id_card));
				if (_tmp10_ == NULL) {
					char* _tmp11_;
					_tmp10_ = (_tmp11_ = g_strdup (""), _g_free0 (_tmp10_), _tmp11_);
				}
				g_key_file_set_string (key_file, id_card_get_display_name (id_card), "Issuer", _tmp10_);
				_tmp12_ = g_strdup (id_card_get_display_name (id_card));
				if (_tmp12_ == NULL) {
					char* _tmp13_;
					_tmp12_ = (_tmp13_ = g_strdup (""), _g_free0 (_tmp12_), _tmp13_);
				}
				g_key_file_set_string (key_file, id_card_get_display_name (id_card), "DisplayName", _tmp12_);
				_tmp14_ = g_strdup (id_card_get_username (id_card));
				if (_tmp14_ == NULL) {
					char* _tmp15_;
					_tmp14_ = (_tmp15_ = g_strdup (""), _g_free0 (_tmp14_), _tmp15_);
				}
				g_key_file_set_string (key_file, id_card_get_display_name (id_card), "Username", _tmp14_);
				_tmp16_ = g_strdup (id_card_get_password (id_card));
				if (_tmp16_ == NULL) {
					char* _tmp17_;
					_tmp16_ = (_tmp17_ = g_strdup (""), _g_free0 (_tmp16_), _tmp17_);
				}
				g_key_file_set_string (key_file, id_card_get_display_name (id_card), "Password", _tmp16_);
				_tmp20_ = (_tmp21_ = (_tmp19_ = id_card_get_services (id_card, &_tmp18_), (_tmp19_ == NULL) ? ((gpointer) _tmp19_) : _vala_array_dup3 (_tmp19_, _tmp18_)), _tmp20__length1 = _tmp18_, __tmp20__size_ = _tmp20__length1, _tmp21_);
				if (_tmp20_ == NULL) {
					char** _tmp22_ = NULL;
					char** _tmp23_;
					_tmp20_ = (_tmp23_ = (_tmp22_ = g_new0 (char*, 0 + 1), _tmp22_), _tmp20_ = (_vala_array_free (_tmp20_, _tmp20__length1, (GDestroyNotify) g_free), NULL), _tmp20__length1 = 0, __tmp20__size_ = _tmp20__length1, _tmp23_);
				}
				g_key_file_set_string_list (key_file, id_card_get_display_name (id_card), "Services", (const gchar* const*) _tmp20_, _tmp20__length1);
				if (_tmp24_ > 0) {
					g_key_file_set_string_list (key_file, id_card_get_display_name (id_card), "Rules-Patterns", (const gchar* const*) rules_patterns, rules_patterns_length1);
					g_key_file_set_string_list (key_file, id_card_get_display_name (id_card), "Rules-AlwaysConfirm", (const gchar* const*) rules_always_conf, rules_always_conf_length1);
				}
				_tmp25_ = g_strdup (trust_anchor_get_ca_cert (id_card_get_trust_anchor (id_card)));
				if (_tmp25_ == NULL) {
					char* _tmp26_;
					_tmp25_ = (_tmp26_ = g_strdup (""), _g_free0 (_tmp25_), _tmp26_);
				}
				g_key_file_set_string (key_file, id_card_get_display_name (id_card), "CA-Cert", _tmp25_);
				_tmp27_ = g_strdup (trust_anchor_get_subject (id_card_get_trust_anchor (id_card)));
				if (_tmp27_ == NULL) {
					char* _tmp28_;
					_tmp27_ = (_tmp28_ = g_strdup (""), _g_free0 (_tmp27_), _tmp28_);
				}
				g_key_file_set_string (key_file, id_card_get_display_name (id_card), "Subject", _tmp27_);
				_tmp29_ = g_strdup (trust_anchor_get_subject_alt (id_card_get_trust_anchor (id_card)));
				if (_tmp29_ == NULL) {
					char* _tmp30_;
					_tmp29_ = (_tmp30_ = g_strdup (""), _g_free0 (_tmp29_), _tmp30_);
				}
				g_key_file_set_string (key_file, id_card_get_display_name (id_card), "SubjectAlt", _tmp29_);
				_tmp31_ = g_strdup (trust_anchor_get_server_cert (id_card_get_trust_anchor (id_card)));
				if (_tmp31_ == NULL) {
					char* _tmp32_;
					_tmp31_ = (_tmp32_ = g_strdup (""), _g_free0 (_tmp31_), _tmp32_);
				}
				g_key_file_set_string (key_file, id_card_get_display_name (id_card), "ServerCert", _tmp31_);
				_g_free0 (_tmp31_);
				_g_free0 (_tmp29_);
				_g_free0 (_tmp27_);
				_g_free0 (_tmp25_);
				_tmp20_ = (_vala_array_free (_tmp20_, _tmp20__length1, (GDestroyNotify) g_free), NULL);
				_g_free0 (_tmp16_);
				_g_free0 (_tmp14_);
				_g_free0 (_tmp12_);
				_g_free0 (_tmp10_);
				rules_always_conf = (_vala_array_free (rules_always_conf, rules_always_conf_length1, (GDestroyNotify) g_free), NULL);
				rules_patterns = (_vala_array_free (rules_patterns, rules_patterns_length1, (GDestroyNotify) g_free), NULL);
				_g_object_unref0 (id_card);
			}
		}
	}
	text = g_key_file_to_data (key_file, NULL, NULL);
	{
		char* path;
		char* filename;
		path = identities_manager_get_data_dir (self);
		filename = g_build_filename (path, IDENTITIES_MANAGER_FILE_NAME, NULL);
		g_file_set_contents (filename, text, (gssize) (-1), &_inner_error_);
		if (_inner_error_ != NULL) {
			_g_free0 (filename);
			_g_free0 (path);
			goto __catch2_g_error;
		}
		_g_free0 (filename);
		_g_free0 (path);
	}
	goto __finally2;
	__catch2_g_error:
	{
		GError * e;
		e = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stdout, "Error:  %s\n", e->message);
			_g_error_free0 (e);
		}
	}
	__finally2:
	if (_inner_error_ != NULL) {
		_g_free0 (text);
		_g_key_file_free0 (key_file);
		g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
		g_clear_error (&_inner_error_);
		return;
	}
	_g_free0 (text);
	_g_key_file_free0 (key_file);
}


static char* identities_manager_get_data_dir (IdentitiesManager* self) {
	char* result = NULL;
	char* path;
	char* _tmp0_;
	g_return_val_if_fail (self != NULL, NULL);
	path = NULL;
	path = (_tmp0_ = g_build_filename (g_get_user_data_dir (), PACKAGE_TARNAME, NULL), _g_free0 (path), _tmp0_);
	if (!g_file_test (path, G_FILE_TEST_EXISTS)) {
		g_mkdir (path, 0700);
	}
	result = path;
	return result;
}


static void identities_manager_class_init (IdentitiesManagerClass * klass) {
	identities_manager_parent_class = g_type_class_peek_parent (klass);
	G_OBJECT_CLASS (klass)->finalize = identities_manager_finalize;
}


static void identities_manager_instance_init (IdentitiesManager * self) {
}


static void identities_manager_finalize (GObject* obj) {
	IdentitiesManager * self;
	self = IDENTITIES_MANAGER (obj);
	__g_slist_free_g_object_unref0 (self->id_card_list);
	G_OBJECT_CLASS (identities_manager_parent_class)->finalize (obj);
}


GType identities_manager_get_type (void) {
	static volatile gsize identities_manager_type_id__volatile = 0;
	if (g_once_init_enter (&identities_manager_type_id__volatile)) {
		static const GTypeInfo g_define_type_info = { sizeof (IdentitiesManagerClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) identities_manager_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (IdentitiesManager), 0, (GInstanceInitFunc) identities_manager_instance_init, NULL };
		GType identities_manager_type_id;
		identities_manager_type_id = g_type_register_static (G_TYPE_OBJECT, "IdentitiesManager", &g_define_type_info, 0);
		g_once_init_leave (&identities_manager_type_id__volatile, identities_manager_type_id);
	}
	return identities_manager_type_id__volatile;
}


static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func) {
	if ((array != NULL) && (destroy_func != NULL)) {
		int i;
		for (i = 0; i < array_length; i = i + 1) {
			if (((gpointer*) array)[i] != NULL) {
				destroy_func (((gpointer*) array)[i]);
			}
		}
	}
}


static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func) {
	_vala_array_destroy (array, array_length, destroy_func);
	g_free (array);
}




