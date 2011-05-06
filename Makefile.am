ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = po

bin_PROGRAMS = src/moonshot src/dbus-client


AM_CPPFLAGS = \
	-include config.h \
	-DLOCALEDIR=\""$(localedir)"\" \
	$(moonshot_CFLAGS)

AM_VALAFLAGS = \
	config.vapi \
	--pkg gtk+-2.0 --pkg dbus-glib-1

src_moonshot_SOURCES = \
        src/moonshot-id.vala \
        src/moonshot-add-dialog.vala \
        src/moonshot-idcard-widget.vala \
        src/moonshot-custom-vbox.vala \
	src/moonshot-identities-manager.vala \
        src/moonshot-dbus-server.vala \
        src/moonshot-window.vala

src_dbus_client_SOURCES = \
        src/dbus-client.vala

src_moonshot_LDADD = \
        $(moonshot_LIBS)

src_dbus_client_LDADD = \
        $(moonshot_LIBS)
