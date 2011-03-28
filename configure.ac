AC_PREREQ([2.66])
AC_INIT([Moonshot],
        [0.0.1],
        [BUG-REPORT-ADDRESS],
        [moonshot])

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([configure.ac])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])

AM_INIT_AUTOMAKE([1.11 -Wall foreign subdir-objects])
AM_SILENT_RULES([yes])

# Checks for programs.
AC_PROG_CC
AM_PROG_CC_C_O
AM_PROG_VALAC([0.9])

# Dependencies
PKG_CHECK_MODULES(moonshot,[
        glib-2.0 >= 2.26
        gobject-2.0 >= 2.26
        gtk+-2.0 >= 2.22
])

# i18n stuff
AM_GNU_GETTEXT([external])
AM_GNU_GETTEXT_VERSION([0.18.1])

AC_SUBST([GETTEXT_PACKAGE],[PACKAGE_TARNAME])
AC_DEFINE([GETTEXT_PACKAGE],[PACKAGE_TARNAME],[Define to the gettext package name.])

AC_CONFIG_FILES([
        Makefile
        po/Makefile.in
])

AC_OUTPUT
