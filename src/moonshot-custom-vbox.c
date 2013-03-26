/* moonshot-custom-vbox.c generated by valac 0.16.1, the Vala compiler
 * generated from moonshot-custom-vbox.vala, do not modify */


#include <glib.h>
#include <glib-object.h>
#include <gtk/gtk.h>


#define TYPE_CUSTOM_VBOX (custom_vbox_get_type ())
#define CUSTOM_VBOX(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_CUSTOM_VBOX, CustomVBox))
#define CUSTOM_VBOX_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_CUSTOM_VBOX, CustomVBoxClass))
#define IS_CUSTOM_VBOX(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_CUSTOM_VBOX))
#define IS_CUSTOM_VBOX_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_CUSTOM_VBOX))
#define CUSTOM_VBOX_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_CUSTOM_VBOX, CustomVBoxClass))

typedef struct _CustomVBox CustomVBox;
typedef struct _CustomVBoxClass CustomVBoxClass;
typedef struct _CustomVBoxPrivate CustomVBoxPrivate;

#define TYPE_ID_CARD_WIDGET (id_card_widget_get_type ())
#define ID_CARD_WIDGET(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_ID_CARD_WIDGET, IdCardWidget))
#define ID_CARD_WIDGET_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_ID_CARD_WIDGET, IdCardWidgetClass))
#define IS_ID_CARD_WIDGET(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_ID_CARD_WIDGET))
#define IS_ID_CARD_WIDGET_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_ID_CARD_WIDGET))
#define ID_CARD_WIDGET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_ID_CARD_WIDGET, IdCardWidgetClass))

typedef struct _IdCardWidget IdCardWidget;
typedef struct _IdCardWidgetClass IdCardWidgetClass;

#define TYPE_IDENTITY_MANAGER_VIEW (identity_manager_view_get_type ())
#define IDENTITY_MANAGER_VIEW(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_IDENTITY_MANAGER_VIEW, IdentityManagerView))
#define IDENTITY_MANAGER_VIEW_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_IDENTITY_MANAGER_VIEW, IdentityManagerViewClass))
#define IS_IDENTITY_MANAGER_VIEW(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_IDENTITY_MANAGER_VIEW))
#define IS_IDENTITY_MANAGER_VIEW_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_IDENTITY_MANAGER_VIEW))
#define IDENTITY_MANAGER_VIEW_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_IDENTITY_MANAGER_VIEW, IdentityManagerViewClass))

typedef struct _IdentityManagerView IdentityManagerView;
typedef struct _IdentityManagerViewClass IdentityManagerViewClass;
#define _g_object_unref0(var) ((var == NULL) ? NULL : (var = (g_object_unref (var), NULL)))
typedef struct _IdentityManagerViewPrivate IdentityManagerViewPrivate;

#define TYPE_IDENTITY_MANAGER_APP (identity_manager_app_get_type ())
#define IDENTITY_MANAGER_APP(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_IDENTITY_MANAGER_APP, IdentityManagerApp))
#define IDENTITY_MANAGER_APP_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_IDENTITY_MANAGER_APP, IdentityManagerAppClass))
#define IS_IDENTITY_MANAGER_APP(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_IDENTITY_MANAGER_APP))
#define IS_IDENTITY_MANAGER_APP_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_IDENTITY_MANAGER_APP))
#define IDENTITY_MANAGER_APP_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_IDENTITY_MANAGER_APP, IdentityManagerAppClass))

typedef struct _IdentityManagerApp IdentityManagerApp;
typedef struct _IdentityManagerAppClass IdentityManagerAppClass;

#define TYPE_IDENTITY_MANAGER_MODEL (identity_manager_model_get_type ())
#define IDENTITY_MANAGER_MODEL(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_IDENTITY_MANAGER_MODEL, IdentityManagerModel))
#define IDENTITY_MANAGER_MODEL_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_IDENTITY_MANAGER_MODEL, IdentityManagerModelClass))
#define IS_IDENTITY_MANAGER_MODEL(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_IDENTITY_MANAGER_MODEL))
#define IS_IDENTITY_MANAGER_MODEL_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_IDENTITY_MANAGER_MODEL))
#define IDENTITY_MANAGER_MODEL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_IDENTITY_MANAGER_MODEL, IdentityManagerModelClass))

typedef struct _IdentityManagerModel IdentityManagerModel;
typedef struct _IdentityManagerModelClass IdentityManagerModelClass;

#define TYPE_IDENTITY_REQUEST (identity_request_get_type ())
#define IDENTITY_REQUEST(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), TYPE_IDENTITY_REQUEST, IdentityRequest))
#define IDENTITY_REQUEST_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), TYPE_IDENTITY_REQUEST, IdentityRequestClass))
#define IS_IDENTITY_REQUEST(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), TYPE_IDENTITY_REQUEST))
#define IS_IDENTITY_REQUEST_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), TYPE_IDENTITY_REQUEST))
#define IDENTITY_REQUEST_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), TYPE_IDENTITY_REQUEST, IdentityRequestClass))

typedef struct _IdentityRequest IdentityRequest;
typedef struct _IdentityRequestClass IdentityRequestClass;
#define _g_list_free0(var) ((var == NULL) ? NULL : (var = (g_list_free (var), NULL)))

struct _CustomVBox {
	GtkVBox parent_instance;
	CustomVBoxPrivate * priv;
};

struct _CustomVBoxClass {
	GtkVBoxClass parent_class;
};

struct _CustomVBoxPrivate {
	IdCardWidget* _current_idcard;
	IdentityManagerView* main_window;
};

struct _IdentityManagerView {
	GtkWindow parent_instance;
	IdentityManagerViewPrivate * priv;
	IdentityManagerApp* parent_app;
	IdentityManagerModel* identities_manager;
	GQueue* request_queue;
};

struct _IdentityManagerViewClass {
	GtkWindowClass parent_class;
};


static gpointer custom_vbox_parent_class = NULL;

GType custom_vbox_get_type (void) G_GNUC_CONST;
GType id_card_widget_get_type (void) G_GNUC_CONST;
GType identity_manager_view_get_type (void) G_GNUC_CONST;
#define CUSTOM_VBOX_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), TYPE_CUSTOM_VBOX, CustomVBoxPrivate))
enum  {
	CUSTOM_VBOX_DUMMY_PROPERTY,
	CUSTOM_VBOX_CURRENT_IDCARD
};
CustomVBox* custom_vbox_new (IdentityManagerView* window, gboolean homogeneous, gint spacing);
CustomVBox* custom_vbox_construct (GType object_type, IdentityManagerView* window, gboolean homogeneous, gint spacing);
void custom_vbox_receive_expanded_event (CustomVBox* self, IdCardWidget* id_card_widget);
void id_card_widget_collapse (IdCardWidget* self);
void custom_vbox_set_current_idcard (CustomVBox* self, IdCardWidget* value);
IdCardWidget* custom_vbox_get_current_idcard (CustomVBox* self);
gpointer identity_manager_app_ref (gpointer instance);
void identity_manager_app_unref (gpointer instance);
GParamSpec* param_spec_identity_manager_app (const gchar* name, const gchar* nick, const gchar* blurb, GType object_type, GParamFlags flags);
void value_set_identity_manager_app (GValue* value, gpointer v_object);
void value_take_identity_manager_app (GValue* value, gpointer v_object);
gpointer value_get_identity_manager_app (const GValue* value);
GType identity_manager_app_get_type (void) G_GNUC_CONST;
GType identity_manager_model_get_type (void) G_GNUC_CONST;
GType identity_request_get_type (void) G_GNUC_CONST;
GtkButton* id_card_widget_get_send_button (IdCardWidget* self);
void custom_vbox_add_id_card_widget (CustomVBox* self, IdCardWidget* id_card_widget);
void custom_vbox_remove_id_card_widget (CustomVBox* self, IdCardWidget* id_card_widget);
static void custom_vbox_finalize (GObject* obj);
static void _vala_custom_vbox_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec);
static void _vala_custom_vbox_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec);


static gpointer _g_object_ref0 (gpointer self) {
#line 10 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	return self ? g_object_ref (self) : NULL;
#line 138 "moonshot-custom-vbox.c"
}


CustomVBox* custom_vbox_construct (GType object_type, IdentityManagerView* window, gboolean homogeneous, gint spacing) {
	CustomVBox * self = NULL;
	IdentityManagerView* _tmp0_;
	IdentityManagerView* _tmp1_;
	gboolean _tmp2_;
	gint _tmp3_;
#line 8 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_val_if_fail (window != NULL, NULL);
#line 8 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	self = (CustomVBox*) g_object_new (object_type, NULL);
#line 10 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp0_ = window;
#line 10 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp1_ = _g_object_ref0 (_tmp0_);
#line 10 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_g_object_unref0 (self->priv->main_window);
#line 10 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	self->priv->main_window = _tmp1_;
#line 11 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp2_ = homogeneous;
#line 11 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	gtk_box_set_homogeneous ((GtkBox*) self, _tmp2_);
#line 12 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp3_ = spacing;
#line 12 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	gtk_box_set_spacing ((GtkBox*) self, _tmp3_);
#line 8 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	return self;
#line 170 "moonshot-custom-vbox.c"
}


CustomVBox* custom_vbox_new (IdentityManagerView* window, gboolean homogeneous, gint spacing) {
#line 8 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	return custom_vbox_construct (TYPE_CUSTOM_VBOX, window, homogeneous, spacing);
#line 177 "moonshot-custom-vbox.c"
}


void custom_vbox_receive_expanded_event (CustomVBox* self, IdCardWidget* id_card_widget) {
	GList* _tmp0_ = NULL;
	GList* list;
	GList* _tmp1_;
	IdCardWidget* _tmp6_;
	gboolean _tmp7_ = FALSE;
	IdCardWidget* _tmp8_;
	gboolean _tmp12_;
#line 15 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_if_fail (self != NULL);
#line 15 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_if_fail (id_card_widget != NULL);
#line 17 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp0_ = gtk_container_get_children ((GtkContainer*) self);
#line 17 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	list = _tmp0_;
#line 18 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp1_ = list;
#line 199 "moonshot-custom-vbox.c"
	{
		GList* id_card_collection = NULL;
		GList* id_card_it = NULL;
#line 18 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		id_card_collection = _tmp1_;
#line 18 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		for (id_card_it = id_card_collection; id_card_it != NULL; id_card_it = id_card_it->next) {
#line 207 "moonshot-custom-vbox.c"
			GtkWidget* _tmp2_;
			GtkWidget* id_card = NULL;
#line 18 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
			_tmp2_ = _g_object_ref0 ((GtkWidget*) id_card_it->data);
#line 18 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
			id_card = _tmp2_;
#line 214 "moonshot-custom-vbox.c"
			{
				GtkWidget* _tmp3_;
				IdCardWidget* _tmp4_;
#line 20 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
				_tmp3_ = id_card;
#line 20 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
				_tmp4_ = id_card_widget;
#line 20 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
				if (_tmp3_ != GTK_WIDGET (_tmp4_)) {
#line 224 "moonshot-custom-vbox.c"
					GtkWidget* _tmp5_;
#line 21 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
					_tmp5_ = id_card;
#line 21 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
					id_card_widget_collapse (ID_CARD_WIDGET (_tmp5_));
#line 230 "moonshot-custom-vbox.c"
				}
#line 18 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
				_g_object_unref0 (id_card);
#line 234 "moonshot-custom-vbox.c"
			}
		}
	}
#line 23 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp6_ = id_card_widget;
#line 23 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	custom_vbox_set_current_idcard (self, _tmp6_);
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp8_ = self->priv->_current_idcard;
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	if (_tmp8_ != NULL) {
#line 246 "moonshot-custom-vbox.c"
		IdentityManagerView* _tmp9_;
		GQueue* _tmp10_;
		guint _tmp11_;
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		_tmp9_ = self->priv->main_window;
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		_tmp10_ = _tmp9_->request_queue;
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		_tmp11_ = _tmp10_->length;
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		_tmp7_ = _tmp11_ > ((guint) 0);
#line 258 "moonshot-custom-vbox.c"
	} else {
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		_tmp7_ = FALSE;
#line 262 "moonshot-custom-vbox.c"
	}
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp12_ = _tmp7_;
#line 25 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	if (_tmp12_) {
#line 268 "moonshot-custom-vbox.c"
		IdCardWidget* _tmp13_;
		GtkButton* _tmp14_;
		GtkButton* _tmp15_;
#line 26 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		_tmp13_ = self->priv->_current_idcard;
#line 26 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		_tmp14_ = id_card_widget_get_send_button (_tmp13_);
#line 26 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		_tmp15_ = _tmp14_;
#line 26 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		gtk_widget_set_sensitive ((GtkWidget*) _tmp15_, TRUE);
#line 280 "moonshot-custom-vbox.c"
	}
#line 15 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_g_list_free0 (list);
#line 284 "moonshot-custom-vbox.c"
}


void custom_vbox_add_id_card_widget (CustomVBox* self, IdCardWidget* id_card_widget) {
	IdCardWidget* _tmp0_;
#line 29 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_if_fail (self != NULL);
#line 29 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_if_fail (id_card_widget != NULL);
#line 31 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp0_ = id_card_widget;
#line 31 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	gtk_box_pack_start ((GtkBox*) self, (GtkWidget*) _tmp0_, FALSE, FALSE, (guint) 0);
#line 298 "moonshot-custom-vbox.c"
}


void custom_vbox_remove_id_card_widget (CustomVBox* self, IdCardWidget* id_card_widget) {
	IdCardWidget* _tmp0_;
#line 34 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_if_fail (self != NULL);
#line 34 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_if_fail (id_card_widget != NULL);
#line 36 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp0_ = id_card_widget;
#line 36 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	gtk_container_remove ((GtkContainer*) self, (GtkWidget*) _tmp0_);
#line 312 "moonshot-custom-vbox.c"
}


IdCardWidget* custom_vbox_get_current_idcard (CustomVBox* self) {
	IdCardWidget* result;
	IdCardWidget* _tmp0_;
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_val_if_fail (self != NULL, NULL);
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp0_ = self->priv->_current_idcard;
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	result = _tmp0_;
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	return result;
#line 327 "moonshot-custom-vbox.c"
}


void custom_vbox_set_current_idcard (CustomVBox* self, IdCardWidget* value) {
	IdCardWidget* _tmp0_;
	IdCardWidget* _tmp1_;
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_return_if_fail (self != NULL);
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp0_ = value;
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_tmp1_ = _g_object_ref0 (_tmp0_);
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_g_object_unref0 (self->priv->_current_idcard);
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	self->priv->_current_idcard = _tmp1_;
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_object_notify ((GObject *) self, "current-idcard");
#line 346 "moonshot-custom-vbox.c"
}


static void custom_vbox_class_init (CustomVBoxClass * klass) {
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	custom_vbox_parent_class = g_type_class_peek_parent (klass);
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_type_class_add_private (klass, sizeof (CustomVBoxPrivate));
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	G_OBJECT_CLASS (klass)->get_property = _vala_custom_vbox_get_property;
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	G_OBJECT_CLASS (klass)->set_property = _vala_custom_vbox_set_property;
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	G_OBJECT_CLASS (klass)->finalize = custom_vbox_finalize;
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	g_object_class_install_property (G_OBJECT_CLASS (klass), CUSTOM_VBOX_CURRENT_IDCARD, g_param_spec_object ("current-idcard", "current-idcard", "current-idcard", TYPE_ID_CARD_WIDGET, G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));
#line 363 "moonshot-custom-vbox.c"
}


static void custom_vbox_instance_init (CustomVBox * self) {
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	self->priv = CUSTOM_VBOX_GET_PRIVATE (self);
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	self->priv->_current_idcard = NULL;
#line 372 "moonshot-custom-vbox.c"
}


static void custom_vbox_finalize (GObject* obj) {
	CustomVBox * self;
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	self = CUSTOM_VBOX (obj);
#line 5 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_g_object_unref0 (self->priv->_current_idcard);
#line 6 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	_g_object_unref0 (self->priv->main_window);
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	G_OBJECT_CLASS (custom_vbox_parent_class)->finalize (obj);
#line 386 "moonshot-custom-vbox.c"
}


GType custom_vbox_get_type (void) {
	static volatile gsize custom_vbox_type_id__volatile = 0;
	if (g_once_init_enter (&custom_vbox_type_id__volatile)) {
		static const GTypeInfo g_define_type_info = { sizeof (CustomVBoxClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) custom_vbox_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (CustomVBox), 0, (GInstanceInitFunc) custom_vbox_instance_init, NULL };
		GType custom_vbox_type_id;
		custom_vbox_type_id = g_type_register_static (GTK_TYPE_VBOX, "CustomVBox", &g_define_type_info, 0);
		g_once_init_leave (&custom_vbox_type_id__volatile, custom_vbox_type_id);
	}
	return custom_vbox_type_id__volatile;
}


static void _vala_custom_vbox_get_property (GObject * object, guint property_id, GValue * value, GParamSpec * pspec) {
	CustomVBox * self;
	self = CUSTOM_VBOX (object);
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	switch (property_id) {
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		case CUSTOM_VBOX_CURRENT_IDCARD:
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		g_value_set_object (value, custom_vbox_get_current_idcard (self));
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		break;
#line 413 "moonshot-custom-vbox.c"
		default:
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		break;
#line 419 "moonshot-custom-vbox.c"
	}
}


static void _vala_custom_vbox_set_property (GObject * object, guint property_id, const GValue * value, GParamSpec * pspec) {
	CustomVBox * self;
	self = CUSTOM_VBOX (object);
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
	switch (property_id) {
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		case CUSTOM_VBOX_CURRENT_IDCARD:
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		custom_vbox_set_current_idcard (self, g_value_get_object (value));
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		break;
#line 435 "moonshot-custom-vbox.c"
		default:
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
#line 3 "/build/slave/packages-full/build/ui/src/moonshot-custom-vbox.vala"
		break;
#line 441 "moonshot-custom-vbox.c"
	}
}



