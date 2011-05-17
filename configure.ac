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

# Checks for programs.
AC_PROG_CC
AM_PROG_CC_C_O
AM_PROG_VALAC([0.9])

# Platform-specific checks
AC_CANONICAL_HOST

case "$host" in
  *-*-mingw*)
    AC_PATH_MSRPC_MINGW([0.1.0], :,
      AC_MSG_ERROR([
*** msrpc-mingw 0.1.0 or better is required.]))


    AC_PATH_PROG([MIDL], [midl], no)
    if test "$MIDL" = "no"; then
       AC_MSG_ERROR([
*** Could not find the Microsoft interface compiler MIDL.EXE.
*** This program is available as part of the MS Windows SDK, in
*** the Win32 Development Tools package.])
    fi

    IPC="msrpc-glib2-1.0"
    ;;
  *)
    IPC="dbus-glib"
    ;;
esac

AC_SUBST(MIDL)

AM_CONDITIONAL([IPC_MSRPC], [test "$IPC" = "msrpc-glib2-1.0"])
AM_CONDITIONAL([IPC_DBUS], [test "$IPC" = "dbus-glib"])

# Dependencies
PKG_CHECK_MODULES(moonshot,[
        atk >= 1.20
        glib-2.0 >= 2.24
        gobject-2.0 >= 2.24
        gtk+-2.0 >= 2.20
        $IPC
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
