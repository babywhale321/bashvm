#!/bin/bash
#
#bashvm is a console tool to manage your virtual machines. ("INSTALLER")
#
#Author: Kyle Schroeder "BabyWhale"

# Check and install qemu-kvm
dpkg --list | grep qemu-kvm >> /dev/zero
if [ ! $? == 0 ]; then
    apt install qemu-kvm -y || echo "Installing qemu-kvm has failed. Please check the logs or console output above."
else
    echo "qemu-kvm is already installed."
fi

# Check and install libvirt-daemon-system
dpkg --list | grep libvirt-daemon-system >> /dev/zero
if [ ! $? == 0 ]; then
    apt install libvirt-daemon-system -y || echo "Installing libvirt-daemon-system has failed. Please check the logs or console output above."
else
    echo "libvirt-daemon-system is already installed."
fi

# Check and install libvirt-clients
dpkg --list | grep libvirt-clients >> /dev/zero
if [ ! $? == 0 ]; then
    apt install libvirt-clients -y || echo "Installing libvirt-clients has failed. Please check the logs or console output above."
else
    echo "libvirt-clients is already installed."
fi

# Check and install bridge-utils
dpkg --list | grep bridge-utils >> /dev/zero
if [ ! $? == 0 ]; then
    apt install bridge-utils -y || echo "Installing bridge-utils has failed. Please check the logs or console output above."
else
    echo "bridge-utils is already installed."
fi

# Check and install qemu-utils
dpkg --list | grep qemu-utils >> /dev/zero
if [ ! $? == 0 ]; then
    apt install qemu-utils -y || echo "Installing qemu-utils has failed. Please check the logs or console output above."
else
    echo "qemu-utils is already installed."
fi

# Check and install virt-manager
dpkg --list | grep virt-manager >> /dev/zero
if [ ! $? == 0 ]; then
    apt install virt-manager -y || echo "Installing virt-manager has failed. Please check the logs or console output above."
else
    echo "virt-manager is already installed."
fi

# Check and install htop
dpkg --list | grep htop >> /dev/zero
if [ ! $? == 0 ]; then
    apt install htop -y || echo "Installing htop has failed. Please check the logs or console output above."
else
    echo "htop is already installed."
fi

# Check and install net-tools
dpkg --list | grep net-tools >> /dev/zero
if [ ! $? == 0 ]; then
    apt install net-tools -y || echo "Installing net-tools has failed. Please check the logs or console output above."
else
    echo "net-tools is already installed."
fi

# Check and install ufw
dpkg --list | grep ufw >> /dev/zero
if [ ! $? == 0 ]; then
    apt install ufw -y || echo "Installing ufw has failed. Please check the logs or console output above."
else
    echo "ufw is already installed."
fi

# Check and install dnsmasq
dpkg --list | grep dnsmasq >> /dev/zero
if [ ! $? == 0 ]; then
    apt install dnsmasq -y || echo "Installing dnsmasq has failed. Please check the logs or console output above."
else
    echo "dnsmasq is already installed."
fi

echo ""
echo "======================================================="
echo "If no errors above then you can run bashvm with"
echo "bash bashvm.sh"
echo ""
