#!/bin/bash

read -ep "Enter the hostname of the new VM: " vm_name
read -ep "Enter the username for the new VM: " user_name
read -ep "Enter the password for the new VM: " user_pass

cp bashvm-cloudinit.yaml bashvm-cloudinit.yaml.backup

sed -i "s/default-vm/$vm_name/g" bashvm-cloudinit.yaml
sed -i "s/bashvm/$user_name/g" bashvm-cloudinit.yaml
sed -i "s/password/$user_pass/g" bashvm-cloudinit.yaml

# Copy cloudinit file to default location
cp bashvm-cloudinit.yaml /var/lib/libvirt/images
cp bashvm-cloudinit.yaml.backup bashvm-cloudinit.yaml
rm bashvm-cloudinit.yaml.backup
cd /var/lib/libvirt/images

# Check to see if the qcow2 file is there
if [ -f "debian-12-generic-amd64.qcow2" ]; then
    # Dont download
    echo "File debian-12-generic-amd64.qcow2 already there. Canceling re-download."
else
    # Download
    wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
fi

virsh net-info default | grep "Active:" | grep "yes" >> /dev/null
if [ ! $? == 0 ]; then
#start default
virsh net-start default
# Enable autostart of default network
virsh net-autostart default
fi

echo "NOTE: press Ctrl + ] to exit the vm"

# Deploy the new VM
virt-install --name $vm_name --memory 2048 --vcpus 2 --disk=size=20,backing_store=/var/lib/libvirt/images/debian-12-generic-amd64.qcow2 --cloud-init user-data=./bashvm-cloudinit.yaml,disable=on --network bridge=virbr0 --osinfo=debian10
