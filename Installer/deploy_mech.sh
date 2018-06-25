#!/bin/bash
sudo tar -zxvf local.tar.gz -C /usr/local/
sudo mkdir /etc/gss/
printf "eap-aes128 1.3.6.1.5.5.15.1.1.17 /usr/local/lib/gss/mech_eap.so\neap-aes256 1.3.6.1.5.5.15.1.1.18 /usr/local/lib/gss/mech_eap.so" | sudo tee -a /etc/gss/mech

sudo mkdir -p ~/Library/LaunchAgents
sudo cp /usr/local/moonshot/org.freedesktop.dbus-session.plist ~/Library/LaunchAgents/
sudo chmod 604 ~/Library/LaunchAgents/org.freedesktop.dbus-session.plist
sudo chown root:wheel ~/Library/LaunchAgents/org.freedesktop.dbus-session.plist

/usr/local/moonshot/bin/dbus-uuidgen --ensure=/usr/local/moonshot/var/lib/dbus/machine-id

sudo launchctl load -w ~/Library/LaunchAgents/org.freedesktop.dbus-session.plist