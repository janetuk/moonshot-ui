#!/bin/bash
#
# This script checks that launchctl sets the DBUS_LAUNCHD_SESSION_BUS_SOCKET value
#

# Get the launchctl environment DBUS_LAUNCHD_SESSION_BUS_SOCKET
LAUNCHCTL_DBUS_SOCKET=`launchctl getenv DBUS_LAUNCHD_SESSION_BUS_SOCKET`

# If variable is unset
if [[ "x$LAUNCHCTL_DBUS_SOCKET" == "x" ]] ; then
	echo "No DBUS_LAUNCHD_SESSION_BUS_SOCKET set. Discovering socket and setting it..."
	# stop the Dbus daemon
	launchctl unload ~/Library/LaunchAgents/org.freedesktop.dbus-session.plist
	# get list of sockets
	LAUNCHCTL_PRE_LIST=`find /private/tmp/com.apple.launchd*/unix* -print`
	# start the Dbus daemon
	launchctl load -w ~/Library/LaunchAgents/org.freedesktop.dbus-session.plist
	# look at new list of sockets
	for i in `find /private/tmp/com.apple.launchd*/unix* -print`
	do
		# aha! You didn't exist in the list, I'll set DBUS_LAUNCHD_SESSION_BUS_SOCKET to you
		if ! [[ "$LAUNCHCTL_PRE_LIST" =~ "$i" ]]; then
			launchctl setenv DBUS_LAUNCHD_SESSION_BUS_SOCKET $i
			LAUNCHCTL_DBUS_SOCKET=`launchctl getenv DBUS_LAUNCHD_SESSION_BUS_SOCKET`
		fi
	done
fi
# it exists, echo it
echo $LAUNCHCTL_DBUS_SOCKET
