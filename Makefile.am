ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = po

bin_PROGRAMS = src/moonshot

AM_CFLAGS =

AM_CPPFLAGS = \
	-include config.h \
	-DLOCALEDIR=\""$(localedir)"\" \
	$(moonshot_CFLAGS)

AM_VALAFLAGS = \
	config.vapi \
	--pkg gtk+-2.0

src_moonshot_SOURCES = \
        src/moonshot-id.vala \
        src/moonshot-add-dialog.vala \
        src/moonshot-idcard-widget.vala \
        src/moonshot-custom-vbox.vala \
        src/moonshot-identities-manager.vala \
        src/moonshot-window.vala \
        src/moonshot-utils.vala

src_moonshot_LDADD = \
        $(moonshot_LIBS)

if OS_WIN32
AM_CFLAGS += -mwindows
AM_VALAFLAGS += --define=OS_WIN32
endif

if IPC_MSRPC

AM_CPPFLAGS += -Isrc

AM_VALAFLAGS += \
	--pkg msrpc-1.0 \
	--define=IPC_MSRPC

noinst_HEADERS = src/moonshot-msrpc.h

src_moonshot_SOURCES += \
        src/moonshot-msrpc-server.vala \
        src/moonshot-msrpc_s.c \
        src/moonshot-msrpc-vala.c \
        src/moonshot-msrpc.vapi

bin_PROGRAMS += src/msrpc-client

src_msrpc_client_SOURCES = \
        src/msrpc-client.vala \
        src/moonshot-msrpc_c.c \
        src/moonshot-msrpc-vala.c \
        src/moonshot-msrpc.vapi

src_msrpc_client_LDADD = \
        $(moonshot_LIBS)

BUILT_SOURCES = src/moonshot-msrpc.h src/moonshot-msrpc_s.c src/moonshot-msrpc_c.c

DISTCLEANFILES = ${BUILT_SOURCES}

src/moonshot-msrpc.h: src/moonshot-msrpc.idl src/moonshot-msrpc.acf
	${AM_V_GEN} ${MIDL_WRAPPER} -o src -m "${MIDL}" $^

src/moonshot-msrpc_s.c: src/moonshot-msrpc.h

else

# IPC_DBUS

AM_VALAFLAGS += \
	--pkg dbus-glib-1
	--define=IPC_DBUS

src_moonshot_SOURCES += src/moonshot-dbus-server.vala

bin_PROGRAMS += src/dbus-client

src_dbus_client_SOURCES = \
        src/dbus-client.vala

src_dbus_client_LDADD = \
        $(moonshot_LIBS)

endif


if OS_WIN32

## A couple of Windows-specific targets:

## 1. Icons. You must have gnome-icon-theme and gnome-icon-theme-symbolic installed
##    in c:/build prefix; and ImageMagick installed in c:/tools/ImageMagick. This
##    pulls in the icons required by moonshot and converts svg's to png's (we have
##    no svg support built in to Windows Gtk+ right now).

icons:
	mkdir -p share/icons
	cp c:/build/share/icons/gnome/48x48/status/avatar-default.png share/icons
	c:/tools/ImageMagick/convert.exe -background none c:/build/share/icons/gnome/scalable/actions/edit-clear-symbolic.svg -size 13x13 share/icons/edit-clear-symbolic.png
	c:/tools/ImageMagick/convert.exe -background none c:/build/share/icons/gnome/scalable/actions/edit-find-symbolic.svg -size 13x13 share/icons/edit-find-symbolic.png


## 2. Installer. You must have the Windows Installer XML toolkit version 3.5
##    installed in its default path. Note that this requires at least .NET
##    runtime with service packs 1 and 2.

installer: moonshot.msi

moonshot.msi: windows/app.wxs
	candle $<
	light -b c:/build -b c:/tools/mingw -o moonshot.msi app.wixobj

endif
