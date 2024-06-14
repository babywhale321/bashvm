#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

# Detect debian
if [ ! -f "/etc/debian_version" ]; then
    echo "This installer seems to be running on an unsupported distribution."
    echo "Supported distros are Debian 12 and Ubuntu 22.04."
    exit
fi

# Required packages to download
# Function to check the exit status and exit if failed
check_status() {
    if [ "$1" -ne 0 ]; then
        echo "Error: $2 failed to install."
        exit 1
    fi
}

# Install packages
apt install qemu-kvm -y
check_status $? "qemu-kvm"

apt install libvirt-daemon-system -y
check_status $? "libvirt-daemon-system"

apt install libvirt-clients -y
check_status $? "libvirt-clients"

apt install bridge-utils -y
check_status $? "bridge-utils"

apt install qemu-utils -y
check_status $? "qemu-utils"

apt install virt-manager -y
check_status $? "virt-manager"

apt install cloud-init -y
check_status $? "cloud-init"

apt install net-tools -y
check_status $? "net-tools"

apt install ufw -y
check_status $? "ufw"

apt install btop -y
check_status $? "btop"

apt install bc -y
check_status $? "bc"

apt install ifstat -y
check_status $? "ifstat"

apt install ndppd -y
check_status $? "ndppd"

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
