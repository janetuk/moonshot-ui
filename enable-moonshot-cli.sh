#!/usr/bin/env bash
# The Moonshot UI requires a DBUS user session to work.
# When DISPLAY is set, libdbus automatically launches a new session,
# but in pure CLI environment, we need to launch it ourselves.
# The trap line would take care of killing the bus when not needed anymore.
eval $(dbus-launch --sh-syntax)
trap "kill $DBUS_SESSION_BUS_PID" exit

# If gnome-keyring is installed, launch a new instance associated to the new bus
if command -v gnome-keyring &> /dev/null;
then
    mkdir -p $HOME/.cache
    eval $(/usr/bin/gnome-keyring-daemon "--start")
    export $(gnome-keyring-daemon)
fi
