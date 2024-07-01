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
echo "1. debian-12.5         2. ubuntu-22.04  3. AlmaLinux-9.4"
echo "4. openmediavault_7.0  5. TrueNas-13.0  "
echo ""

echo "Enter the iso you would like to use"
read -ep "You can safely say no if you have your own or not using an iso: " iso_question


if [ "$iso_question" == 1 ];then
    iso_img="debian-12.5.0-amd64-netinst.iso"
    iso_download="https://cdimage.debian.org/mirror/cdimage/archive/12.5.0/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso"
    pool_image_download

elif [ "$iso_question" == 2 ];then
    iso_img="ubuntu-22.04.4-live-server-amd64.iso"
    iso_download="https://releases.ubuntu.com/jammy/ubuntu-22.04.4-live-server-amd64.iso"
    pool_image_download

elif [ "$iso_question" == 3 ];then
    iso_img="AlmaLinux-9.4-x86_64-minimal.iso"
    iso_download="https://repo.almalinux.org/almalinux/9.4/isos/x86_64/AlmaLinux-9.4-x86_64-minimal.iso"
    pool_image_download

elif [ "$iso_question" == 4 ];then
    iso_img="openmediavault_7.0-32-amd64.iso"
    iso_download="https://sourceforge.net/projects/openmediavault/files/iso/7.0-32/openmediavault_7.0-32-amd64.iso"
    pool_image_download

elif [ "$iso_question" == 5 ];then
    iso_img="TrueNAS-13.0-U6.1.iso"
    iso_download="https://download-core.sys.truenas.net/13.0/STABLE/U6.1/x64/TrueNAS-13.0-U6.1.iso"
    pool_image_download

else
    # full iso path needed
    echo "Enter the full path to the ISO file (e.g., /var/lib/libvirt/images/debian-12.5.0-amd64-netinst.iso)"
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
<vcpu placement='static'>$new_vcpus</vcpu>
<os>
    <type arch='x86_64' machine='q35'>hvm</type>
    <boot dev='hd'/>
    <boot dev='cdrom'/>
</os>
<features>
    <acpi/>
    <apic/>
    <vmport state='off'/>
</features>
<cpu mode='host-passthrough' check='none' migratable='on'>
    <topology sockets='1' dies='1' cores='$new_vcpus' threads='1'/>
</cpu>
<clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
</clock>
<on_poweroff>destroy</on_poweroff>
<on_reboot>restart</on_reboot>
<on_crash>destroy</on_crash>
<pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
</pm>
<devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
    <driver name='qemu' type='qcow2' cache='none' io='native'/>
    <source file='$disk_path'/>
    <target dev='sdb' bus='sata'/>
    </disk>
    <disk type='file' device='cdrom'>
    <driver name='qemu' type='raw'/>
    <source file='$iso_path'/>
    <target dev='sda' bus='sata'/>
    <readonly/>
    <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='usb' index='0' model='qemu-xhci' ports='15'>
    <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
    </controller>
    <controller type='sata' index='0'>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pcie-root'/>
    <controller type='virtio-serial' index='0'>
    <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
    </controller>
    <controller type='pci' index='1' model='pcie-root-port'>
    <model name='pcie-root-port'/>
    <target chassis='1' port='0x10'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
    </controller>
    <controller type='pci' index='2' model='pcie-root-port'>
    <model name='pcie-root-port'/>
    <target chassis='2' port='0x11'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
    </controller>
    <controller type='pci' index='3' model='pcie-root-port'>
    <model name='pcie-root-port'/>
    <target chassis='3' port='0x12'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
    </controller>
    <controller type='pci' index='4' model='pcie-root-port'>
    <model name='pcie-root-port'/>
    <target chassis='4' port='0x13'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
    </controller>
    <controller type='pci' index='5' model='pcie-root-port'>
    <model name='pcie-root-port'/>
    <target chassis='5' port='0x14'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
    </controller>
    <controller type='pci' index='6' model='pcie-root-port'>
    <model name='pcie-root-port'/>
    <target chassis='6' port='0x15'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
    </controller>
    <controller type='pci' index='7' model='pcie-root-port'>
    <model name='pcie-root-port'/>
    <target chassis='7' port='0x16'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
    </controller>
    <interface type='network'>
    <mac address='$mac_address'/>
    <source network='$network_name'/>
    <model type='e1000'/>
    <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <serial type='pty'>
    <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
    </target>
    </serial>
    <console type='pty'>
    <target type='serial' port='0'/>
    </console>
    <channel type='unix'>
    <target type='virtio' name='org.qemu.guest_agent.0'/>
    <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    <channel type='spicevmc'>
    <target type='virtio' name='com.redhat.spice.0'/>
    <address type='virtio-serial' controller='0' bus='0' port='2'/>
    </channel>
    <input type='tablet' bus='usb'>
    <address type='usb' bus='0' port='1'/>
    </input>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'>
    <listen type='address' address='0.0.0.0'/>
    </graphics>
    <graphics type='spice' autoport='yes' listen='0.0.0.0'>
    <listen type='address' address='0.0.0.0'/>
    <image compression='off'/>
    </graphics>
    <sound model='ich9'>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
    </sound>
    <audio id='1' type='spice'/>
    <video>
    <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
    <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
    </video>
    <redirdev bus='usb' type='spicevmc'>
    <address type='usb' bus='0' port='2'/>
    </redirdev>
    <redirdev bus='usb' type='spicevmc'>
    <address type='usb' bus='0' port='3'/>
    </redirdev>
    <memballoon model='virtio'>
    <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </memballoon>
    <rng model='virtio'>
    <backend model='random'>/dev/urandom</backend>
    <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
    </rng>
</devices>
</domain>"


# Define the path for the new VM XML file
vm_xml_file="/etc/libvirt/qemu/$new_vm_name.xml"

# Save the XML configuration to the file
echo "$vm_xml" > "$vm_xml_file"

# Create the new virtual machine
virsh define "$vm_xml_file"

echo "Please note that there will be a vnc port automatically assigned to this vm."
echo "This is optional if needed and the ports will start at 5900 and onward."
