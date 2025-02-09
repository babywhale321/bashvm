#!/bin/bash

# Configurable Database Variables
db_file="bashvm.db" # SQLite database file

# Get the list of all tables
tables=$(sqlite3 "$db_file" "SELECT name FROM sqlite_master WHERE type='table';")

# Iterate over each table and select all data
for table in $tables; do
    echo "table: $table"
    # Fetch and format table data with dynamic column spacing
    sqlite3 -header -csv "$db_file" "SELECT * FROM $table;" | column -s, -t
    echo ""
done
