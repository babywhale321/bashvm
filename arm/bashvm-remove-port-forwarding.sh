#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

# Prompt user for VM details
read -ep "Enter the VM name: " vm_name

# If the variable is empty then don't continue
if [ -z "$vm_name" ]; then
    echo "Invalid response. Please enter a VM name."
    exit
fi

# Get the network name
net_name=$(virsh dumpxml "$vm_name" | grep "source network" | awk -F"'" '{print $2}')
if [[ -z "$net_name" ]]; then
    net_name="default"
fi
# Get the bridge name
int_name=$(virsh net-dumpxml "$net_name" | grep "bridge name" | awk -F"'" '{print $2}')
if [[ -z "$int_name" ]]; then    
    int_name="virbr0"
fi

# Database file and table name
db_file="bashvm.db"
net_table=""$net_name"_table"

# Check if the database exists
if [ ! -f "$db_file" ]; then
    echo "Database file '$db_file' does not exist. Nothing to delete."
    exit
fi

# Confirm the record exists before deleting
vm_exists=$(sqlite3 "$db_file" "SELECT EXISTS(SELECT 1 FROM "$net_table" WHERE vm_name='$vm_name');")

# Verify the result
if [[ "$vm_exists" -eq 0 ]]; then
    echo "No record found for VM name '$vm_name' in the database."
    exit
fi

# Check if there are rules present in the hook file
vm_hook=$(cat /etc/libvirt/hooks/qemu | grep "$vm_name")
if [ -z "$vm_hook" ]; then
    echo "No record found for VM name '$vm_name' in the hook file. ( /etc/libvirt/hooks/qemu )"
    exit
fi

# Delete the record
sqlite3 $db_file <<EOF
DELETE FROM $net_table WHERE vm_name = "$vm_name";
EOF

# Port forwarding removal
sed -i "/#$vm_name#/,/###$vm_name###/d" /etc/libvirt/hooks/qemu
echo ""
echo "Port forwarding rules for $vm_name has been deleted."

# Confirm deletion
echo "Record for VM name '$vm_name' has been deleted from the database."
