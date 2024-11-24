#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

echo "Note: this will delete dhcpv4 reservation, snapshots, disks and forwarded ports of a vm."
read -ep "Enter the virtual machine you would like to delete: " vm_name

vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
if [ "$vm_state" == "running" ];then
    echo "Please shutdown the vm before running this again"
    exit
fi

# Database variables
db_file="bashvm.db"              
net_table="default_table"        
net_name="default"             

# Function to delete a VM
delete_vm() {
    resource=$(sqlite3 "$db_file" <<EOF
SELECT ipv4, ssh_port, start_port, end_port FROM $net_table WHERE vm_name = '$vm_name';
EOF
    )

    if [ -z "$resource" ]; then
        echo "VM not found: $vm_name"
        exit
    fi

    sqlite3 "$db_file" <<EOF
DELETE FROM $net_table WHERE vm_name = '$vm_name';
EOF

    if [ $? -eq 0 ]; then
        ipv4=$(echo "$resource" | cut -d'|' -f1)
        ssh_port=$(echo "$resource" | cut -d'|' -f2)
        start_port=$(echo "$resource" | cut -d'|' -f3)
        end_port=$(echo "$resource" | cut -d'|' -f4)
    else
        echo "Error deleting VM: $vm_name"
    fi
}

# Network
echo ""
echo "Removing DHCP reservation..."
vm_mac=$(virsh net-dumpxml "$net_name" | grep "$vm_name" | head -n 1 | awk '{print $2}' | cut -d"'" -f2)
vm_ip=$(virsh net-dumpxml "$net_name" | grep "$vm_name" | head -n 1 | awk '{print $4}' | cut -d"'" -f2)
virsh net-update "$net_name" delete ip-dhcp-host "<host mac='$vm_mac' name='$vm_name' ip='$vm_ip' />" --live --config
if [ ! $? == 0 ]; then
echo "Failed to remove DHCP reservation."
exit
fi

# Disk
echo ""
echo "Removing Disk..."
virsh undefine "$vm_name" --remove-all-storage --snapshots-metadata
if [ ! $? == 0 ]; then
echo "Failed to remove disk."
exit
fi

# Database
echo ""
echo "Remove from database..."
delete_vm

# Ports
echo ""
echo "Removing Ports..."

# Port forwarding removal
sed -i "/#$vm_name#/,/###$vm_name###/d" /etc/libvirt/hooks/qemu
echo ""
echo "$vm_name has been deleted"