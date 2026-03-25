#!/bin/bash
# safe general linux hardening script

set -euo pipefail

echo "starting general hardening..."

# 1. root password
echo "setting root password..."

read -sp "enter new root password: " ROOTPASS
echo ""
echo "root:$ROOTPASS" | chpasswd
echo "root password updated."

# 2. sshd
echo "hardening ssh..."

SSHD="/etc/ssh/sshd_config"

if [ ! -f "$SSHD" ]; then
    echo "sshd_config not found, exiting."
    exit 1
fi

# disable root login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD"

# enforce password authentication
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' "$SSHD"

# disable empty passwords
sed -i 's/^PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD"

# disable challenge-response
sed -i 's/^ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' "$SSHD"

# ensure protocol 2
if ! grep -q "^Protocol 2" "$SSHD"; then
    echo "Protocol 2" >> "$SSHD"
fi

systemctl reload sshd || systemctl reload ssh || true
echo "ssh hardened."

# 3. sudo
echo "checking sudo settings..."

# ensure sudo requires a password
if [ -f /etc/sudoers ]; then
    sed -i 's/^%sudo ALL=(ALL:ALL) NOPASSWD: ALL/%sudo ALL=(ALL:ALL) ALL/' /etc/sudoers || true
fi

echo "sudo settings updated."

# 4. permissions
echo "fixing sensitive file permissions..."

chmod 600 /etc/shadow || true
chmod 600 /etc/gshadow || true
chmod 600 /etc/ssh/ssh_host_* || true

echo "permissions updated."

# 5. sysctl
echo "applying basic sysctl hardening..."

SYSCTL="/etc/sysctl.conf"

# disable ip forwarding
if ! grep -q "^net.ipv4.ip_forward" "$SYSCTL"; then
    echo "net.ipv4.ip_forward = 0" >> "$SYSCTL"
fi

# disable source routing
if ! grep -q "^net.ipv4.conf.all.accept_source_route" "$SYSCTL"; then
    echo "net.ipv4.conf.all.accept_source_route = 0" >> "$SYSCTL"
fi

# enable reverse path filtering
if ! grep -q "^net.ipv4.conf.all.rp_filter" "$SYSCTL"; then
    echo "net.ipv4.conf.all.rp_filter = 1" >> "$SYSCTL"
fi

sysctl -p >/dev/null 2>&1 || true
echo "sysctl settings applied."

# 6. updates
echo "checking for updates..."

apt-get update -y >/dev/null 2>&1 || true
apt-get upgrade -y >/dev/null 2>&1 || true

echo "updates complete."

echo "general hardening complete."
