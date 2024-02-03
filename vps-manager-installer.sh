#!/bin/bash
#
#vps-manager written in bash ("INSTALLER")
#
#Author: Kyle Schroeder "BabyWhale"

apt install qemu-kvm || echo "Installing qemu-kvm has failed. Please check the logs or console output above."
apt install libvirt-daemon-system || echo "Installing libvirt-daemon-system has failed. Please check the logs or console output above."
apt install libvirt-clients || echo "Installing libvirt-clients has failed. Please check the logs or console output above."
apt install bridge-utils || echo "Installing bridge-utils has failed. Please check the logs or console output above."
apt install git || echo "Installing git has failed. Please check the logs or console output above."

git clone https://github.com/novnc/noVNC.git || echo "cloning novnc has failed. Please check the logs or console output above."

echo "If no errors then everything should be up and ready to use!"
echo "Run vps-manager.sh to use the interface."