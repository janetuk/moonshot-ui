AC_PREREQ([2.66])
AC_INIT([Moonshot],
        [0.0.1],
        [BUG-REPORT-ADDRESS],
        [moonshot])

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([configure.ac])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([1.11 -Wall foreign subdir-objects tar-pax no-dist-gzip dist-xz])
AM_SILENT_RULES([yes])
AM_MAINTAINER_MODE([enable])

LT_PREREQ([2.2])
LT_INIT([win32-dll])

PKG_PROG_PKG_CONFIG([0.24])

# Platform checks
AC_CANONICAL_HOST

case "$host" in
  *-*-mingw*)
    win32=yes
    IPC_MODULE="msrpc-glib2-1.0"
    ;;
  *)
    win32=no
    IPC_MODULE="dbus-glib-1"
    ;;
esac

AM_CONDITIONAL([OS_WIN32], [test "$win32" = "yes"])
AM_CONDITIONAL([IPC_MSRPC], [test "$IPC_MODULE" = "msrpc-glib2-1.0"])
AM_CONDITIONAL([IPC_DBUS], [test "$IPC_MODULE" = "dbus-glib-1"])

# Checks for programs.
AC_PROG_CC
AM_PROG_CC_C_O
AM_PROG_VALAC([0.9])

if test "$IPC_MODULE" = "msrpc-glib2-1.0"; then
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

  # ImageMagick for the 'make icons' target. Watch that it doesn't pick up
  # c:/windows/system32/convert.exe, which is nothing to do with ImageMagick
  AC_PATH_PROG([IMAGEMAGICK_CONVERT], [convert], ,
               [/c/Program\ Files/ImageMagick$PATH_SEPARATOR$PATH])

  # Windows Installer XML tools
  AC_PATH_PROG([WIX_CANDLE], [candle], ,
               [/c/Program\ Files/Windows\ Installer\ XML\ v3.5/bin$PATH_SEPARATOR$PATH])
  AC_PATH_PROG([WIX_LIGHT], [light], ,
               [/c/Program\ Files/Windows\ Installer\ XML\ v3.5/bin$PATH_SEPARATOR$PATH])
fi

AC_SUBST(MIDL)
AC_SUBST(IMAGEMAGICK_CONVERT)
AC_SUBST(WIX_CANDLE)
AC_SUBST(WIX_LIGHT)

# Dependencies
PKG_CHECK_MODULES(moonshot,[
        atk >= 1.20
        glib-2.0 >= 2.24
        gobject-2.0 >= 2.24
        gtk+-2.0 >= 2.20
        $IPC_MODULE
])

PKG_CHECK_MODULES(libmoonshot,[
        $IPC_MODULE
])

# i18n stuff
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.17])

AC_SUBST([GETTEXT_PACKAGE],[PACKAGE_TARNAME])
AC_DEFINE([GETTEXT_PACKAGE],[PACKAGE_TARNAME],[Define to the gettext package name.])

AC_CONFIG_FILES([
        Makefile
        po/Makefile.in
])

AC_OUTPUT
