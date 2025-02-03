#!/bin/bash

# Prompt user for VM details
read -ep "Enter the VM name: " vm_name

# If the variable is empty then don't continue
if [ -z "$vm_name" ]; then
    echo "Invalid response. Please enter a VM name."
    exit 1
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
    exit 1
fi

# Confirm the record exists before deleting
record_count=$(sqlite3 $db_file "SELECT COUNT(*) FROM $net_table WHERE vm_name = '$vm_name';")

if [ -z "$record_count" ]; then
    echo "No record found for VM name '$vm_name'."
    exit 1
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
