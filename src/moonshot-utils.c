/* moonshot-utils.c generated by valac 0.10.4, the Vala compiler
 * generated from moonshot-utils.vala, do not modify */


#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <string.h>
#include <gtk/gtk.h>
#include <gdk-pixbuf/gdk-pixdata.h>
#include <stdio.h>

#define _g_object_unref0(var) ((var == NULL) ? NULL : (var = (g_object_unref (var), NULL)))
#define _g_error_free0(var) ((var == NULL) ? NULL : (var = (g_error_free (var), NULL)))



GdkPixbuf* find_icon_sized (const char* name, GtkIconSize icon_size);
GdkPixbuf* find_icon (const char* name, gint size);



GdkPixbuf* find_icon_sized (const char* name, GtkIconSize icon_size) {
	GdkPixbuf* result = NULL;
	gint width = 0;
	gint height = 0;
	g_return_val_if_fail (name != NULL, NULL);
	gtk_icon_size_lookup (icon_size, &width, &height);
	result = find_icon (name, width);
	return result;
}


static gpointer _g_object_ref0 (gpointer self) {
	return self ? g_object_ref (self) : NULL;
}


GdkPixbuf* find_icon (const char* name, gint size) {
	GdkPixbuf* result = NULL;
	GError * _inner_error_ = NULL;
	g_return_val_if_fail (name != NULL, NULL);
	{
		GtkIconTheme* icon_theme;
		GdkPixbuf* _tmp0_;
		icon_theme = _g_object_ref0 (gtk_icon_theme_get_default ());
		_tmp0_ = gtk_icon_theme_load_icon (icon_theme, name, size, GTK_ICON_LOOKUP_FORCE_SIZE, &_inner_error_);
		if (_inner_error_ != NULL) {
			_g_object_unref0 (icon_theme);
			goto __catch7_g_error;
		}
		result = _tmp0_;
		_g_object_unref0 (icon_theme);
		return result;
	}
	goto __finally7;
	__catch7_g_error:
	{
		GError * e;
		e = _inner_error_;
		_inner_error_ = NULL;
		{
			fprintf (stdout, "Error loading icon '%s': %s\n", name, e->message);
			result = NULL;
			_g_error_free0 (e);
			return result;
		}
	}
	__finally7:
	{
		g_critical ("file %s: line %d: uncaught error: %s (%s, %d)", __FILE__, __LINE__, _inner_error_->message, g_quark_to_string (_inner_error_->domain), _inner_error_->code);
		g_clear_error (&_inner_error_);
		return NULL;
	}
}




