#!/bin/bash
#
#bashvm is a console tool to manage your virtual machines. ("INSTALLER")
#
#Author: Kyle Schroeder "BabyWhale"

apt install qemu-kvm -y || echo "Installing qemu-kvm has failed. Please check the logs or console output above."
apt install libvirt-daemon-system -y || echo "Installing libvirt-daemon-system has failed. Please check the logs or console output above."
apt install libvirt-clients -y || echo "Installing libvirt-clients has failed. Please check the logs or console output above."
apt install bridge-utils -y || echo "Installing bridge-utils has failed. Please check the logs or console output above."
apt install qemu-utils -y || echo "Installing qemu-utils has failed. Please check the logs or console output above."
apt install htop -y || echo "Installing htop has failed. Please check the logs or console output above."
apt install net-tools -y || echo "Installing net-tools has failed. Please check the logs or console output above."
apt install ufw -y || echo "Installing ufw has failed. Please check the logs or console output above."

echo ""
echo "If no errors then everything should be up and ready to use!"
echo "Run bashvm.sh to use the interface."
