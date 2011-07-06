ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = po


lib_LTLIBRARIES = libmoonshot/libmoonshot.la

bin_PROGRAMS = src/moonshot



AM_CFLAGS =

AM_CPPFLAGS = \
	-include config.h \
	-DLOCALEDIR=\""$(localedir)"\" \
	-I$(top_srcdir)/libmoonshot

AM_VALAFLAGS = \
	config.vapi \
	--pkg gtk+-2.0


libmoonshot_libmoonshot_la_CPPFLAGS = \
        $(libmoonshot_CFLAGS) \
        $(AM_CPPFLAGS)

libmoonshot_libmoonshot_la_SOURCES = libmoonshot/libmoonshot-common.c

libmoonshot_libmoonshot_la_LIBADD = $(libmoonshot_LIBS)

include_HEADERS = libmoonshot/libmoonshot.h
noinst_HEADERS = libmoonshot/libmoonshot-common.h

src_moonshot_SOURCES = \
        src/moonshot-id.vala \
        src/moonshot-add-dialog.vala \
        src/moonshot-idcard-widget.vala \
        src/moonshot-custom-vbox.vala \
        src/moonshot-identities-manager.vala \
        src/moonshot-identity-request.vala \
        src/moonshot-server.vala \
        src/moonshot-window.vala \
        src/moonshot-password-dialog.vala \
        src/moonshot-utils.vala

src_moonshot_LDADD = \
        $(moonshot_LIBS)

src_moonshot_CPPFLAGS = \
        $(moonshot_CFLAGS) \
        $(AM_CPPFLAGS)

if OS_WIN32

libmoonshot_libmoonshot_la_LDFLAGS = -no-undefined

src_moonshot_CFLAGS = -mwindows

AM_CPPFLAGS += -DOS_WIN32
AM_VALAFLAGS += --define=OS_WIN32

endif


if IPC_MSRPC

AM_CPPFLAGS += -Isrc

AM_VALAFLAGS += \
	--pkg msrpc-1.0 \
	--define=IPC_MSRPC

BUILT_SOURCES = libmoonshot/moonshot-msrpc.h \
                libmoonshot/moonshot-msrpc_s.c \
                libmoonshot/moonshot-msrpc_c.c

DISTCLEANFILES = ${BUILT_SOURCES}

libmoonshot/moonshot-msrpc.h: libmoonshot/moonshot-msrpc.idl libmoonshot/moonshot-msrpc.acf
	${AM_V_GEN} ${MIDL_WRAPPER} -o libmoonshot -m "${MIDL}" $^

libmoonshot/moonshot-msrpc_s.c: libmoonshot/moonshot-msrpc.h
libmoonshot/moonshot-msrpc_c.c: libmoonshot/moonshot-msrpc.h

libmoonshot_libmoonshot_la_SOURCES += \
        libmoonshot/libmoonshot-msrpc.c

src_moonshot_SOURCES += \
        src/moonshot-msrpc.vapi

nodist_src_moonshot_SOURCES = \
        libmoonshot/moonshot-msrpc_s.c

nodist_libmoonshot_libmoonshot_la_SOURCES = \
        libmoonshot/moonshot-msrpc_c.c

endif

if IPC_DBUS

# DBus service file
dbusservicedir = $(datadir)/dbus-1/services
dbusservice_in_files = org.janet.Moonshot.service.in
dbusservice_DATA = $(dbusservice_in_files:.service.in=.service)

# Rule to make the service file with bindir expanded
$(dbusservice_DATA): $(dbusservice_in_files) Makefile
	@sed -e "s|\@bindir\@|$(bindir)|" $< > $@

AM_VALAFLAGS += \
	--pkg dbus-glib-1 \
	--define=IPC_DBUS

libmoonshot_libmoonshot_la_SOURCES += libmoonshot/libmoonshot-dbus.c

CLEANFILES = $(dbusservice_DATA)
EXTRA_DIST = $(dbusservice_in_files)

endif


bin_PROGRAMS += src/moonshot-webp

src_moonshot_webp_SOURCES = src/moonshot-webp-parser.vala src/moonshot-id.vala
src_moonshot_webp_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
src_moonshot_webp_LDADD = $(moonshot_LIBS)

if OS_WIN32
moonshot_webp_CFLAGS = -mwindows
endif


noinst_PROGRAMS = \
        examples/client \
        tests/basic

examples_client_SOURCES = examples/client.c
examples_client_CPPFLAGS = $(libmoonshot_CFLAGS) $(AM_CPPFLAGS)
examples_client_LDADD = ${top_builddir}/libmoonshot/libmoonshot.la

tests_basic_SOURCES = tests/basic.c
tests_basic_CPPFLAGS = $(libmoonshot_CFLAGS) $(AM_CPPFLAGS)
tests_basic_LDADD = ${top_builddir}/libmoonshot/libmoonshot.la $(moonshot_LIBS)


if OS_WIN32

## A couple of Windows-specific targets:

## 1. Icons. You must have gnome-icon-theme and gnome-icon-theme-symbolic installed
##    in c:/build prefix; and ImageMagick installed in c:/tools/ImageMagick. This
##    pulls in the icons required by moonshot and converts svg's to png's (we have
##    no svg support built in to Windows Gtk+ right now).

icons:
	mkdir -p share/icons
	cp c:/build/share/icons/gnome/48x48/status/avatar-default.png share/icons
	"${IMAGEMAGICK_CONVERT}" -background none c:/build/share/icons/gnome/scalable/actions/edit-clear-symbolic.svg -size 13x13 share/icons/edit-clear-symbolic.png
	"${IMAGEMAGICK_CONVERT}" -background none c:/build/share/icons/gnome/scalable/actions/edit-find-symbolic.svg -size 13x13 share/icons/edit-find-symbolic.png


## 2. Installer. You must have the Windows Installer XML toolkit version 3.5
##    installed in its default path. Note that this requires at least .NET
##    runtime with service packs 1 and 2. The installer picks up files from
##    the build prefix and mingw dir; you must change these if you have them
##    in different locations I'm afraid.

installer: moonshot.msi

moonshot.msi: windows/app.wxs
	"${WIX_CANDLE}" $<
	"${WIX_LIGHT}" -b c:/build -b c:/tools/mingw -o moonshot.msi app.wixobj

endif
