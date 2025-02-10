#!/bin/bash

# Configurable Database Variables
db_file="bashvm.db" # SQLite database file

# Get the list of all tables
tables=$(sqlite3 "$db_file" "SELECT name FROM sqlite_master WHERE type='table';")

# Iterate over each table and select all data
for table in $tables; do
    echo "table: $table"
    # Format table data
    sqlite3 -header "$db_file" ".mode column" "SELECT * FROM $table;"
    echo ""
done
