AC_PREREQ([2.63])
AC_INIT([Moonshot-ui],
        [1.0.0],
        [moonshot-community@jiscmail.ac.uk],
        [moonshot-ui],
        [http://www.project-moonshot.org/])

# Remove this when we can depend on autoconf >= 2.64
AC_SUBST(PACKAGE_URL, [http://www.project-moonshot.org/])
AC_DEFINE(PACKAGE_URL,["http://www.project-moonshot.org"],[package URL])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([configure.ac])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([1.11 -Wall foreign subdir-objects tar-pax no-dist-gzip dist-xz])
AM_SILENT_RULES([yes])
AM_MAINTAINER_MODE([enable])

LT_PREREQ([2.2])
LT_INIT([win32-dll])
AC_CHECK_FUNCS_ONCE(geteuid getpwuid)

# Checks for programs.
PKG_PROG_PKG_CONFIG([0.23])
AC_PROG_CC
AM_PROG_CC_C_O
AM_PROG_VALAC([0.9])

# Platform checks
AC_CANONICAL_HOST

case "$host" in
  *-*-mingw*)
    win32=yes
    macos=no
    linux=no
    SERVER_IPC_MODULE="msrpc-glib2-1.0"
    CLIENT_IPC_MODULE="msrpc-mingw-1.0"
    ;;
    
  *darwin*) 
    win32=no
    macos=yes
    linux=no

    # We require dbus-glib for the client library even if we are using GDBus
    # in the server. The reason we can't always use dbus-glib in the server is
    # because Vala drops support for it, but as it ships with DBus there is very
    # little danger of it being dropped by distros any time soon.
    CLIENT_IPC_MODULE="dbus-glib-1"
	SERVER_IPC_MODULE="dbus-glib-1"   
	
	PKG_CHECK_MODULES([MAC], 
			[gtk-mac-integration >= 1.0.1]
	)

    ;;
  *)
    macos=no
    win32=no
    linux=yes

    # We require dbus-glib for the client library even if we are using GDBus
    # in the server. The reason we can't always use dbus-glib in the server is
    # because Vala drops support for it, but as it ships with DBus there is very
    # little danger of it being dropped by distros any time soon.
    CLIENT_IPC_MODULE="dbus-glib-1"
    PKG_CHECK_MODULES([GDBUS],
            [gio-2.0 >= 2.26],
            [SERVER_IPC_MODULE="gio-2.0"],
            [SERVER_IPC_MODULE="dbus-glib-1"]
    )

    ;;
esac


# For all platforms: Use Gtk+3.0 if available; else revert to Gtk+2.0
PKG_CHECK_MODULES([GTK],
        [gtk+-3.0 >= 3.1],
        [GTK_VERSION="gtk+-3.0"],
            [PKG_CHECK_MODULES([GTK],
                        [gtk+-2.0 >= 2.18],
                        [GTK_VERSION="gtk+-2.0"]
            )]                            
)
AC_SUBST(GTK_VERSION)


# For all platforms: Use gee-0.8 if available; else revert to gee-1.0
# (yes, gee-0.8 is an upgrade from gee-1.0!)
PKG_CHECK_MODULES([LIB_GEE],
        [gee-0.8 >= 0.16],
        [GEE_VERSION="gee-0.8"],
            [PKG_CHECK_MODULES([LIB_GEE],
                        [gee-1.0 >= 0.5],
                        [GEE_VERSION="gee-1.0"]
            )]                            
)
AC_SUBST(GEE_VERSION)

#enable the optional use of Log4Vala (Must have the package installed!)
AC_ARG_ENABLE([log4vala],
[  --enable-log4vala    Enable use of log4vala for logging],
[case "${enableval}" in
  yes) log4vala=true ;;
  no)  log4vala=false ;;
  *) AC_MSG_ERROR([bad value ${enableval} for --enable-log4vala]) ;;
esac],[log4vala=false])
AM_CONDITIONAL([LOG4VALA], [test x$log4vala = xtrue])


AM_CONDITIONAL([OS_LINUX], [test "$linux" = "yes"])
AM_CONDITIONAL([OS_WIN32], [test "$win32" = "yes"])
AM_CONDITIONAL([OS_MACOS], [test "$macos" = "yes"])

AM_CONDITIONAL([IPC_MSRPC], [test "$SERVER_IPC_MODULE" = "msrpc-glib2-1.0"])
AM_CONDITIONAL([IPC_DBUS], [test "$SERVER_IPC_MODULE" != "msrpc-glib2-1.0"])
AM_CONDITIONAL([IPC_DBUS_GLIB], [test "$SERVER_IPC_MODULE" = "dbus-glib-1"])
AM_CONDITIONAL([IPC_GDBUS], [test "$SERVER_IPC_MODULE" = "gio-2.0"])

vala_version=`$VALAC --version | sed 's/Vala  *//'`
AS_VERSION_COMPARE(["$vala_version"], [0.11.1],
  [gio_vapi_uses_arrays="no"],
  [gio_vapi_uses_arrays="yes"],
  [gio_vapi_uses_arrays="yes"])
AM_CONDITIONAL([GIO_VAPI_USES_ARRAYS], [test "$gio_vapi_uses_arrays" = "yes"])
if test "$SERVER_IPC_MODULE" = "dbus-glib-1"; then
  AC_MSG_CHECKING([$VALAC is no greater than 0.12.1])
  AS_VERSION_COMPARE([0.12.2], ["$vala_version"],
    [vala_supports_dbus_glib="no"],
    [vala_supports_dbus_glib="no"],
    [vala_supports_dbus_glib="yes"])

  AC_MSG_RESULT([$vala_supports_dbus_glib])
  if test "$vala_supports_dbus_glib" = "no"; then
    AC_MSG_ERROR([
*** Vala 0.12.1 or earlier is required for dbus-glib support. Newer versions
*** require that you have GLib 2.26 or newer (for GDBus support).])
  fi
fi

if test "$SERVER_IPC_MODULE" = "msrpc-glib2-1.0"; then
  # MS RPC utilities
  AC_PATH_MSRPC_MINGW([0.1.0], :,
    AC_MSG_ERROR([
*** msrpc-mingw 0.1.0 or better is required.]))

  AC_PATH_PROG([MIDL], [midl], no,
               [/c/Program\ Files/Microsoft\ SDKs/Windows/v7.0/Bin$PATH_SEPARATOR$PATH])
  if test "$MIDL" = "no"; then
     AC_MSG_ERROR([
*** Could not find the Microsoft interface compiler MIDL.EXE.
*** This program is available as part of the MS Windows SDK, in
*** the Win32 Development Tools package. If it is not in the PATH
*** or its default location you may set the 'MIDL' environment
*** variable to point to its location and rerun configure.])
  fi
fi

if test "$win32" = "yes"; then
  # Other Windows-specific tools

  # LIB.EXE from MSVC to build an MSVC-compatible import library.
  AC_PATH_PROG([MSVC_LIB], [lib], no,
               [/c/Program\ Files/Microsoft\ Visual\ Studio\ 9.0/VC/bin$PATH_SEPARATOR/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio\ 9.0/VC/bin$PATH_SEPARATOR$PATH])

  if test "$MSVC_LIB" = "no"; then
     AC_MSG_WARN([
*** Could not find the Microsoft 'LIB.EXE' program. This is required
*** to build the Visual C import library for libmoonshot. Use the
*** MSVC_LIB environment variable to pass its location if this is
*** outside the PATH.])
  fi


  # ImageMagick for the 'make icons' target. Note that
  # c:/windows/system32/convert.exe is nothing to do with ImageMagick.
  AC_PATH_PROG([IMAGEMAGICK_CONVERT], [convert], no,
               [/c/Program\ Files/ImageMagick$PATH_SEPARATOR/c/Program\ Files\ \(x86\)/ImageMagick$PATH_SEPARATOR$PATH])

  if test "$IMAGEMAGICK_CONVERT" = "no" || test "$IMAGEMAGICK_CONVERT" = "/c/windows/system32/convert"; then
     AC_MSG_WARN([
*** Could not find ImageMagick convert.exe. This is required for the
*** 'make icons' target. Use the IMAGEMAGICK_CONVERT environment
*** variable to pass its location if this is outside the PATH.])
  fi


  # Windows Installer XML tools
  AC_PATH_PROG([WIX_CANDLE], [candle], no,
               [/c/Program\ Files/Windows\ Installer\ XML\ v3.5/bin$PATH_SEPARATOR/c/Program\ Files\ \(x86\)/Windows\ Installer\ XML\ v3.5/bin$PATH_SEPARATOR$PATH])
  AC_PATH_PROG([WIX_LIGHT], [light], no,
               [/c/Program\ Files/Windows\ Installer\ XML\ v3.5/bin$PATH_SEPARATOR/c/Program\ Files\ \(x86\)/Windows\ Installer\ XML\ v3.5/bin$PATH_SEPARATOR$PATH])

  if test "$WIX_CANDLE" = "no" || test "$WIX_LIGHT" = "no"; then
     AC_MSG_WARN([
*** Could not find the Windows Installer XML tools. These are required
*** for the 'make installer' target. Use the WIX_CANDLE and WIX_LIGHT
*** environment variables to pass their locations if they are outside
*** the PATH.])
  fi
fi

if test "$linux" = "yes"; then
  AC_PATH_PROG([UPDATE_MIME_DATABASE], [update-mime-database], [no])
  if test "$UPDATE_MIME_DATABASE" = "no"; then
    AC_MSG_ERROR([
*** Could not find the Freedesktop.org  mime database update tool.
*** Web provisioning files could not be automatically installed.])
  fi
  AC_PATH_PROG([UPDATE_DESKTOP_DATABASE], [update-desktop-database], [no])
  if test "$UPDATE_DESKTOP_DATABASE" = "no"; then
    AC_MSG_ERROR([
*** Could not find the Freedesktop.org desktop entry database update
*** tool. Web provisioning files could not be automatically installed.])
  fi
fi

MOONSHOT_APP="$bindir/moonshot"
MOONSHOT_WEBP="$bindir/moonshot-webp"

AC_SUBST(MIDL)
AC_SUBST(MSVC_LIB)
AC_SUBST(IMAGEMAGICK_CONVERT)
AC_SUBST(WIX_CANDLE)
AC_SUBST(WIX_LIGHT)
AC_SUBST(UPDATE_MIME_DATABASE)
AC_SUBST(UPDATE_DESKTOP_DATABASE)
AC_SUBST(MOONSHOT_APP)
AC_SUBST(MOONSHOT_WEBP)

# Dependencies
PKG_CHECK_MODULES(moonshot,[
        atk >= 1.20
        glib-2.0 >= 2.22
        gobject-2.0 >= 2.22
        libssl
        $GTK_VERSION
        $GEE_VERSION
        $SERVER_IPC_MODULE
		$MAC
])

PKG_CHECK_MODULES(libmoonshot,[
        $CLIENT_IPC_MODULE
])

# i18n stuff
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.17])

AC_SUBST([GETTEXT_PACKAGE],[PACKAGE_TARNAME])
AC_DEFINE([GETTEXT_PACKAGE],[PACKAGE_TARNAME],[Define to the gettext package name.])

AC_CONFIG_FILES([
        Makefile
        po/Makefile.in
        moonshot.desktop
        moonshot-webp.desktop
	moonshot-ui.spec
])

AC_OUTPUT
