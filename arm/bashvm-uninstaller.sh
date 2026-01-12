#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

# Prompt the user about this script
echo ""
echo "This uninstall script will only remove packages and dependencies needed to run bashvm"
echo ""
echo "Here is a list of packages that would have been installed with the installer"
echo "qemu-kvm, libvirt-daemon-system, libvirt-clients, virt-manager, qemu-utils,"
echo "cloud-init, bridge-utils, net-tools, ufw, ifstat, ndppd, btop, bc, sqlite3"
echo ""
echo "Do not run this script if any of the packages above are needed for other programs"
echo ""
echo "Please type remove to continue or type cancel to exit this script"

# Prompt the user to continue ("remove") or exit ("cancel") out of this script
while true; do

    read -ep ": " check_to_continue

    lowercase_check_to_continue=$(echo "$check_to_continue" | tr '[:upper:]' '[:lower:]')
    
    if [ "$lowercase_check_to_continue" == "cancel" ]; then
        exit

    elif [ "$lowercase_check_to_continue" == "remove" ]; then
        break
    
    else
        echo "Please enter the word remove to uninstall bashvm"
        echo "Please enter the word cancel to cancel the uninstall of bashvm"
        echo ""
        continue
    fi
done
    

# Required packages to remove
# Function to check the exit status and exit if failed
check_status() {
    if [ "$1" -ne 0 ]; then
        echo "Error: $2 failed to uninstall."
        exit 1
    fi
}

# Uninstall packages
apt remove qemu-kvm -y
check_status $? "qemu-kvm"
echo ""
apt remove libvirt-daemon-system -y
check_status $? "libvirt-daemon-system"
echo ""
apt remove libvirt-clients -y
check_status $? "libvirt-clients"
echo ""
apt remove bridge-utils -y
check_status $? "bridge-utils"
echo ""
apt remove qemu-utils -y
check_status $? "qemu-utils"
echo ""
apt remove virt-manager -y
check_status $? "virt-manager"
echo ""
apt remove cloud-init -y
check_status $? "cloud-init"
echo ""
apt remove net-tools -y
check_status $? "net-tools"
echo ""
apt remove ufw -y
check_status $? "ufw"
echo ""
apt remove btop -y
check_status $? "btop"
echo ""
apt remove bc -y
check_status $? "bc"
echo ""
apt remove ifstat -y
check_status $? "ifstat"
echo ""
apt remove ndppd -y
check_status $? "ndppd"
echo ""
apt remove sqlite3 -y
check_status $? "sqlite3"
echo ""
# Remove dependencies that are now orphaned
apt autoremove -y

echo "=============================================================================="
echo ""
echo "If no error's above then all required packages for bashvm are now uninstalled"
echo ""
