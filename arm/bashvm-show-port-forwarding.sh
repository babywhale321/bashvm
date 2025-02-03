#!/bin/bash

# Configurable Database Variables
db_file="bashvm.db" # SQLite database file

# Get the list of all tables
tables=$(sqlite3 "$db_file" "SELECT name FROM sqlite_master WHERE type='table';")

# Iterate over each table and select all data
for table in $tables; do
    echo "table: $table"
    # Fetch and format table data
    sqlite3 -header -csv "$db_file" "SELECT * FROM $table;" | \
    awk -F',' 'BEGIN {OFS="\t"} {printf "%-10s %-15s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5}'
    echo ""
done
