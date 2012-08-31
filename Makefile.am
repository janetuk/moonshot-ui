ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}
 
SUBDIRS = po


lib_LTLIBRARIES = libmoonshot/libmoonshot.la

bin_PROGRAMS = \
         src/moonshot \
         src/moonshot-webp

AM_CFLAGS = -g -O0

AM_CPPFLAGS = -g -O0 \
	-include config.h \
	-DLOCALEDIR=\""$(localedir)"\" \
	-I$(top_srcdir)/libmoonshot \
	-I$(top_builddir)/libmoonshot

AM_VALAFLAGS = -g \
        config.vapi \
	--vapidir=$(top_srcdir)/vapi \
        --pkg gio-2.0


libmoonshot_libmoonshot_la_CPPFLAGS = \
        $(libmoonshot_CFLAGS) \
        $(AM_CPPFLAGS) 

libmoonshot_libmoonshot_la_SOURCES = libmoonshot/libmoonshot-common.c

libmoonshot_libmoonshot_la_LIBADD = $(libmoonshot_LIBS)

include_HEADERS = libmoonshot/libmoonshot.h
noinst_HEADERS = libmoonshot/libmoonshot-common.h

src_moonshot_SOURCES = \
        src/moonshot-identity-manager-app.vala \
        src/moonshot-identity-management-view.vala \
        src/moonshot-local-flat-file-store.vala \
        src/moonshot-idcard-store.vala \
        src/moonshot-id.vala \
        src/moonshot-add-dialog.vala \
        src/moonshot-idcard-widget.vala \
        src/moonshot-custom-vbox.vala \
        src/moonshot-identities-manager.vala \
        src/moonshot-identity-request.vala \
        src/moonshot-server.vala \
        src/moonshot-password-dialog.vala \
        src/moonshot-provisioning-common.vala \
        src/moonshot-utils.vala

src_moonshot_webp_SOURCES = \
        src/moonshot-webp-parser.vala \
        src/moonshot-provisioning-common.vala \
        src/moonshot-id.vala

src_moonshot_VALAFLAGS = --pkg gdk-2.0 --pkg gtk+-2.0 --pkg gee-1.0 $(AM_VALAFLAGS)
src_moonshot_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)  
src_moonshot_LDADD = $(moonshot_LIBS) 
src_moonshot_LDFLAGS = -g -O0

src_moonshot_webp_VALAFLAGS = --vapidir=$(top_srcdir)/libmoonshot  --pkg gtk+-2.0 --pkg gdk-2.0 --pkg libmoonshot $(AM_VALAFLAGS)
src_moonshot_webp_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
src_moonshot_webp_LDADD = $(moonshot_LIBS) ${top_builddir}/libmoonshot/libmoonshot.la

if OS_WIN32

libmoonshot_libmoonshot_la_LDFLAGS = -no-undefined

src_moonshot_CFLAGS = -mwindows
src_moonshot_webp_CFLAGS = -mwindows
    
AM_CPPFLAGS += -DOS_WIN32
AM_VALAFLAGS += --define=OS_WIN32

noinst_DATA = libmoonshot/libmoonshot.lib

# Build the MSVC lib. The sed hack fixes execution in the case that
# the MSVC toolchain isn't in the PATH.
libmoonshot/libmoonshot.lib: libmoonshot/libmoonshot.def
	PATH="$(shell echo "${MSVC_LIB}" | sed -e s,/VC/bin/lib,/Common7/IDE,)":$$PATH "${MSVC_LIB}" -def:$< -out:$@ -machine:x86

endif

if  OS_MACOS

AM_CPPFLAGS += -DOS_MACOS $(MAC_CFLAGS)
AM_VALAFLAGS += --define=OS_MACOS --pkg gtk-mac-integration
moonshot_LIBS += $(MAC_LIBS)
src_moonshot_LDADD += $(MAC_LIBS)
endif

if OS_LINUX

## Installing mime type data
mimedir = $(datadir)/mime/packages
mime_DATA = webprovisioning/moonshot.xml

## Installing
dotdesktopdir = $(datadir)/applications
dotdesktop_DATA = moonshot.desktop moonshot-webp.desktop

endif

if IPC_MSRPC

AM_CPPFLAGS += -Isrc

AM_VALAFLAGS += \
	--pkg moonshot-msrpc.vapi --pkg msrpc-1.0 \
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


nodist_src_moonshot_SOURCES = \
        libmoonshot/moonshot-msrpc_s.c

nodist_libmoonshot_libmoonshot_la_SOURCES = \
        libmoonshot/moonshot-msrpc_c.c

endif

if IPC_DBUS

# DBus service file
dbusservicedir = $(datadir)/dbus-1/services
if  OS_MACOS
dbusservice_in_files = org.janet.Moonshot.service.mac
dbusservice_DATA = $(dbusservice_in_files:.service.mac=.service)
else
dbusservice_in_files = org.janet.Moonshot.service.in
dbusservice_DATA = $(dbusservice_in_files:.service.in=.service)
endif 

# Rule to make the service file with bindir expanded
$(dbusservice_DATA): $(dbusservice_in_files) Makefile
	@sed -e "s|\@bindir\@|$(bindir)|" $< > $@

libmoonshot_libmoonshot_la_SOURCES += libmoonshot/libmoonshot-dbus.c

CLEANFILES = $(dbusservice_DATA)

if IPC_DBUS_GLIB
AM_VALAFLAGS += \
	--pkg dbus-glib-1 \
	--define=IPC_DBUS_GLIB \
	--define=IPC_DBUS
else
AM_VALAFLAGS += \
	--pkg gio-2.0 \
	--define=IPC_GDBUS \
	--define=IPC_DBUS
endif
endif

EXTRA_DIST = webprovisioning/moonshot.xml $(dbusservice_in_files) \
	moonshot-ui.spec

noinst_PROGRAMS = \
        examples/client \
        examples/service-selection \
        tests/basic

examples_service_selection_SOURCES = examples/service-selection.c
examples_service_selection_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
examples_service_selection_LDADD = ${top_builddir}/libmoonshot/libmoonshot.la $(moonshot_LIBS)

examples_client_SOURCES = examples/client.c
examples_client_CPPFLAGS = $(libmoonshot_CFLAGS) $(AM_CPPFLAGS)
examples_client_LDADD = ${top_builddir}/libmoonshot/libmoonshot.la

tests_basic_SOURCES = tests/basic.c
tests_basic_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
tests_basic_LDADD = ${top_builddir}/libmoonshot/libmoonshot.la $(moonshot_LIBS)

##if OS_LINUX
##install-data-hook:
##	"${UPDATE_MIME_DATABASE}" $(datadir)/mime
##	"${UPDATE_DESKTOP_DATABASE}" $(datadir)/applications
##uninstall-hook:
##	"${UPDATE_MIME_DATABASE}" $(datadir)/mime
##	"${UPDATE_DESKTOP_DATABASE}" $(datadir)/applications
##endif

if OS_WIN32

## A couple of Windows-specific targets:

## 1. Icons. You must have gnome-icon-theme and gnome-icon-theme-symbolic installed
##    in the install prefix; and ImageMagick installed in c:/tools/ImageMagick. This
##    pulls in the icons required by moonshot and converts svg's to png's (we have
##    no svg support built in to Windows Gtk+ right now).

icons:
	mkdir -p share/icons
	cp ${prefix}/share/icons/gnome/48x48/status/avatar-default.png share/icons
	"${IMAGEMAGICK_CONVERT}" -background none ${prefix}/share/icons/gnome/scalable/actions/edit-clear-symbolic.svg -size 13x13 share/icons/edit-clear-symbolic.png
	"${IMAGEMAGICK_CONVERT}" -background none ${prefix}/share/icons/gnome/scalable/actions/edit-find-symbolic.svg -size 13x13 share/icons/edit-find-symbolic.png


## 2. Installer. You must have the Windows Installer XML toolkit version 3.5
##    installed in its default path. Note that this requires at least .NET
##    runtime with service packs 1 and 2. The installer picks up files from
##    the build prefix and mingw dir; you must change these if you have them
##    in different locations I'm afraid.

installer: moonshot.msi

moonshot.msi: windows/app.wxs windows/config.wxi $(bin_PROGRAMS)
	"${WIX_CANDLE}" $<
	"${WIX_LIGHT}" -b ${prefix} -b ${prefix}/mingw -o moonshot.msi app.wixobj

endif

if  OS_MACOS
## Mac-specific targets

## 1. Icons. 

icons:
	mkdir -p share/icons
	cp mac/icons/process-stop.png share/icons
	cp mac/icons/edit-find.png share/icons
	cp mac/icons/avatar-default.png share/icons

## 2. App bundle
## gtk-app-bundler must be installed
## moonshot-ui.app will be built in moonshot/mac-client-installer/moonshot-ui/
app-bundle:
	gtk-mac-bundler ./mac/moonshot-ui.bundle

## 3: Installer Package

installerdir = $(HOME)/moonshot/mac-client-installer

endif
