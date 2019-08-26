AC_PREREQ([2.63])
AC_INIT([Moonshot-ui],
        [1.2.4],
        [moonshot@jiscmail.ac.uk],
        [moonshot-ui],
        [http://www.project-moonshot.org/])

# Remove this when we can depend on autoconf >= 2.64
AC_SUBST(PACKAGE_URL, [http://www.project-moonshot.org/])
AC_DEFINE(PACKAGE_URL,["http://www.project-moonshot.org"],[package URL])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_SRCDIR([configure.ac])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_AUX_DIR([build-aux])
AC_SUBST([KEYRING_VALAFLAGS],[])

AM_INIT_AUTOMAKE([1.11 -Wall foreign subdir-objects tar-pax no-dist-gzip dist-xz])
AM_SILENT_RULES([yes])
AM_MAINTAINER_MODE([enable])

LT_PREREQ([2.2])
LT_INIT([win32-dll])
AC_CHECK_FUNCS_ONCE(geteuid getpwuid)

# Checks for programs.
PKG_PROG_PKG_CONFIG([0.23])
AC_PROG_CC
AC_PROG_LN_S
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

    # On macOS, we require dbus-glib-1 for the client library for the time being.
    CLIENT_IPC_MODULE="dbus-glib-1"
    SERVER_IPC_MODULE="dbus-glib-1"
  
#    # Use gdbus for everything
#    CLIENT_IPC_MODULE="gio-2.0"
#    SERVER_IPC_MODULE="gio-2.0"

    ;;
  *)
    macos=no
    win32=no
    linux=yes

    # Now use gdbus for everything, so no test
    CLIENT_IPC_MODULE="gio-2.0"
    SERVER_IPC_MODULE="gio-2.0"

    PKG_CHECK_MODULES([KEYRING],
	[libsecret-1, gcr-3],
	[KEYRING_VALAFLAGS=" --pkg libsecret-1 --define LIBSECRET_KEYRING"],
	[
		PKG_CHECK_MODULES([KEYRING], [gnome-keyring-1],
		[KEYRING_VALAFLAGS="--pkg moonshot-gnome-keyring --define GNOME_KEYRING"],
		[AC_ERROR(["Neither gnome-keyring not libsecret+gcr is found])
		])
    ])
    ;;
esac

### if not on macOS ###
# On Windows/Linux we use ATK, GTK, LOG4VALA and LIBGEE
if test "$macos" = "no"; then

  # Windows/Linux: Use ATK 1.2 or higher
  PKG_CHECK_MODULES([ATK], 
      [atk >= 1.20]
  )

# Windows/Linux: Use Gtk+3.0 if available; else revert to Gtk+2.0
PKG_CHECK_MODULES([GTK],
        [gtk+-3.0 >= 3.1],
        [GTK_VERSION="gtk+-3.0"],
            [PKG_CHECK_MODULES([GTK],
                        [gtk+-2.0 >= 2.18],
                        [GTK_VERSION="gtk+-2.0"]
            )]
)
AC_SUBST(GTK_VERSION)


# Windows/Linux: If Log4Vala is enabled, then Use Log4Vala 0.2 if available; else revert to 0.1
if [test x$log4vala = xtrue]; then
PKG_CHECK_MODULES([LOG4VALA],
        [log4vala-0.2],
        [LOG4VALA_VERSION="log4vala-0.2"],
            [PKG_CHECK_MODULES([LOG4VALA],
                        [log4vala-0.1],
                        [LOG4VALA_VERSION="log4vala-0.1"]
            )]
)
AC_SUBST(LOG4VALA_VERSION)
fi


# Windows/Linux: Use gee-0.8 if available; else revert to gee-1.0
# (yes, gee-0.8 is an upgrade from gee-1.0!)
PKG_CHECK_MODULES([LIB_GEE],
        [gee-0.8 >= 0.10.5],
        [GEE_VERSION="gee-0.8"],
            [PKG_CHECK_MODULES([LIB_GEE],
                        [gee-1.0 >= 0.5],
                        [GEE_VERSION="gee-1.0"]
            )]
)
AC_SUBST(GEE_VERSION)

# Windows/Linux: Use libnewt
PKG_CHECK_MODULES([LIB_NEWT], [libnewt >= 0.52])

# For all platforms: Use libkeyutils
AC_CHECK_HEADERS([keyutils.h])
AC_CHECK_LIB(keyutils, request_key, [], [
  echo "Error! You need to have libkeyutils"
  exit -1
])

#enable the optional use of Log4Vala (Must have the package installed!)
AC_ARG_ENABLE([log4vala],
[  --enable-log4vala    Enable use of log4vala for logging],
[case "${enableval}" in
  yes) log4vala=true ;;
  no)  log4vala=false ;;
  *) AC_MSG_ERROR([bad value ${enableval} for --enable-log4vala]) ;;
esac],[log4vala=false])
AM_CONDITIONAL([LOG4VALA], [test x$log4vala = xtrue])

else
  ## On macOS, find xcodebuild! ##
  # locate currently selected Xcode path
  AC_MSG_CHECKING(Xcode location)
  if test "x$XCODE_SELECT" != "x"; then
    DEVELOPER_DIR=`$XCODE_SELECT -print-path`
  fi
  if test -z "$DEVELOPER_DIR" -o ! -d "$DEVELOPER_DIR" ; then
      if test -d /Applications/Xcode.app/Contents/Developer ; then
          DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
      else
          DEVELOPER_DIR=/Developer
      fi
  fi
  AC_MSG_RESULT([$DEVELOPER_DIR])
  AC_SUBST(DEVELOPER_DIR)

  case "$DEVELOPER_DIR" in
    *Xcode.app/Contents/Developer)
      XCODEPLIST_BASE=`dirname $DEVELOPER_DIR`/version
      ;;
    *)
      XCODEPLIST_BASE=$DEVELOPER_DIR/Applications/Xcode.app/Contents/version
      ;;
  esac
  XCODEPLIST=${XCODEPLIST_BASE}.plist
  if test -r "$XCODEPLIST"; then
    AC_MSG_CHECKING(Xcode version)
    if test "x$DEFAULTS" != "x"; then
      XCODE_VERSION=`$DEFAULTS read $XCODEPLIST_BASE CFBundleShortVersionString`
    else
      XCODE_VERSION=`tr -d '\r\n' < $XCODEPLIST | sed -e 's/.*<key>CFBundleShortVersionString<\/key>.<string>\([[0-9.]]*\)<\/string>.*/\1/'`
    fi
    AC_MSG_RESULT([$XCODE_VERSION])
  fi

  case "$XCODE_VERSION" in
    1.*|2.[[0-1]]*)
      AC_MSG_WARN([This version of Xcode Tools is not supported])
      AC_MSG_WARN([Please upgrade at https://developer.apple.com/downloads/])
      ;;
    2.[[2-3]]*|3.[[0]]*)
      AC_MSG_WARN([This version of Xcode Tools is out of date])
      AC_MSG_WARN([Please consider upgrading as some ports fail compiling])
      ;;
    2.*|3.*|4.*|5.*|6.*|7.*|8.*|9.*|10.*)
      dnl Supported version
      ;;
    *)
      ;;
  esac

  AC_PATH_PROG(XCODEBUILD, [xcodebuild], [no])
  if test "$XCODEBUILD" = "no"; then
    AC_MSG_ERROR([
*** Could not find the Xcode Build binary. Please install Xcode.])
  fi

AC_MSG_CHECKING(for Apple Developer Team ID)
APPLE_DEVELOPER_TEAM_ID=
APPLE_DEVELOPER_ID_INSTALLER=
APPLE_DEVELOPER_ID_APPLICATION=
found_apple_developer_id="no"
AC_ARG_WITH(apple_developer_id,
    AC_HELP_STRING([--with-apple-developer-id],
       [Use specified Apple Developer Team ID, set to 'no' for none]),
    [use_apple_developer_id="$withval"],
    [use_apple_developer_id=])

  # We don't want to set an Apple Developer ID
  if test "x$use_apple_developer_id" = "xno"; then
    AC_MSG_WARN([
----------------------------------------------------------------------
  Disabling Apple Developer Team ID.

  This may mean that the Moonshot app and uninstaller will not be
  signed and may not be able to run on target systems.
----------------------------------------------------------------------
    ])
  else
    # Ok, there is no Developer ID cert on the system or the one set on the command-line does not exist on this system
    if test "x$(security find-identity -v login.keychain |grep 'Developer ID' |grep "$use_apple_developer_id" |grep -c -v 'valid identities')" = "x0"; then
      AC_MSG_RESULT($found_apple_developer_id)
      if test "x$use_apple_developer_id" = "x"; then
        AC_MSG_WARN([
----------------------------------------------------------------------
  Cannot find a Apple Developer Team ID. Disabling signing.

  This may mean that the Moonshot app and uninstaller will not be
  signed and may not be able to run on target systems.
----------------------------------------------------------------------
        ])
      else
        AC_MSG_WARN([
----------------------------------------------------------------------
  Cannot find your specified Apple Developer Team ID.

  Please check that a Developer ID Application and a Developer ID 
  Installer certificate matching your given ID are installed.
----------------------------------------------------------------------
        ])
      fi
    else
      # We have a valid Developer ID set, or we haven't set one but there is a valid Developer ID installed
      found_apple_developer_id="yes"
      AC_MSG_RESULT($found_apple_developer_id)
      if test "x$use_apple_developer_id" = "x"; then
        # We take the first one listed
        apple_developer_id=$(security find-identity -v login.keychain |grep 'Developer ID' |head -1 |cut -f 2 -d\")
        use_apple_developer_id=$(echo $apple_developer_id |cut -f 2 -d\( |cut -f 1 -d\))
        AC_MSG_WARN([Setting Apple Developer ID to "$use_apple_developer_id". This may not be correct!])
      else
        AC_MSG_NOTICE([Apple Developer ID is "$use_apple_developer_id".])
      fi
      # We list the Apple Developer ID, and then find the Application and Installer certificates for this ID
      APPLE_DEVELOPER_TEAM_ID=$use_apple_developer_id
      APPLE_DEVELOPER_ID_INSTALLER=$(security find-identity -v login.keychain |grep "$use_apple_developer_id" |grep 'Developer ID Installer' |cut -f 2 -d\")
      AC_MSG_NOTICE([Setting Apple Developer ID Installer to "$APPLE_DEVELOPER_ID_INSTALLER".])
      APPLE_DEVELOPER_ID_APPLICATION=$(security find-identity -v login.keychain |grep "$use_apple_developer_id" |grep 'Developer ID Application' |cut -f 2 -d\")
      AC_MSG_NOTICE([Setting Apple Developer ID Application to "$APPLE_DEVELOPER_ID_APPLICATION".])
    fi
  fi
  AC_SUBST(APPLE_DEVELOPER_TEAM_ID)
  AC_SUBST(APPLE_DEVELOPER_ID_INSTALLER)
  AC_SUBST(APPLE_DEVELOPER_ID_APPLICATION)
fi
# To make autotools happy
AM_CONDITIONAL([WITH_APPLE_DEVELOPER_ID_INSTALLER], [test "x$APPLE_DEVELOPER_ID_INSTALLER" != "x"])
AM_CONDITIONAL([WITH_APPLE_DEVELOPER_ID_APPLICATION], [test "x$APPLE_DEVELOPER_ID_APPLICATION" != "x"])
AM_CONDITIONAL([LOG4VALA], [test x$log4vala = xtrue])
### end of macOS ###

AM_CONDITIONAL([IPC_DBUS_GLIB], [test "$SERVER_IPC_MODULE" = "dbus-glib-1"])
AM_CONDITIONAL([IPC_GDBUS], [test "$SERVER_IPC_MODULE" = "gio-2.0"])

AM_CONDITIONAL([OS_LINUX], [test "$linux" = "yes"])
AM_CONDITIONAL([OS_WIN32], [test "$win32" = "yes"])
AM_CONDITIONAL([OS_MACOS], [test "$macos" = "yes"])

AM_CONDITIONAL([IPC_MSRPC], [test "$SERVER_IPC_MODULE" = "msrpc-glib2-1.0"])
AM_CONDITIONAL([IPC_DBUS], [test "$SERVER_IPC_MODULE" != "msrpc-glib2-1.0"])


# On Windows/Linux we use ATK, GTK, LOG4VALA and LIBGEE
vala_version=`$VALAC --version | sed 's/Vala  *//'`
AS_VERSION_COMPARE(["$vala_version"], [0.11.1],
  [gio_vapi_uses_arrays="no"],
  [gio_vapi_uses_arrays="yes"],
  [gio_vapi_uses_arrays="yes"])
AM_CONDITIONAL([GIO_VAPI_USES_ARRAYS], [test "$gio_vapi_uses_arrays" = "yes"])

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

### If on Windows ###
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
### end of Windows ###

### If on Linux ###
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
### end of Linux ###

AM_COND_IF([IPC_DBUS],
           [AC_ARG_VAR(DBUS_DAEMON, [Location of dbus-daemon executable])
            AC_PATH_PROG([DBUS_DAEMON], [dbus-daemon], [no])
            if test "$DBUS_DAEMON" = "no"; then
              AC_MSG_ERROR([
*** Could not find the dbus-daemon executable. This is required.])
            fi ])

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
        glib-2.0 >= 2.26
        gobject-2.0 >= 2.26
        libssl
        $ATK
        $GTK_VERSION
        $GEE_VERSION
        $SERVER_IPC_MODULE
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
        macos-ui/Makefile
        po/Makefile.in
        moonshot.desktop
        moonshot-webp.desktop
        moonshot-ui.spec
        APKBUILD
        PKGBUILD
])

AC_OUTPUT
