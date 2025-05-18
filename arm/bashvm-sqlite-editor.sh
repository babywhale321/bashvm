#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

db_name="bashvm.db"

# What network to use with validation
while true; do
    read -ep "Enter the network name to edit [default]: " net_name
    if [ -z "$net_name" ]; then
        net_name="default"
    fi

    net_list=$(virsh net-list --all | grep "$net_name" | awk '{print $1}')
    if [ -z "$net_list" ]; then
        echo "Please enter a valid network, The network "$net_name" was not found."
        continue
    fi
    
    table_name=""$net_name"_table"
    break
done

# Create table if not exists
sqlite3 "$db_name" <<EOF
CREATE TABLE IF NOT EXISTS $table_name (
    vm_name TEXT PRIMARY KEY,
    ipv4 TEXT UNIQUE NOT NULL,
    ssh_port INTEGER,
    start_port INTEGER,
    end_port INTEGER
);
EOF

# Validation functions
validate_ipv4() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    echo "Invalid IPv4 format! Use xxx.xxx.xxx.xxx"
    return 1
}

validate_integer() {
    local value=$1
    if [[ -n "$value" && ! "$value" =~ ^[0-9]+$ ]]; then
        echo "Invalid integer value!"
        return 1
    fi
    return 0
}

# Add VM with validation
add_vm() {
    echo "Adding new VM entry:"
    while true; do
        read -ep "VM Name: " vm_name
        if [ -z "$vm_name" ]; then
            echo "VM Name cannot be empty!"
            continue
        fi
        break
    done

    while true; do
        read -ep "IPv4 Address: " ipv4
        if [ -z "$ipv4" ]; then
            echo "IPv4 cannot be null!"
            continue
        fi
        validate_ipv4 "$ipv4" && break
    done

    read -ep "SSH Port (press Enter for NULL): " ssh_port
    validate_integer "$ssh_port" || return

    read -ep "Start Port (press Enter for NULL): " start_port
    validate_integer "$start_port" || return

    read -ep "End Port (press Enter for NULL): " end_port
    validate_integer "$end_port" || return

    sqlite3 "$db_name" <<EOF
INSERT INTO $table_name VALUES (
    '$vm_name',
    '$ipv4',
    ${ssh_port:-NULL},
    ${start_port:-NULL},
    ${end_port:-NULL}
);
EOF
    echo "VM entry added successfully!"
}

# Delete VM with existence check
delete_vm() {
    read -ep "Enter VM Name to delete: " vm_name
    exists=$(sqlite3 "$db_name" "SELECT COUNT(*) FROM $table_name WHERE vm_name='$vm_name';")
    if [ "$exists" -eq 0 ]; then
        echo "VM $vm_name does not exist!"
        return
    fi
    sqlite3 "$db_name" "DELETE FROM $table_name WHERE vm_name='$vm_name';"
    echo "VM entry deleted successfully!"
}

# Update VM with validation
update_vm() {
    echo "Update VM entry:"
    read -ep "Enter VM Name to update: " vm_name
    exists=$(sqlite3 "$db_name" "SELECT COUNT(*) FROM $table_name WHERE vm_name='$vm_name';")
    if [ "$exists" -eq 0 ]; then
        echo "VM $vm_name does not exist!"
        return
    fi

    echo "Select field to update:"
    echo "1. IPv4 Address  2. SSH Port"
    echo "3. Start Port    4. End Port"
    read -ep "Enter choice [1-4]: " field

    case $field in
        1)
            column="ipv4"
            while true; do
                read -ep "Enter new IPv4 address: " new_value
                if [ -z "$new_value" ]; then
                    echo "Error: IPv4 cannot be null!"
                    continue
                fi
                validate_ipv4 "$new_value" && break
            done
            sql_value="'$new_value'"
            ;;
        2|3|4)
            case $field in
                2) column="ssh_port";;
                3) column="start_port";;
                4) column="end_port";;
            esac
            
            while true; do
                read -ep "Enter new value for $column (press Enter for NULL): " new_value
                validate_integer "$new_value" && break
            done
            
            if [ -z "$new_value" ]; then
                sql_value="NULL"
            else
                sql_value="$new_value"
            fi
            ;;
        *)
            echo "Invalid option"
            return
            ;;
    esac

    sqlite3 "$db_name" "UPDATE $table_name SET $column=$sql_value WHERE vm_name='$vm_name';"
    echo "VM entry updated successfully!"
}

# View all entries with formatting
view_vms() {
    echo ""
    echo "========================== "$table_name" =========================="
    sqlite3 -column -header "$db_name" <<EOF
SELECT vm_name as 'VM Name',
       ipv4 as 'IPv4 Address',
       ssh_port as 'SSH Port',
       start_port as 'Start Port',
       end_port as 'End Port'
FROM $table_name
ORDER BY vm_name;
EOF
}

# Delete current table
delete_table() {
    exists=$(sqlite3 "$db_name" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='$table_name';")
    if [ "$exists" -eq 0 ]; then
        echo "Table $table_name does not exist."
        return
    fi

    read -ep "Are you sure you want to delete the entire table $table_name? This cannot be undone! (y/n): " confirm
    lowercase_input=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
    if [[ "$lowercase_input" == y || "$lowercase_input" == ye || "$lowercase_input" == yes ]];then
        sqlite3 "$db_name" "DROP TABLE $table_name;"
        echo "Table $table_name deleted successfully."
        exit
    else
        echo "Deletion cancelled."
        return
    fi
}

# Main menu
while true; do
    echo ""
    echo "============================ SQLite Editor Menu ============================"
    echo "s. View all entries  1. Add new VM entry      2. Delete VM entry"
    echo "3. Update VM entry   4. Delete current table  q. Exit"
    echo ""
    read -ep "Enter your choice: " choice

    case $choice in
        s) view_vms ;;
        1) add_vm ;;
        2) delete_vm ;;
        3) update_vm ;;
        4) delete_table ;;
        q) exit ;;
        *) echo "Invalid option. Please try again." ;;
    esac
done
