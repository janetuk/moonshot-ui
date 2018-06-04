#!/bin/bash
rm /Applications/local.tar.gz

sudo chmod 600 /usr/local/moonshot/org.freedesktop.dbus-session.plist
sudo chown root /usr/local/moonshot/org.freedesktop.dbus-session.plist

ln -sfv /usr/local/moonshot/*.plist ~/Library/LaunchAgents

launchctl load ~/Library/LaunchAgents/org.freedesktop.dbus-session.plist
launchctl unload ~/Library/LaunchAgents/org.freedesktop.dbus-session.plist
launchctl load ~/Library/LaunchAgents/org.freedesktop.dbus-session.plist
