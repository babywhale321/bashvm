#!/bin/bash
#
#bashvm is a console tool to manage your virtual machines. ("INSTALLER")
#
#Author: Kyle Schroeder "BabyWhale"

# Detect debian
if [ ! -f "/etc/debian_version" ]; then
    echo "This installer seems to be running on an unsupported distribution."
    echo "Supported distros are Debian 11, Debian 12 and Ubuntu 22.04."
    exit
fi

# Check and install qemu-kvm
dpkg --list | grep qemu-kvm >> /dev/null
if [ ! $? == 0 ]; then
    apt install qemu-kvm -y
else
    echo "qemu-kvm is already installed."
fi

# Check and install libvirt-daemon-system
dpkg --list | grep libvirt-daemon-system >> /dev/null
if [ ! $? == 0 ]; then
    apt install libvirt-daemon-system -y
else
    echo "libvirt-daemon-system is already installed."
fi

# Check and install libvirt-clients
dpkg --list | grep libvirt-clients >> /dev/null
if [ ! $? == 0 ]; then
    apt install libvirt-clients -y
else
    echo "libvirt-clients is already installed."
fi

# Check and install bridge-utils
dpkg --list | grep bridge-utils >> /dev/null
if [ ! $? == 0 ]; then
    apt install bridge-utils -y
else
    echo "bridge-utils is already installed."
fi

# Check and install qemu-utils
dpkg --list | grep qemu-utils >> /dev/null
if [ ! $? == 0 ]; then
    apt install qemu-utils -y
else
    echo "qemu-utils is already installed."
fi

# Check and install virt-manager
dpkg --list | grep virt-manager >> /dev/null
if [ ! $? == 0 ]; then
    apt install virt-manager -y
else
    echo "virt-manager is already installed."
fi

# Check and install cloud-init
dpkg --list | grep cloud-init >> /dev/null
if [ ! $? == 0 ]; then
    apt install cloud-init -y
else
    echo "cloud-init is already installed."
fi

# Check and install net-tools
dpkg --list | grep net-tools >> /dev/null
if [ ! $? == 0 ]; then
    apt install net-tools -y
else
    echo "net-tools is already installed."
fi

# Check and install ufw
dpkg --list | grep ufw >> /dev/null
if [ ! $? == 0 ]; then
    apt install ufw -y
else
    echo "ufw is already installed."
fi

# Check and install dnsmasq
dpkg --list | grep dnsmasq >> /dev/null
if [ ! $? == 0 ]; then
    apt install dnsmasq -y
else
    echo "dnsmasq is already installed."
fi

apt install htop -y

apt install ndppd -y

echo ""
echo "======================================================="
echo "If no errors above then you can run bashvm with"
echo "bash bashvm.sh"
echo ""
