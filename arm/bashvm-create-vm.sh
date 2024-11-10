#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

# Function to generate a random MAC address
generate_mac_address() {
    printf '52:54:%02x:%02x:%02x:%02x\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

pool_image_download() {
    read -ep "Enter the storage pool name to download / use [default]: " pool_name

    if [ -z "$pool_name" ]; then
        pool_name="default"
    fi
    pool_path=$(virsh pool-dumpxml "$pool_name" | grep '<path>' | cut -d'>' -f2 | cut -d'<' -f1)
    iso_path="$pool_path/$iso_img"
    # Check to see if the iso file is there
    if [ -f "$iso_path" ]; then
        # ISO is already present, Dont download
        echo "File "$iso_img" already there. Canceling re-download."
    else
        # ISO is not present, Download
        cd "$pool_path"
        wget "$iso_download"
        iso_path="$pool_path/$iso_img"
    fi
}


# Prompt user for VM details
read -ep "Enter the name for the new / existing virtual machine: " new_vm_name
read -ep "Enter the amount of memory in MB (e.g., 1024): " new_memory
read -ep "Enter the number of virtual CPUs (e.g., 2): " new_vcpus

echo ""
echo "1. debian-12.5         2. ubuntu-22.04"
echo ""

echo "Enter the iso you would like to use"
read -ep "You can safely say no if you have your own or not using an iso: " iso_question


if [ "$iso_question" == 1 ];then
    iso_img="debian-12.6.0-arm64-netinst.iso"
    iso_download="https://cdimage.debian.org/mirror/cdimage/archive/12.6.0/arm64/iso-cd/debian-12.6.0-arm64-netinst.iso"
    pool_image_download

elif [ "$iso_question" == 2 ];then
    iso_img="ubuntu-22.04.4-live-server-arm64.iso"
    iso_download="http://old-releases.ubuntu.com/releases/jammy/ubuntu-22.04.4-live-server-arm64.iso"
    pool_image_download

else
    # full iso path needed
    echo "Enter the full path to the ISO file (e.g., /var/lib/libvirt/images/debian-12.6.0-arm64-netinst.iso)"
    echo "Note: If you dont want to add an ISO then you can just ignore this option and press enter" 
    read -ep ": " iso_path
fi
    


# DISK CREATION #


read -ep "Would you like to create a new volume? (y/n): " disk_question

# Convert to lowercase
lowercase_input=$(echo "$disk_question" | tr '[:upper:]' '[:lower:]')
if [[ "$lowercase_input" == y || "$lowercase_input" == yes ]];then

    # disk name, capacity and pool
    read -ep "Enter the name of the new storage volume (e.g., new-vm): " volume_name
    read -ep "Enter the size of the volume (e.g., 10GB): " volume_capacity
    read -ep "Enter the storage pool name [default]: " pool_name
    if [ -z "$pool_name" ]; then
        pool_name="default"
    fi
    # virsh command to create new disk
    virsh vol-create-as --pool "$pool_name" --name "$volume_name.qcow2" --capacity "$volume_capacity" --format qcow2
    disk_path=$(virsh vol-path --pool "$pool_name" --vol "$volume_name.qcow2")
else
    # full disk path needed
    read -ep "Enter the full path of the virtual machine disk (e.g., /var/lib/libvirt/images/vm.qcow2): " disk_path
fi
# Network select
read -ep "Enter the network name to connect the virtual machine to [default]: " network_name
if [ -z "$network_name" ]; then
    network_name="default"
fi

read -ep "Enter the mac address for this vm (nothing for auto generate): " mac_address
if [ -z "$mac_address" ];then
    # Generate a random MAC address
    mac_address=$(generate_mac_address)
fi

# Generate a UUID
uuid=$(cat /proc/sys/kernel/random/uuid)

# Define the XML configuration for the new virtual machine
vm_xml="<domain type='kvm'>
  <name>$new_vm_name</name>
  <uuid>$uuid</uuid>
  <memory unit='KiB'>$((new_memory * 1024))</memory>
  <currentMemory unit='KiB'>$((new_memory * 1024))</currentMemory>
  <vcpu>$new_vcpus</vcpu>
  <os firmware='efi'>
    <type arch='aarch64' machine='virt'>hvm</type>
    <boot dev='hd'/>
    <boot dev='cdrom'/>
  </os>
  <features>
    <acpi/>
  </features>
  <cpu mode='host-passthrough'/>
  <clock offset='utc'/>
  <devices>
    <emulator>/usr/bin/qemu-system-aarch64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' discard='unmap'/>
      <source file='$disk_path'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='$iso_path'/>
      <target dev='sda' bus='scsi'/>
      <readonly/>
    </disk>
    <controller type='usb' model='qemu-xhci' ports='15'/>
    <controller type='scsi' model='virtio-scsi'/>
    <controller type='pci' model='pcie-root'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <controller type='pci' model='pcie-root-port'/>
    <interface type='network'>
      <source network='$network_name'/>
      <mac address='$mac_address'/>
      <model type='virtio'/>
    </interface>
    <console type='pty'/>
    <channel type='unix'>
      <source mode='bind'/>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>
    <tpm>
      <backend type='emulator'/>
    </tpm>
  </devices>
</domain>"

# Define the path for the new VM XML file
vm_xml_file="/etc/libvirt/qemu/$new_vm_name.xml"

# Save the XML configuration to the file
echo "$vm_xml" > "$vm_xml_file"

# Create the new virtual machine
virsh define "$vm_xml_file"
