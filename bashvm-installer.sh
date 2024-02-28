#!/bin/bash
#
# bashvm.com
#
# Author: Kyle Schroeder "BabyWhale"

# Detect debian
if [ ! -f "/etc/debian_version" ]; then
    echo "This installer seems to be running on an unsupported distribution."
    echo "Supported distros are Debian 11, Debian 12 and Ubuntu 22.04."
    exit
fi

# Required packages to download

apt install qemu-kvm -y

apt install libvirt-daemon-system -y

apt install libvirt-clients -y

apt install bridge-utils -y

apt install qemu-utils -y

apt install virt-manager -y

apt install cloud-init -y

apt install net-tools -y

apt install ufw -y

apt install htop -y

apt install ndppd -y

# Check and install dnsmasq
dpkg --list | grep dnsmasq >> /dev/null
if [ ! $? == 0 ]; then
    apt install dnsmasq -y
else
    echo "dnsmasq is already installed."
fi

echo ""
echo "======================================================="
echo "If no errors above then you can run bashvm with"
echo "bash bashvm.sh"
echo ""
