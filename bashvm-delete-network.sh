#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

read -ep "Enter the name of the network to delete: " delete_network_name
read -ep "Would you also like to delete the sqlite table and data of the network specified? (y/n): " delete_table_question

lowercase_input=$(echo "$delete_table_question" | tr '[:upper:]' '[:lower:]')
if [[ "$lowercase_input" == y || "$lowercase_input" == ye || "$lowercase_input" == yes ]];then

    db_file="bashvm.db"
    table_name=""$delete_network_name"_table"

    # Check if table exists
    exists=$(sqlite3 "$db_file" "SELECT name FROM sqlite_master WHERE type='table' AND name='$table_name';")

    # Remove table if it exists
    if [ -n "$exists" ]; then
        sqlite3 "$db_file" "DROP TABLE $table_name;"
        echo "Table '$table_name' has been removed."
    fi
fi

virsh net-destroy "$delete_network_name"
virsh net-undefine "$delete_network_name"