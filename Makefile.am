ACLOCAL_AMFLAGS = -I m4 ${ACLOCAL_FLAGS}

SUBDIRS = po macos-ui

moonshotsysconfdir=${sysconfdir}/moonshot

lib_LTLIBRARIES = libmoonshot/libmoonshot.la

if !OS_MACOS
bin_PROGRAMS = \
         src/moonshot \
         src/moonshot-webp \
         src/moonshot-keyring-tool \
         src/moonshot-idcard-generator
endif

dist_pkgdata_DATA = webprovisioning/default-identity.msht enable-moonshot-txt-ui-gnome-keyring
dist_doc_DATA = README.cli
dist_moonshotsysconf_DATA=flatstore-users

AM_CFLAGS = -g -O0 -Wall

AM_CPPFLAGS =  \
	-include config.h \
	-DLOCALEDIR=\""$(localedir)"\" \
    -DMOONSHOT_FLATSTORE_USERS='"$(moonshotsysconfdir)/flatstore-users"' \
    -DMOONSHOT_APP='"$(MOONSHOT_APP)"' \
	-I$(top_srcdir)/libmoonshot \
	-I$(top_builddir)/libmoonshot


if LOG4VALA
MOONSHOT_LOG_PKG= --pkg $(LOG4VALA_VERSION) -X -l$(LOG4VALA_VERSION) --define=USE_LOG4VALA
MOONSHOT_LOG_LIBS= -l$(LOG4VALA_VERSION)
else
MOONSHOT_LOG_PKG=
MOONSHOT_LOG_LIBS=
endif


AM_VALAFLAGS = -g \
        config.vapi \
        --vapidir=$(top_srcdir)/vapi \
        --pkg gio-2.0 \
        $(MOONSHOT_LOG_PKG)

libmoonshot_libmoonshot_la_CPPFLAGS = \
        $(libmoonshot_CFLAGS) \
        $(AM_CPPFLAGS)

libmoonshot_libmoonshot_la_SOURCES = libmoonshot/libmoonshot-common.c

libmoonshot_libmoonshot_la_LIBADD = $(libmoonshot_LIBS)
libmoonshot_libmoonshot_la_LDFLAGS = -no-undefined -version-info 1:1:0

include_HEADERS = libmoonshot/libmoonshot.h
noinst_HEADERS = libmoonshot/libmoonshot-common.h

src_moonshot_SOURCES = \
        src/moonshot-identity-manager-app.vala \
        src/moonshot-identity-management-view.vala \
        src/moonshot-identity-management-interface.vala \
        src/moonshot-identity-management-cli.vala \
        src/moonshot-local-flat-file-store.vala \
        src/moonshot-keyring-store-base.vala \
        src/moonshot-keyring-store-gnome.vala \
        src/moonshot-keyring-store-secret.vala \
        src/moonshot-idcard-store.vala \
        src/moonshot-id.vala \
        src/moonshot-identity-dialog.vala \
        src/moonshot-idcard-widget.vala \
        src/moonshot-custom-vbox.vala \
        src/moonshot-identities-manager.vala \
        src/moonshot-identity-request.vala \
        src/moonshot-server-linux.vala \
        src/moonshot-settings.vala \
        src/moonshot-password-dialog.vala \
        src/moonshot-service-dialog.vala \
        src/moonshot-provisioning-common.vala \
        src/moonshot-trust-anchor-dialog.vala \
        src/moonshot-utils.vala \
        src/moonshot-futils.c \
        src/moonshot-crypto-utils.c \
        src/moonshot-logger.vala \
        src/moonshot-warning-dialog.vala

src_moonshot_webp_SOURCES = \
        src/moonshot-crypto-utils.c \
        src/moonshot-webp-parser.vala \
        src/moonshot-provisioning-common.vala \
        src/moonshot-id.vala \
        src/moonshot-logger.vala

src_moonshot_keyring_tool_SOURCES = src/moonshot-keyring-tool.vala

src_moonshot_idcard_generator_SOURCES = src/moonshot-idcard-generator.c


src_moonshot_VALAFLAGS = --pkg $(GTK_VERSION) --pkg $(GEE_VERSION) --pkg libnewt --pkg posix --pkg libxml-2.0 $(AM_VALAFLAGS)
src_moonshot_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
src_moonshot_LDADD = $(moonshot_LIBS)
src_moonshot_LDFLAGS = -g -O0 $(MOONSHOT_LOG_LIBS)

src_moonshot_webp_VALAFLAGS = --vapidir=$(top_srcdir)/libmoonshot  --pkg $(GEE_VERSION) --pkg libxml-2.0 --pkg libmoonshot $(AM_VALAFLAGS)
src_moonshot_webp_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
src_moonshot_webp_LDADD = $(moonshot_LIBS) ${top_builddir}/libmoonshot/libmoonshot.la
src_moonshot_webp_LDFLAGS = $(MOONSHOT_LOG_LIBS)

src_moonshot_keyring_tool_VALAFLAGS = --pkg $(GEE_VERSION) --pkg posix $(AM_VALAFLAGS)
src_moonshot_keyring_tool_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
src_moonshot_keyring_tool_LDADD = $(moonshot_LIBS) ${top_builddir}/libmoonshot/libmoonshot.la
src_moonshot_keyring_tool_LDFLAGS = $(MOONSHOT_LOG_LIBS)

src_moonshot_idcard_generator_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
src_moonshot_idcard_generator_LDADD = $(moonshot_LIBS) ${top_builddir}/libmoonshot/libmoonshot.la
src_moonshot_idcard_generator_LDFLAGS = $(MOONSHOT_LOG_LIBS)

if OS_WIN32

src_moonshot_CFLAGS = -mwindows
src_moonshot_webp_CFLAGS = -mconsole

AM_CPPFLAGS += -DOS_WIN32
AM_VALAFLAGS += --define=OS_WIN32

noinst_DATA = libmoonshot/libmoonshot.lib

# Build the MSVC lib. The sed hack fixes execution in the case that
# the MSVC toolchain isn't in the PATH.
libmoonshot/libmoonshot.lib: libmoonshot/libmoonshot.def
	PATH="$(shell echo "${MSVC_LIB}" | sed -e s,/VC/bin/lib,/Common7/IDE,)":$$PATH "${MSVC_LIB}" -def:$< -out:$@ -machine:x86

endif

if OS_MACOS

AM_CPPFLAGS = 
AM_VALAFLAGS = 
moonshot_LIBS = 
src_moonshot_LDADD = 
endif

if OS_LINUX

AM_CPPFLAGS += $(KEYRING_CFLAGS) $(LIB_XML2_CFLAGS)
AM_VALAFLAGS += $(KEYRING_VALAFLAGS)
src_moonshot_LDADD += $(KEYRING_LIBS) -lcrypto $(LIB_NEWT_LIBS) $(LIB_XML2_LIBS) -lkeyutils
src_moonshot_keyring_tool_LDFLAGS += $(KEYRING_LIBS)
src_moonshot_webp_LDFLAGS += $(KEYRING_LIBS) -lcrypto $(LIB_NEWT_LIBS) $(LIB_XML2_LIBS) -lkeyutils
src_moonshot_idcard_generator_LDFLAGS += -lcrypto

## Installing mime type data
mimedir = $(datadir)/mime/packages
mime_DATA = webprovisioning/moonshot.xml

## Installing
dotdesktopdir = $(datadir)/applications
dotdesktop_DATA = moonshot.desktop moonshot-webp.desktop

#the application icon
appicondir=$(datadir)/icons/hicolor/scalable/apps
appicon_DATA=moonshot.svg

endif

if IPC_MSRPC

AM_CPPFLAGS += -Isrc

AM_VALAFLAGS += \
	--pkg moonshot-msrpc --pkg msrpc-1.0 \
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

# Script to expand makefile variables.
# Note: @bindir[@] is does what \@bindir\@ appears to do, but \@ is
# not POSIX-compliant
in_substitute = sed \
	-e 's|@bindir[@]|$(bindir)|g' \
	-e 's|@pkgdatadir[@]|$(pkgdatadir)|g'

# DBus service def file. This will be symlinked into ${datadir}/dbus-1/services by
# the packaging scripts.
if  OS_MACOS
dbus_service_in_file = org.janet.Moonshot.service.mac
dbus_service_file = $(dbus_service_in_file:.service.mac=.service)
else
dbus_service_in_file = org.janet.Moonshot.service.in
dbus_service_file = $(dbus_service_in_file:.service.in=.service)
endif
libmoonshot_libmoonshot_la_SOURCES += libmoonshot/libmoonshot-dbus.c

# DBus bus configuration file, used for launching our own bus when the session bus
# is not available.
dbus_bus_in_file = org.janet.Moonshot.conf.in
dbus_bus_file = $(dbus_bus_in_file:.conf.in=.conf)

# Rules to expand .in files into service/conf files
$(dbus_service_file): $(dbus_service_in_file) Makefile
	@$(in_substitute) $< > $@
$(dbus_bus_file): $(dbus_bus_in_file) Makefile
	@$(in_substitute) $< > $@

dbuscfgdir = $(pkgdatadir)/dbus
dist_dbuscfg_DATA = $(dbus_service_file) $(dbus_bus_file)
AM_CPPFLAGS += -DMOONSHOT_DBUS_BUS_CONF='"$(pkgdatadir)/dbus/org.janet.Moonshot.conf"' \
               -DMOONSHOT_DBUS_DAEMON='"@DBUS_DAEMON@"'

CLEANFILES = $(dist_dbuscfg_DATA)  src_moonshot_vala.stamp src_moonshot_vala.stamp-t

AM_VALAFLAGS += \
	--pkg gio-2.0 \
	--define=IPC_GDBUS \
	--define=IPC_DBUS
endif

if GIO_VAPI_USES_ARRAYS
AM_VALAFLAGS += --define=GIO_VAPI_USES_ARRAYS
endif

EXTRA_DIST = webprovisioning/moonshot.xml $(dbus_service_in_file) \
    $(dbus_bus_in_file) \
	webprovisioning/complex-test.msht webprovisioning/sample.msht \
	README.webprovisioning README.windows \
	moonshot-ui.spec moonshot.svg \
	vapi/moonshot-gnome-keyring.vapi libmoonshot/libmoonshot.vapi

noinst_PROGRAMS = \
        examples/client \
        examples/service-selection \
        examples/confirm-ca \
        tests/basic

examples_service_selection_SOURCES = examples/service-selection.c
examples_service_selection_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
examples_service_selection_LDADD = ${top_builddir}/libmoonshot/libmoonshot.la $(moonshot_LIBS)

examples_client_SOURCES = examples/client.c
examples_client_CPPFLAGS = $(libmoonshot_CFLAGS) $(AM_CPPFLAGS)
examples_client_LDADD = $(libmoonshot_LIBS) ${top_builddir}/libmoonshot/libmoonshot.la

examples_confirm_ca_SOURCES = examples/confirm-ca.c
examples_confirm_ca_CPPFLAGS = $(moonshot_CFLAGS) $(AM_CPPFLAGS)
examples_confirm_ca_LDADD = ${top_builddir}/libmoonshot/libmoonshot.la $(moonshot_LIBS)

tests_basic_SOURCES = tests/basic.c
tests_basic_CPPFLAGS = $(libmoonshot_CFLAGS) $(AM_CPPFLAGS)
tests_basic_LDADD = ${top_builddir}/libmoonshot/libmoonshot.la $(libmoonshot_LIBS)

## Automated tests
TESTS = tests/basic.bash
dist_check_SCRIPTS = tests/basic.bash

##if OS_LINUX
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
#icons:
#	mkdir -p share/icons
#	cp mac/icons/process-stop.png share/icons
#	cp mac/icons/edit-find.png share/icons
#	cp mac/icons/avatar-default.png share/icons

## 2. App bundle
## xcodebuild must be installed
## Moonshot.app will be built in moonshot/macos-ui/build/Release
app-bundle:
#if WITH_APPLE_DEVELOPER_ID_APPLICATION
#	cd macos-ui/Moonshot.xcodeproj; \
#	sed -i '' 's/ = APPLE_DEVELOPER_TEAM;/ = $(APPLE_DEVELOPER_TEAM_ID);/g' project.pbxproj;
#else
	cd macos-ui/Moonshot.xcodeproj; \
	sed -i '' 's/ = APPLE_DEVELOPER_TEAM;/ = \"\";/g' project.pbxproj; \
	sed -i '' 's/CODE_SIGN_IDENTITY = "Developer ID Application";/CODE_SIGN_IDENTITY = "";/g' project.pbxproj
#endif
	cd macos-ui && $(XCODEBUILD)

uninstaller-bundle:
if WITH_APPLE_DEVELOPER_ID_APPLICATION
	cd "macos-ui/Uninstaller/Uninstall Moonshot.xcodeproj"; \
	sed -i '' 's/ = APPLE_DEVELOPER_TEAM;/ = $(APPLE_DEVELOPER_TEAM_ID);/g' project.pbxproj;
else
	cd "macos-ui/Uninstaller/Uninstall Moonshot.xcodeproj"; \
	sed -i '' 's/ = APPLE_DEVELOPER_TEAM;/ = \"\";/g' project.pbxproj; \
	sed -i '' 's/CODE_SIGN_IDENTITY = "Developer ID Application";/CODE_SIGN_IDENTITY = "";/g' project.pbxproj
endif
	cd macos-ui/Uninstaller && $(XCODEBUILD)

endif
