#!/bin/bash
sudo tar -zxvf local.tar.gz -C /usr/local/
sudo mkdir /etc/gss/
printf "eap-aes128 1.3.6.1.5.5.15.1.1.17 /usr/local/lib/gss/mech_eap.so\neap-aes256 1.3.6.1.5.5.15.1.1.18 /usr/local/lib/gss/mech_eap.so" | sudo tee -a /etc/gss/mech