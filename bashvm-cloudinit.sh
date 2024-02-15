#!/bin/bash
echo ""
echo "====== Default Login ======"
echo "Default username: bashvm"
echo "Default password: bashvm"
echo ""

read -ep "Enter the new VM name: " vmname

# Copy cloudinit file to default location
cp bashvm-cloudinit.yaml /var/lib/libvirt/images
cd /var/lib/libvirt/images

# Check to see if the qcow2 file is there
if [ -f "debian-12-generic-amd64.qcow2" ]; then
    # Dont download
    echo "File debian-12-generic-amd64.qcow2 already there. Canceling re-download."
else
    # Download
    wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
fi

# Enable default network
virsh net-start default
# Enable autostart of default network
virsh net-autostart default

echo "NOTE: press Ctrl + ] to exit the vm"

# Deploy the new VM
virt-install --name $vmname --memory 2048 --vcpus 2 --disk=size=20,backing_store=/var/lib/libvirt/images/debian-12-generic-amd64.qcow2 --cloud-init user-data=./bashvm-cloudinit.yaml,disable=on --network bridge=virbr0 --osinfo=debian10
