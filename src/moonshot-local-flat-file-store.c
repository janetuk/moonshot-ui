/* moonshot-local-flat-file-store.c generated by valac 0.10.4, the Vala compiler
 * generated from moonshot-local-flat-file-store.vala, do not modify */


#include <glib.h>
#include <glib-object.h>
#include <gee.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <gdk-pixbuf/gdk-pixdata.h>
#include <config.h>
#include <glib/gstdio.h>


#define TYPE_IIDENTITY_CARD_STORE (iidentity_card_store_get_type ())
#define IIDENTITY_CARD_STORE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_IIDENTITY_CARD_STORE, IIdentityCardStore))
#define IS_IIDENTITY_CARD_STORE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_IIDENTITY_CARD_STORE))
#define IIDENTITY_CARD_STORE_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), TYPE_IIDENTITY_CARD_STORE, IIdentityCardStoreIface))

typedef struct _IIdentityCardStore IIdentityCardStore;
typedef struct _IIdentityCardStoreIface IIdentityCardStoreIface;

#define TYPE_ID_CARD (id_card_get_type ())
#define ID_CARD(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_ID_CARD, IdCard))
#define ID_CARD_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_ID_CARD, IdCardClass))
#define IS_ID_CARD(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_ID_CARD))
#define IS_ID_CARD_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_ID_CARD))
#define ID_CARD_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_ID_CARD, IdCardClass))

typedef struct _IdCard IdCard;
typedef struct _IdCardClass IdCardClass;

#define TYPE_LOCAL_FLAT_FILE_STORE (local_flat_file_store_get_type ())
#define LOCAL_FLAT_FILE_STORE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_LOCAL_FLAT_FILE_STORE, LocalFlatFileStore))
#define LOCAL_FLAT_FILE_STORE_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_LOCAL_FLAT_FILE_STORE, LocalFlatFileStoreClass))
#define IS_LOCAL_FLAT_FILE_STORE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_LOCAL_FLAT_FILE_STORE))
#define IS_LOCAL_FLAT_FILE_STORE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_LOCAL_FLAT_FILE_STORE))
#define LOCAL_FLAT_FILE_STORE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_LOCAL_FLAT_FILE_STORE, LocalFlatFileStoreClass))

typedef struct _LocalFlatFileStore LocalFlatFileStore;
typedef struct _LocalFlatFileStoreClass LocalFlatFileStoreClass;
typedef struct _LocalFlatFileStorePrivate LocalFlatFileStorePrivate;
#define _g_object_unref0(var) ((var == NULL) ? NULL : (var = (g_object_unref (var), NULL)))
#define _g_error_free0(var) ((var == NULL) ? NULL : (var = (g_error_free (var), NULL)))
#define _g_free0(var) (var = (g_free (var), NULL))
#define _g_key_file_free0(var) ((var == NULL) ? NULL : (var = (g_key_file_free (var), NULL)))

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

struct _IIdentityCardStoreIface {
	GTypeInterface parent_iface;
	void (*add_card) (IIdentityCardStore* self, IdCard* card);
	void (*remove_card) (IIdentityCardStore* self, IdCard* card);
	void (*update_card) (IIdentityCardStore* self, IdCard* card);
	GeeLinkedList* (*get_card_list) (IIdentityCardStore* self);
};

struct _LocalFlatFileStore {
	GObject parent_instance;
	LocalFlatFileStorePrivate * priv;
};

struct _LocalFlatFileStoreClass {
	GObjectClass parent_class;
};

struct _LocalFlatFileStorePrivate {
	GeeLinkedList* id_card_list;
};

struct _Rule {
	char* pattern;
	char* always_confirm;
};


static gpointer local_flat_file_store_parent_class = NULL;
static IIdentityCardStoreIface* local_flat_file_store_iidentity_card_store_parent_iface = NULL;

GType id_card_get_type (void) G_GNUC_CONST;
GType iidentity_card_store_get_type (void) G_GNUC_CONST;
GType local_flat_file_store_get_type (void) G_GNUC_CONST;
#define LOCAL_FLAT_FILE_STORE_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), TYPE_LOCAL_FLAT_FILE_STORE, LocalFlatFileStorePrivate))
enum  {
	LOCAL_FLAT_FILE_STORE_DUMMY_PROPERTY
};
#define LOCAL_FLAT_FILE_STORE_FILE_NAME "identities.txt"
static void local_flat_file_store_real_add_card (IIdentityCardStore* base, IdCard* card);
void local_flat_file_store_store_id_cards (LocalFlatFileStore* self);
static void local_flat_file_store_real_update_card (IIdentityCardStore* base, IdCard* card);
static void local_flat_file_store_real_remove_card (IIdentityCardStore* base, IdCard* card);
static GeeLinkedList* local_flat_file_store_real_get_card_list (IIdentityCardStore* base);
static void local_flat_file_store_load_id_cards (LocalFlatFileStore* self);
static char* local_flat_file_store_get_data_dir (LocalFlatFileStore* self);
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
Rule* id_card_get_rules (IdCard* self, int* result_length1);
const char* id_card_get_issuer (IdCard* self);
const char* id_card_get_display_name (IdCard* self);
const char* id_card_get_username (IdCard* self);
const char* id_card_get_password (IdCard* self);
char** id_card_get_services (IdCard* self, int* result_length1);
static char** _vala_array_dup1 (char** self, int length);
const char* trust_anchor_get_ca_cert (TrustAnchor* self);
const char* trust_anchor_get_subject (TrustAnchor* self);
const char* trust_anchor_get_subject_alt (TrustAnchor* self);
const char* trust_anchor_get_server_cert (TrustAnchor* self);
LocalFlatFileStore* local_flat_file_store_new (void);
LocalFlatFileStore* local_flat_file_store_construct (GType object_type);
static void local_flat_file_store_finalize (GObject* obj);
static void _vala_array_destroy (gpointer array, gint array_length, GDestroyNotify destroy_func);
static void _vala_array_free (gpointer array, gint array_length, GDestroyNotify destroy_func);



#line 7 "moonshot-local-flat-file-store.vala"
static void local_flat_file_store_real_add_card (IIdentityCardStore* base, IdCard* card) {
#line 150 "moonshot-local-flat-file-store.c"
	LocalFlatFileStore * self;
	self = (LocalFlatFileStore*) base;
#line 7 "moonshot-local-flat-file-store.vala"
	g_return_if_fail (card != NULL);
#line 8 "moonshot-local-flat-file-store.vala"
	gee_abstract_collection_add ((GeeAbstractCollection*) self->priv->id_card_list, card);
#line 9 "moonshot-local-flat-file-store.vala"
	local_flat_file_store_store_id_cards (self);
#line 159 "moonshot-local-flat-file-store.c"
}


#line 12 "moonshot-local-flat-file-store.vala"
static void local_flat_file_store_real_update_card (IIdentityCardStore* base, IdCard* card) {
#line 165 "moonshot-local-flat-file-store.c"
	LocalFlatFileStore * self;
	self = (LocalFlatFileStore*) base;
#line 12 "moonshot-local-flat-file-store.vala"
	g_return_if_fail (card != NULL);
#line 13 "moonshot-local-flat-file-store.vala"
	gee_abstract_collection_remove ((GeeAbstractCollection*) self->priv->id_card_list, card);
#line 14 "moonshot-local-flat-file-store.vala"
	gee_abstract_collection_add ((GeeAbstractCollection*) self->priv->id_card_list, card);
#line 15 "moonshot-local-flat-file-store.vala"
	local_flat_file_store_store_id_cards (self);
#line 176 "moonshot-local-flat-file-store.c"
}


#line 18 "moonshot-local-flat-file-store.vala"
static void local_flat_file_store_real_remove_card (IIdentityCardStore* base, IdCard* card) {
#line 182 "moonshot-local-flat-file-store.c"
	LocalFlatFileStore * self;
	self = (LocalFlatFileStore*) base;
#line 18 "moonshot-local-flat-file-store.vala"
	g_return_if_fail (card != NULL);
#line 19 "moonshot-local-flat-file-store.vala"
	gee_abstract_collection_remove ((GeeAbstractCollection*) self->priv->id_card_list, card);
#line 20 "moonshot-local-flat-file-store.vala"
	local_flat_file_store_store_id_cards (self);
#line 191 "moonshot-local-flat-file-store.c"
}


static gpointer _g_object_ref0 (gpointer self) {
	return self ? g_object_ref (self) : NULL;
}


#line 23 "moonshot-local-flat-file-store.vala"
static GeeLinkedList* local_flat_file_store_real_get_card_list (IIdentityCardStore* base) {
#line 202 "moonshot-local-flat-file-store.c"
	LocalFlatFileStore * self;
	GeeLinkedList* result = NULL;
	self = (LocalFlatFileStore*) base;
	result = _g_object_ref0 (self->priv->id_card_list);
#line 24 "moonshot-local-flat-file-store.vala"
	return result;
#line 209 "moonshot-local-flat-file-store.c"
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


#line 27 "moonshot-local-flat-file-store.vala"
static void local_flat_file_store_load_id_cards (LocalFlatFileStore* self) {
#line 226 "moonshot-local-flat-file-store.c"
	GKeyFile* key_file;
	char* path;
	char* filename;
	gint identities_uris_length1;
	gint _identities_uris_size_;
	char** _tmp1_;
	gsize _tmp0_;
	char** identities_uris;
	GError * _inner_error_ = NULL;
#line 27 "moonshot-local-flat-file-store.vala"
	g_return_if_fail (self != NULL);
#line 28 "moonshot-local-flat-file-store.vala"
	gee_abstract_collection_clear ((GeeAbstractCollection*) self->priv->id_card_list);
#line 29 "moonshot-local-flat-file-store.vala"
	key_file = g_key_file_new ();
#line 30 "moonshot-local-flat-file-store.vala"
	path = local_flat_file_store_get_data_dir (self);
#line 31 "moonshot-local-flat-file-store.vala"
	filename = g_build_filename (path, LOCAL_FLAT_FILE_STORE_FILE_NAME, NULL);
#line 246 "moonshot-local-flat-file-store.c"
	{
#line 34 "moonshot-local-flat-file-store.vala"
		g_key_file_load_from_file (key_file, filename, G_KEY_FILE_NONE, &_inner_error_);
#line 250 "moonshot-local-flat-file-store.c"
		if (_inner_error_ != NULL) {
			goto __catch2_g_error;
		}
	}
	goto __finally2;
	__catch2_g_error:
	{
		GError * e;
		e = _inner_error_;
		_inner_error_ = NULL;
		{
#line 37 "moonshot-local-flat-file-store.vala"
			fprintf (stdout, "Error: %s\n", e->message);
#line 264 "moonshot-local-flat-file-store.c"
			_g_error_free0 (e);
			_g_free0 (filename);
			_g_free0 (path);
			_g_key_file_free0 (key_file);
#line 38 "moonshot-local-flat-file-store.vala"
			return;
#line 271 "moonshot-local-flat-file-store.c"
		}
	}
	__finally2:
	if (_inner_error_ != NULL) {
		_g_free0 (filename);
		_g_free0 (path);
		_g_key_file_free0 (key_file);
		g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
		g_clear_error (&_inner_error_);
		return;
	}
	identities_uris = (_tmp1_ = g_key_file_get_groups (key_file, &_tmp0_), identities_uris_length1 = _tmp0_, _identities_uris_size_ = identities_uris_length1, _tmp1_);
	{
		char** identity_collection;
		int identity_collection_length1;
		int identity_it;
#line 42 "moonshot-local-flat-file-store.vala"
		identity_collection = identities_uris;
#line 290 "moonshot-local-flat-file-store.c"
		identity_collection_length1 = identities_uris_length1;
		for (identity_it = 0; identity_it < identities_uris_length1; identity_it = identity_it + 1) {
			char* identity;
			identity = g_strdup (identity_collection[identity_it]);
			{
				{
					IdCard* id_card;
					char* _tmp2_;
					char* _tmp3_;
					char* _tmp4_;
					char* _tmp5_;
					char* _tmp6_;
					char* _tmp7_;
					gint _tmp9__length1;
					gint __tmp9__size_;
					char** _tmp10_;
					gsize _tmp8_;
					char** _tmp9_;
					char** _tmp11_;
					gint _tmp11__length1;
					char** _tmp12_;
					char* _tmp13_;
					char* _tmp14_;
					gboolean _tmp15_ = FALSE;
					gboolean _tmp16_;
					char* _tmp27_;
					char* _tmp28_;
					char* _tmp29_;
					char* _tmp30_;
					char* _tmp31_;
					char* _tmp32_;
					char* _tmp33_;
					char* _tmp34_;
#line 44 "moonshot-local-flat-file-store.vala"
					id_card = id_card_new ();
#line 46 "moonshot-local-flat-file-store.vala"
					_tmp2_ = g_key_file_get_string (key_file, identity, "Issuer", &_inner_error_);
#line 328 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 46 "moonshot-local-flat-file-store.vala"
					id_card_set_issuer (id_card, _tmp3_ = _tmp2_);
#line 335 "moonshot-local-flat-file-store.c"
					_g_free0 (_tmp3_);
#line 47 "moonshot-local-flat-file-store.vala"
					_tmp4_ = g_key_file_get_string (key_file, identity, "Username", &_inner_error_);
#line 339 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 47 "moonshot-local-flat-file-store.vala"
					id_card_set_username (id_card, _tmp5_ = _tmp4_);
#line 346 "moonshot-local-flat-file-store.c"
					_g_free0 (_tmp5_);
#line 48 "moonshot-local-flat-file-store.vala"
					_tmp6_ = g_key_file_get_string (key_file, identity, "Password", &_inner_error_);
#line 350 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 48 "moonshot-local-flat-file-store.vala"
					id_card_set_password (id_card, _tmp7_ = _tmp6_);
#line 357 "moonshot-local-flat-file-store.c"
					_g_free0 (_tmp7_);
					_tmp9_ = (_tmp10_ = g_key_file_get_string_list (key_file, identity, "Services", &_tmp8_, &_inner_error_), _tmp9__length1 = _tmp8_, __tmp9__size_ = _tmp9__length1, _tmp10_);
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 49 "moonshot-local-flat-file-store.vala"
					_tmp12_ = (_tmp11_ = _tmp9_, _tmp11__length1 = _tmp9__length1, _tmp11_);
#line 49 "moonshot-local-flat-file-store.vala"
					id_card_set_services (id_card, _tmp12_, _tmp9__length1);
#line 368 "moonshot-local-flat-file-store.c"
					_tmp11_ = (_vala_array_free (_tmp11_, _tmp11__length1, (GDestroyNotify) g_free), NULL);
#line 50 "moonshot-local-flat-file-store.vala"
					_tmp13_ = g_key_file_get_string (key_file, identity, "DisplayName", &_inner_error_);
#line 372 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 50 "moonshot-local-flat-file-store.vala"
					id_card_set_display_name (id_card, _tmp14_ = _tmp13_);
#line 379 "moonshot-local-flat-file-store.c"
					_g_free0 (_tmp14_);
#line 51 "moonshot-local-flat-file-store.vala"
					g_object_set_data_full ((GObject*) id_card, "pixbuf", find_icon ("avatar-default", 48), g_object_unref);
#line 54 "moonshot-local-flat-file-store.vala"
					_tmp16_ = g_key_file_has_key (key_file, identity, "Rules-Patterns", &_inner_error_);
#line 385 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 54 "moonshot-local-flat-file-store.vala"
					if (_tmp16_) {
#line 392 "moonshot-local-flat-file-store.c"
						gboolean _tmp17_;
#line 55 "moonshot-local-flat-file-store.vala"
						_tmp17_ = g_key_file_has_key (key_file, identity, "Rules-AlwaysConfirm", &_inner_error_);
#line 396 "moonshot-local-flat-file-store.c"
						if (_inner_error_ != NULL) {
							_g_object_unref0 (id_card);
							goto __catch3_g_error;
						}
#line 55 "moonshot-local-flat-file-store.vala"
						_tmp15_ = _tmp17_;
#line 403 "moonshot-local-flat-file-store.c"
					} else {
#line 54 "moonshot-local-flat-file-store.vala"
						_tmp15_ = FALSE;
#line 407 "moonshot-local-flat-file-store.c"
					}
#line 54 "moonshot-local-flat-file-store.vala"
					if (_tmp15_) {
#line 411 "moonshot-local-flat-file-store.c"
						gint rules_patterns_length1;
						gint _rules_patterns_size_;
						char** _tmp19_;
						gsize _tmp18_;
						char** rules_patterns;
						gint rules_always_conf_length1;
						gint _rules_always_conf_size_;
						char** _tmp21_;
						gsize _tmp20_;
						char** rules_always_conf;
						rules_patterns = (_tmp19_ = g_key_file_get_string_list (key_file, identity, "Rules-Patterns", &_tmp18_, &_inner_error_), rules_patterns_length1 = _tmp18_, _rules_patterns_size_ = rules_patterns_length1, _tmp19_);
						if (_inner_error_ != NULL) {
							_g_object_unref0 (id_card);
							goto __catch3_g_error;
						}
						rules_always_conf = (_tmp21_ = g_key_file_get_string_list (key_file, identity, "Rules-AlwaysConfirm", &_tmp20_, &_inner_error_), rules_always_conf_length1 = _tmp20_, _rules_always_conf_size_ = rules_always_conf_length1, _tmp21_);
						if (_inner_error_ != NULL) {
							rules_patterns = (_vala_array_free (rules_patterns, rules_patterns_length1, (GDestroyNotify) g_free), NULL);
							_g_object_unref0 (id_card);
							goto __catch3_g_error;
						}
#line 59 "moonshot-local-flat-file-store.vala"
						if (rules_patterns_length1 == rules_always_conf_length1) {
#line 435 "moonshot-local-flat-file-store.c"
							gint rules_length1;
							gint _rules_size_;
							Rule* _tmp22_;
							Rule* rules;
							Rule* _tmp26_;
							rules = (_tmp22_ = g_new0 (Rule, rules_patterns_length1), rules_length1 = rules_patterns_length1, _rules_size_ = rules_length1, _tmp22_);
							{
								gint i;
#line 61 "moonshot-local-flat-file-store.vala"
								i = 0;
#line 446 "moonshot-local-flat-file-store.c"
								{
									gboolean _tmp23_;
#line 61 "moonshot-local-flat-file-store.vala"
									_tmp23_ = TRUE;
#line 61 "moonshot-local-flat-file-store.vala"
									while (TRUE) {
#line 453 "moonshot-local-flat-file-store.c"
										Rule _tmp24_ = {0};
										Rule _tmp25_;
#line 61 "moonshot-local-flat-file-store.vala"
										if (!_tmp23_) {
#line 61 "moonshot-local-flat-file-store.vala"
											i++;
#line 460 "moonshot-local-flat-file-store.c"
										}
#line 61 "moonshot-local-flat-file-store.vala"
										_tmp23_ = FALSE;
#line 61 "moonshot-local-flat-file-store.vala"
										if (!(i < rules_patterns_length1)) {
#line 61 "moonshot-local-flat-file-store.vala"
											break;
#line 468 "moonshot-local-flat-file-store.c"
										}
#line 62 "moonshot-local-flat-file-store.vala"
										rules[i] = (_tmp25_ = (_tmp24_.pattern = g_strdup (rules_patterns[i]), _tmp24_.always_confirm = g_strdup (rules_always_conf[i]), _tmp24_), rule_destroy (&rules[i]), _tmp25_);
#line 472 "moonshot-local-flat-file-store.c"
									}
								}
							}
#line 64 "moonshot-local-flat-file-store.vala"
							_tmp26_ = rules;
#line 64 "moonshot-local-flat-file-store.vala"
							id_card_set_rules (id_card, _tmp26_, rules_length1);
#line 480 "moonshot-local-flat-file-store.c"
							rules = (_vala_Rule_array_free (rules, rules_length1), NULL);
						}
						rules_always_conf = (_vala_array_free (rules_always_conf, rules_always_conf_length1, (GDestroyNotify) g_free), NULL);
						rules_patterns = (_vala_array_free (rules_patterns, rules_patterns_length1, (GDestroyNotify) g_free), NULL);
					}
#line 69 "moonshot-local-flat-file-store.vala"
					_tmp27_ = g_key_file_get_string (key_file, identity, "CA-Cert", &_inner_error_);
#line 488 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 69 "moonshot-local-flat-file-store.vala"
					trust_anchor_set_ca_cert (id_card_get_trust_anchor (id_card), _tmp28_ = _tmp27_);
#line 495 "moonshot-local-flat-file-store.c"
					_g_free0 (_tmp28_);
#line 70 "moonshot-local-flat-file-store.vala"
					_tmp29_ = g_key_file_get_string (key_file, identity, "Subject", &_inner_error_);
#line 499 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 70 "moonshot-local-flat-file-store.vala"
					trust_anchor_set_subject (id_card_get_trust_anchor (id_card), _tmp30_ = _tmp29_);
#line 506 "moonshot-local-flat-file-store.c"
					_g_free0 (_tmp30_);
#line 71 "moonshot-local-flat-file-store.vala"
					_tmp31_ = g_key_file_get_string (key_file, identity, "SubjectAlt", &_inner_error_);
#line 510 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 71 "moonshot-local-flat-file-store.vala"
					trust_anchor_set_subject_alt (id_card_get_trust_anchor (id_card), _tmp32_ = _tmp31_);
#line 517 "moonshot-local-flat-file-store.c"
					_g_free0 (_tmp32_);
#line 72 "moonshot-local-flat-file-store.vala"
					_tmp33_ = g_key_file_get_string (key_file, identity, "ServerCert", &_inner_error_);
#line 521 "moonshot-local-flat-file-store.c"
					if (_inner_error_ != NULL) {
						_g_object_unref0 (id_card);
						goto __catch3_g_error;
					}
#line 72 "moonshot-local-flat-file-store.vala"
					trust_anchor_set_server_cert (id_card_get_trust_anchor (id_card), _tmp34_ = _tmp33_);
#line 528 "moonshot-local-flat-file-store.c"
					_g_free0 (_tmp34_);
#line 74 "moonshot-local-flat-file-store.vala"
					gee_abstract_collection_add ((GeeAbstractCollection*) self->priv->id_card_list, id_card);
#line 532 "moonshot-local-flat-file-store.c"
					_g_object_unref0 (id_card);
				}
				goto __finally3;
				__catch3_g_error:
				{
					GError * e;
					e = _inner_error_;
					_inner_error_ = NULL;
					{
#line 77 "moonshot-local-flat-file-store.vala"
						fprintf (stdout, "Error:  %s\n", e->message);
#line 544 "moonshot-local-flat-file-store.c"
						_g_error_free0 (e);
					}
				}
				__finally3:
				if (_inner_error_ != NULL) {
					_g_free0 (identity);
					identities_uris = (_vala_array_free (identities_uris, identities_uris_length1, (GDestroyNotify) g_free), NULL);
					_g_free0 (filename);
					_g_free0 (path);
					_g_key_file_free0 (key_file);
					g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
					g_clear_error (&_inner_error_);
					return;
				}
				_g_free0 (identity);
			}
		}
	}
	identities_uris = (_vala_array_free (identities_uris, identities_uris_length1, (GDestroyNotify) g_free), NULL);
	_g_free0 (filename);
	_g_free0 (path);
	_g_key_file_free0 (key_file);
}


#line 82 "moonshot-local-flat-file-store.vala"
static char* local_flat_file_store_get_data_dir (LocalFlatFileStore* self) {
#line 572 "moonshot-local-flat-file-store.c"
	char* result = NULL;
	char* path;
	char* _tmp0_;
#line 82 "moonshot-local-flat-file-store.vala"
	g_return_val_if_fail (self != NULL, NULL);
#line 578 "moonshot-local-flat-file-store.c"
	path = NULL;
#line 84 "moonshot-local-flat-file-store.vala"
	path = (_tmp0_ = g_build_filename (g_get_user_data_dir (), PACKAGE_TARNAME, NULL), _g_free0 (path), _tmp0_);
#line 87 "moonshot-local-flat-file-store.vala"
	if (!g_file_test (path, G_FILE_TEST_EXISTS)) {
#line 88 "moonshot-local-flat-file-store.vala"
		g_mkdir_with_parents (path, 0700);
#line 586 "moonshot-local-flat-file-store.c"
	}
	result = path;
#line 90 "moonshot-local-flat-file-store.vala"
	return result;
#line 591 "moonshot-local-flat-file-store.c"
}


static char** _vala_array_dup1 (char** self, int length) {
	char** result;
	int i;
	result = g_new0 (char*, length + 1);
	for (i = 0; i < length; i++) {
		result[i] = g_strdup (self[i]);
	}
	return result;
}


#line 93 "moonshot-local-flat-file-store.vala"
void local_flat_file_store_store_id_cards (LocalFlatFileStore* self) {
#line 608 "moonshot-local-flat-file-store.c"
	GKeyFile* key_file;
	char* text;
	GError * _inner_error_ = NULL;
#line 93 "moonshot-local-flat-file-store.vala"
	g_return_if_fail (self != NULL);
#line 94 "moonshot-local-flat-file-store.vala"
	key_file = g_key_file_new ();
#line 616 "moonshot-local-flat-file-store.c"
	{
		GeeIterator* _id_card_it;
#line 95 "moonshot-local-flat-file-store.vala"
		_id_card_it = gee_abstract_collection_iterator ((GeeAbstractCollection*) self->priv->id_card_list);
#line 95 "moonshot-local-flat-file-store.vala"
		while (TRUE) {
#line 623 "moonshot-local-flat-file-store.c"
			IdCard* id_card;
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
#line 95 "moonshot-local-flat-file-store.vala"
			if (!gee_iterator_next (_id_card_it)) {
#line 95 "moonshot-local-flat-file-store.vala"
				break;
#line 654 "moonshot-local-flat-file-store.c"
			}
#line 95 "moonshot-local-flat-file-store.vala"
			id_card = (IdCard*) gee_iterator_get (_id_card_it);
#line 658 "moonshot-local-flat-file-store.c"
			rules_patterns = (_tmp1_ = g_new0 (char*, _tmp0_ + 1), rules_patterns_length1 = _tmp0_, _rules_patterns_size_ = rules_patterns_length1, _tmp1_);
			rules_always_conf = (_tmp3_ = g_new0 (char*, _tmp2_ + 1), rules_always_conf_length1 = _tmp2_, _rules_always_conf_size_ = rules_always_conf_length1, _tmp3_);
			{
				gint i;
#line 99 "moonshot-local-flat-file-store.vala"
				i = 0;
#line 665 "moonshot-local-flat-file-store.c"
				{
					gboolean _tmp4_;
#line 99 "moonshot-local-flat-file-store.vala"
					_tmp4_ = TRUE;
#line 99 "moonshot-local-flat-file-store.vala"
					while (TRUE) {
#line 672 "moonshot-local-flat-file-store.c"
						gint _tmp5_;
						gint _tmp6_;
						char* _tmp7_;
						gint _tmp8_;
						char* _tmp9_;
#line 99 "moonshot-local-flat-file-store.vala"
						if (!_tmp4_) {
#line 99 "moonshot-local-flat-file-store.vala"
							i++;
#line 682 "moonshot-local-flat-file-store.c"
						}
#line 99 "moonshot-local-flat-file-store.vala"
						_tmp4_ = FALSE;
#line 99 "moonshot-local-flat-file-store.vala"
						if (!(i < _tmp5_)) {
#line 99 "moonshot-local-flat-file-store.vala"
							break;
#line 690 "moonshot-local-flat-file-store.c"
						}
#line 100 "moonshot-local-flat-file-store.vala"
						rules_patterns[i] = (_tmp7_ = g_strdup (id_card_get_rules (id_card, &_tmp6_)[i].pattern), _g_free0 (rules_patterns[i]), _tmp7_);
#line 101 "moonshot-local-flat-file-store.vala"
						rules_always_conf[i] = (_tmp9_ = g_strdup (id_card_get_rules (id_card, &_tmp8_)[i].always_confirm), _g_free0 (rules_always_conf[i]), _tmp9_);
#line 696 "moonshot-local-flat-file-store.c"
					}
				}
			}
#line 104 "moonshot-local-flat-file-store.vala"
			_tmp10_ = g_strdup (id_card_get_issuer (id_card));
#line 104 "moonshot-local-flat-file-store.vala"
			if (_tmp10_ == NULL) {
#line 704 "moonshot-local-flat-file-store.c"
				char* _tmp11_;
#line 104 "moonshot-local-flat-file-store.vala"
				_tmp10_ = (_tmp11_ = g_strdup (""), _g_free0 (_tmp10_), _tmp11_);
#line 708 "moonshot-local-flat-file-store.c"
			}
#line 104 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string (key_file, id_card_get_display_name (id_card), "Issuer", _tmp10_);
#line 105 "moonshot-local-flat-file-store.vala"
			_tmp12_ = g_strdup (id_card_get_display_name (id_card));
#line 105 "moonshot-local-flat-file-store.vala"
			if (_tmp12_ == NULL) {
#line 716 "moonshot-local-flat-file-store.c"
				char* _tmp13_;
#line 105 "moonshot-local-flat-file-store.vala"
				_tmp12_ = (_tmp13_ = g_strdup (""), _g_free0 (_tmp12_), _tmp13_);
#line 720 "moonshot-local-flat-file-store.c"
			}
#line 105 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string (key_file, id_card_get_display_name (id_card), "DisplayName", _tmp12_);
#line 106 "moonshot-local-flat-file-store.vala"
			_tmp14_ = g_strdup (id_card_get_username (id_card));
#line 106 "moonshot-local-flat-file-store.vala"
			if (_tmp14_ == NULL) {
#line 728 "moonshot-local-flat-file-store.c"
				char* _tmp15_;
#line 106 "moonshot-local-flat-file-store.vala"
				_tmp14_ = (_tmp15_ = g_strdup (""), _g_free0 (_tmp14_), _tmp15_);
#line 732 "moonshot-local-flat-file-store.c"
			}
#line 106 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string (key_file, id_card_get_display_name (id_card), "Username", _tmp14_);
#line 107 "moonshot-local-flat-file-store.vala"
			_tmp16_ = g_strdup (id_card_get_password (id_card));
#line 107 "moonshot-local-flat-file-store.vala"
			if (_tmp16_ == NULL) {
#line 740 "moonshot-local-flat-file-store.c"
				char* _tmp17_;
#line 107 "moonshot-local-flat-file-store.vala"
				_tmp16_ = (_tmp17_ = g_strdup (""), _g_free0 (_tmp16_), _tmp17_);
#line 744 "moonshot-local-flat-file-store.c"
			}
#line 107 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string (key_file, id_card_get_display_name (id_card), "Password", _tmp16_);
#line 748 "moonshot-local-flat-file-store.c"
			_tmp20_ = (_tmp21_ = (_tmp19_ = id_card_get_services (id_card, &_tmp18_), (_tmp19_ == NULL) ? ((gpointer) _tmp19_) : _vala_array_dup1 (_tmp19_, _tmp18_)), _tmp20__length1 = _tmp18_, __tmp20__size_ = _tmp20__length1, _tmp21_);
#line 108 "moonshot-local-flat-file-store.vala"
			if (_tmp20_ == NULL) {
#line 752 "moonshot-local-flat-file-store.c"
				char** _tmp22_ = NULL;
				char** _tmp23_;
#line 108 "moonshot-local-flat-file-store.vala"
				_tmp20_ = (_tmp23_ = (_tmp22_ = g_new0 (char*, 0 + 1), _tmp22_), _tmp20_ = (_vala_array_free (_tmp20_, _tmp20__length1, (GDestroyNotify) g_free), NULL), _tmp20__length1 = 0, __tmp20__size_ = _tmp20__length1, _tmp23_);
#line 757 "moonshot-local-flat-file-store.c"
			}
#line 108 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string_list (key_file, id_card_get_display_name (id_card), "Services", (const gchar* const*) _tmp20_, _tmp20__length1);
#line 110 "moonshot-local-flat-file-store.vala"
			if (_tmp24_ > 0) {
#line 111 "moonshot-local-flat-file-store.vala"
				g_key_file_set_string_list (key_file, id_card_get_display_name (id_card), "Rules-Patterns", (const gchar* const*) rules_patterns, rules_patterns_length1);
#line 112 "moonshot-local-flat-file-store.vala"
				g_key_file_set_string_list (key_file, id_card_get_display_name (id_card), "Rules-AlwaysConfirm", (const gchar* const*) rules_always_conf, rules_always_conf_length1);
#line 767 "moonshot-local-flat-file-store.c"
			}
#line 116 "moonshot-local-flat-file-store.vala"
			_tmp25_ = g_strdup (trust_anchor_get_ca_cert (id_card_get_trust_anchor (id_card)));
#line 116 "moonshot-local-flat-file-store.vala"
			if (_tmp25_ == NULL) {
#line 773 "moonshot-local-flat-file-store.c"
				char* _tmp26_;
#line 116 "moonshot-local-flat-file-store.vala"
				_tmp25_ = (_tmp26_ = g_strdup (""), _g_free0 (_tmp25_), _tmp26_);
#line 777 "moonshot-local-flat-file-store.c"
			}
#line 116 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string (key_file, id_card_get_display_name (id_card), "CA-Cert", _tmp25_);
#line 117 "moonshot-local-flat-file-store.vala"
			_tmp27_ = g_strdup (trust_anchor_get_subject (id_card_get_trust_anchor (id_card)));
#line 117 "moonshot-local-flat-file-store.vala"
			if (_tmp27_ == NULL) {
#line 785 "moonshot-local-flat-file-store.c"
				char* _tmp28_;
#line 117 "moonshot-local-flat-file-store.vala"
				_tmp27_ = (_tmp28_ = g_strdup (""), _g_free0 (_tmp27_), _tmp28_);
#line 789 "moonshot-local-flat-file-store.c"
			}
#line 117 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string (key_file, id_card_get_display_name (id_card), "Subject", _tmp27_);
#line 118 "moonshot-local-flat-file-store.vala"
			_tmp29_ = g_strdup (trust_anchor_get_subject_alt (id_card_get_trust_anchor (id_card)));
#line 118 "moonshot-local-flat-file-store.vala"
			if (_tmp29_ == NULL) {
#line 797 "moonshot-local-flat-file-store.c"
				char* _tmp30_;
#line 118 "moonshot-local-flat-file-store.vala"
				_tmp29_ = (_tmp30_ = g_strdup (""), _g_free0 (_tmp29_), _tmp30_);
#line 801 "moonshot-local-flat-file-store.c"
			}
#line 118 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string (key_file, id_card_get_display_name (id_card), "SubjectAlt", _tmp29_);
#line 119 "moonshot-local-flat-file-store.vala"
			_tmp31_ = g_strdup (trust_anchor_get_server_cert (id_card_get_trust_anchor (id_card)));
#line 119 "moonshot-local-flat-file-store.vala"
			if (_tmp31_ == NULL) {
#line 809 "moonshot-local-flat-file-store.c"
				char* _tmp32_;
#line 119 "moonshot-local-flat-file-store.vala"
				_tmp31_ = (_tmp32_ = g_strdup (""), _g_free0 (_tmp31_), _tmp32_);
#line 813 "moonshot-local-flat-file-store.c"
			}
#line 119 "moonshot-local-flat-file-store.vala"
			g_key_file_set_string (key_file, id_card_get_display_name (id_card), "ServerCert", _tmp31_);
#line 817 "moonshot-local-flat-file-store.c"
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
		_g_object_unref0 (_id_card_it);
	}
#line 122 "moonshot-local-flat-file-store.vala"
	text = g_key_file_to_data (key_file, NULL, NULL);
#line 835 "moonshot-local-flat-file-store.c"
	{
		char* path;
		char* filename;
#line 125 "moonshot-local-flat-file-store.vala"
		path = local_flat_file_store_get_data_dir (self);
#line 126 "moonshot-local-flat-file-store.vala"
		filename = g_build_filename (path, LOCAL_FLAT_FILE_STORE_FILE_NAME, NULL);
#line 127 "moonshot-local-flat-file-store.vala"
		g_file_set_contents (filename, text, (gssize) (-1), &_inner_error_);
#line 845 "moonshot-local-flat-file-store.c"
		if (_inner_error_ != NULL) {
			_g_free0 (filename);
			_g_free0 (path);
			goto __catch4_g_error;
		}
		_g_free0 (filename);
		_g_free0 (path);
	}
	goto __finally4;
	__catch4_g_error:
	{
		GError * e;
		e = _inner_error_;
		_inner_error_ = NULL;
		{
#line 130 "moonshot-local-flat-file-store.vala"
			fprintf (stdout, "Error:  %s\n", e->message);
#line 863 "moonshot-local-flat-file-store.c"
			_g_error_free0 (e);
		}
	}
	__finally4:
	if (_inner_error_ != NULL) {
		_g_free0 (text);
		_g_key_file_free0 (key_file);
		g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
		g_clear_error (&_inner_error_);
		return;
	}
#line 133 "moonshot-local-flat-file-store.vala"
	local_flat_file_store_load_id_cards (self);
#line 877 "moonshot-local-flat-file-store.c"
	_g_free0 (text);
	_g_key_file_free0 (key_file);
}


#line 136 "moonshot-local-flat-file-store.vala"
LocalFlatFileStore* local_flat_file_store_construct (GType object_type) {
#line 885 "moonshot-local-flat-file-store.c"
	LocalFlatFileStore * self = NULL;
	GeeLinkedList* _tmp0_;
#line 136 "moonshot-local-flat-file-store.vala"
	self = (LocalFlatFileStore*) g_object_new (object_type, NULL);
#line 137 "moonshot-local-flat-file-store.vala"
	self->priv->id_card_list = (_tmp0_ = gee_linked_list_new (TYPE_ID_CARD, (GBoxedCopyFunc) g_object_ref, g_object_unref, NULL), _g_object_unref0 (self->priv->id_card_list), _tmp0_);
#line 138 "moonshot-local-flat-file-store.vala"
	local_flat_file_store_load_id_cards (self);
#line 894 "moonshot-local-flat-file-store.c"
	return self;
}


#line 136 "moonshot-local-flat-file-store.vala"
LocalFlatFileStore* local_flat_file_store_new (void) {
#line 136 "moonshot-local-flat-file-store.vala"
	return local_flat_file_store_construct (TYPE_LOCAL_FLAT_FILE_STORE);
#line 903 "moonshot-local-flat-file-store.c"
}


static void local_flat_file_store_class_init (LocalFlatFileStoreClass * klass) {
	local_flat_file_store_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (LocalFlatFileStorePrivate));
	G_OBJECT_CLASS (klass)->finalize = local_flat_file_store_finalize;
}


static void local_flat_file_store_iidentity_card_store_interface_init (IIdentityCardStoreIface * iface) {
	local_flat_file_store_iidentity_card_store_parent_iface = g_type_interface_peek_parent (iface);
	iface->add_card = local_flat_file_store_real_add_card;
	iface->update_card = local_flat_file_store_real_update_card;
	iface->remove_card = local_flat_file_store_real_remove_card;
	iface->get_card_list = local_flat_file_store_real_get_card_list;
}


static void local_flat_file_store_instance_init (LocalFlatFileStore * self) {
	self->priv = LOCAL_FLAT_FILE_STORE_GET_PRIVATE (self);
}


static void local_flat_file_store_finalize (GObject* obj) {
	LocalFlatFileStore * self;
	self = LOCAL_FLAT_FILE_STORE (obj);
	_g_object_unref0 (self->priv->id_card_list);
	G_OBJECT_CLASS (local_flat_file_store_parent_class)->finalize (obj);
}


GType local_flat_file_store_get_type (void) {
	static volatile gsize local_flat_file_store_type_id__volatile = 0;
	if (g_once_init_enter (&local_flat_file_store_type_id__volatile)) {
		static const GTypeInfo g_define_type_info = { sizeof (LocalFlatFileStoreClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) local_flat_file_store_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (LocalFlatFileStore), 0, (GInstanceInitFunc) local_flat_file_store_instance_init, NULL };
		static const GInterfaceInfo iidentity_card_store_info = { (GInterfaceInitFunc) local_flat_file_store_iidentity_card_store_interface_init, (GInterfaceFinalizeFunc) NULL, NULL};
		GType local_flat_file_store_type_id;
		local_flat_file_store_type_id = g_type_register_static (G_TYPE_OBJECT, "LocalFlatFileStore", &g_define_type_info, 0);
		g_type_add_interface_static (local_flat_file_store_type_id, TYPE_IIDENTITY_CARD_STORE, &iidentity_card_store_info);
		g_once_init_leave (&local_flat_file_store_type_id__volatile, local_flat_file_store_type_id);
	}
	return local_flat_file_store_type_id__volatile;
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



