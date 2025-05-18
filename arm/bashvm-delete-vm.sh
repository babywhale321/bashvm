#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

# Note: This script deletes DHCP reservations, snapshots, disks, and forwarded ports for a VM.

echo "Note: this will delete DHCP reservations, snapshots, disks, and forwarded ports of a VM."

read -ep "Enter the virtual machine you would like to delete: " vm_name


# If the variable is empty, exit the script
if [ -z "$vm_name" ]; then
    echo "Invalid response. Please enter a VM name."
    exit 1
fi

# Check VM state
vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
if [ "$vm_state" == "running" ]; then
    echo "Please shutdown the VM before running this script."
    exit 1
fi

# Get the network name
net_name=$(virsh dumpxml "$vm_name" | grep "source network" | awk -F"'" '{print $2}')
net_name=${net_name:-default} # Default to "default" if empty

# Get the bridge name
int_name=$(virsh net-dumpxml "$net_name" 2>/dev/null | grep "bridge name" | awk -F"'" '{print $2}')
int_name=${int_name:-virbr0} # Default to "virbr0" if empty

# Database file and table name
db_file="bashvm.db"
net_table="${net_name}_table"

# Function to delete a VM's database entry
delete_db_entry() {
    
    resource=$(sqlite3 "$db_file" "SELECT ipv4, ssh_port, start_port, end_port FROM $net_table WHERE vm_name = '$vm_name';")

    if [ -z "$resource" ]; then
        echo "No database entry found for the VM. Skipping database deletion."    
        return
    fi

    sqlite3 "$db_file" "DELETE FROM $net_table WHERE vm_name = '$vm_name';"
    if [ $? -eq 0 ]; then
        echo "Database entry deleted." 
    else
        echo "Failed to delete database entry."
    fi
    
}

# Function to delete the VM and related resources
delete_vm() {
    echo "Removing DHCP reservation..."
    vm_mac=$(virsh net-dumpxml "$net_name" 2>/dev/null | grep "$vm_name" | head -n 1 | awk '{print $2}' | cut -d"'" -f2)
    vm_ip=$(virsh net-dumpxml "$net_name" 2>/dev/null | grep "$vm_name" | head -n 1 | awk '{print $4}' | cut -d"'" -f2)

    if [ -n "$vm_mac" ] && [ -n "$vm_ip" ]; then
        virsh net-update "$net_name" delete ip-dhcp-host "<host mac='$vm_mac' name='$vm_name' ip='$vm_ip' />" --live --config
        if [ $? -eq 0 ]; then
            echo "DHCP reservation removed."
        else
            echo "Failed to remove DHCP reservation."
        fi
    else
        echo "No DHCP reservation found for the VM. Skipping."
    fi
    
    # Detach a disk from a VM
    detach_disk=$(virsh dumpxml "$vm_name" | grep "cdrom" -A 6 | grep "source file" | cut -d"'" -f2)

    if [ -z "$detach_disk" ]; then
        echo "No cdrom disk detected. Skipping."
    else
        virsh detach-disk "$vm_name" "$detach_disk" --current
    fi
    
    echo "Removing Virtual Disk..."
    virsh undefine --nvram "$vm_name" --remove-all-storage --snapshots-metadata
    
    
    #Check if port forwarding rules exist
    check_port_rules=$(cat /etc/libvirt/hooks/qemu | grep -x "#$vm_name#")

    if [ -z "$check_port_rules" ]; then
        echo "No port forwarding rules detected. Skipping."
    else
        # Port forwarding removal
        sed -i "/#$vm_name#/,/###$vm_name###/d" /etc/libvirt/hooks/qemu
        echo "Port forwarding rules have been deleted."
    fi

}

# Confirm the record exists before attempting database deletion
record_count=$(sqlite3 "$db_file" "SELECT COUNT(*) FROM $net_table WHERE vm_name = '$vm_name';" 2>/dev/null)
if [ ! -z "$record_count" ]; then
    delete_db_entry
else
    echo "No database entry exists for the VM. Skipping database operations."
fi

delete_vm

echo "VM deletion process completed."
