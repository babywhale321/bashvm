#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

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
echo ""
apt install libvirt-daemon-system -y
check_status $? "libvirt-daemon-system"
echo ""
apt install libvirt-clients -y
check_status $? "libvirt-clients"
echo ""
apt install bridge-utils -y
check_status $? "bridge-utils"
echo ""
apt install qemu-utils -y
check_status $? "qemu-utils"
echo ""
apt install virt-manager -y
check_status $? "virt-manager"
echo ""
apt install cloud-init -y
check_status $? "cloud-init"
echo ""
apt install net-tools -y
check_status $? "net-tools"
echo ""
apt install ufw -y
check_status $? "ufw"
echo ""
apt install btop -y
check_status $? "btop"
echo ""
apt install bc -y
check_status $? "bc"
echo ""
apt install ifstat -y
check_status $? "ifstat"
echo ""
apt install ndppd -y
check_status $? "ndppd"
echo ""
apt install sqlite3 -y
check_status $? "sqlite3"
echo ""

# Check and install dnsmasq
dpkg --list | grep dnsmasq >> /dev/null
if [ ! $? == 0 ]; then
    apt install dnsmasq -y
else
    echo "dnsmasq is already installed."
fi
echo ""

# Check and manage the default pool
if ! virsh pool-info default &>/dev/null; then
    echo "Default storage pool not found. Creating it..."
    virsh pool-define-as default dir --target /var/lib/libvirt/images
    virsh pool-start default
    virsh pool-autostart default
else
    if ! virsh pool-list --all | grep -q "default .* active"; then
        echo "Default storage pool exists but is inactive. Starting it..."
        virsh pool-start default
        virsh pool-autostart default
    else
        echo "Default storage pool is already active."
    fi
fi
echo ""

# Check and manage the default network
if ! virsh net-info default &>/dev/null; then
    echo "Default network not found. Creating it..."
    virsh net-define /etc/libvirt/qemu/networks/default.xml
    virsh net-start default
    virsh net-autostart default
else
    if ! virsh net-list --all | grep -q "default .* active"; then
        echo "Default network exists but is inactive. Starting it..."
        virsh net-start default
        virsh net-autostart default
    else
        echo "Default network is already active."
    fi
fi
echo ""

echo "==========================================================="
echo "If no errors above then you can run bashvm with"
echo "bash bashvm.sh"
echo ""
