#!/bin/sh

# Install resolvconf
sudo apt update
sudo apt install -y resolvconf
sudo systemctl enable --now resolvconf.service

# Setup DNS nameserver
if ! grep -q "nameserver $1" "/etc/resolv.conf"; then
    echo "nameserver $1" >> /etc/resolvconf/resolv.conf.d/head
   sudo resolvconf -u
fi
