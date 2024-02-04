#!/bin/bash
#
#vps-manager written in bash ("INSTALLER")
#
#Author: Kyle Schroeder "BabyWhale"

apt install qemu-kvm -y || echo "Installing qemu-kvm has failed. Please check the logs or console output above."
apt install libvirt-daemon-system -y || echo "Installing libvirt-daemon-system has failed. Please check the logs or console output above."
apt install libvirt-clients -y || echo "Installing libvirt-clients has failed. Please check the logs or console output above."
apt install bridge-utils -y || echo "Installing bridge-utils has failed. Please check the logs or console output above."
apt install git -y || echo "Installing git has failed. Please check the logs or console output above."
apt install neofetch -y || echo "Installing neofetch has failed. Please check the logs or console output above."

git clone https://github.com/novnc/noVNC.git || echo "cloning novnc has failed. Please check the logs or console output above."

echo "If no errors then everything should be up and ready to use!"
echo "Run vps-manager.sh to use the interface."
