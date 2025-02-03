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


read -ep "Enter the IP of the VM (e.g., 192.168.122.2): " ipv4
read -ep "Enter the start port range (e.g., 1024): " start_port
read -ep "Enter the ending port (e.g., 1048): " end_port

# Validate inputs
if [[ ! "$ipv4" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid IP address format."
    exit 1
fi

if [[ ! "$start_port" =~ ^[0-9]+$ ]] || [[ ! "$end_port" =~ ^[0-9]+$ ]]; then
    echo "Ports must be numeric."
    exit 1
fi

if [[ "$start_port" -gt "$end_port" ]]; then
    echo "Start port must be less than or equal to end port."
    exit 1
fi

# Database setup
db_file="bashvm.db"
net_table=""$net_name"_table"
# Port starting variables
ssh_port="$start_port"
start_port=$(($ssh_port + 1))

# Create SQLite database and table if they don't exist
create_net_table="CREATE TABLE IF NOT EXISTS $net_table (
    vm_name TEXT PRIMARY KEY,
    ipv4 TEXT UNIQUE NOT NULL,
    ssh_port INTEGER,
    start_port INTEGER,
    end_port INTEGER
);"

# Function to initialize the database
initialize_db() {
    sqlite3 "$db_file" <<< "$create_net_table"
}

# Initialize database
initialize_db

# Check if ipv4 exists in the database
exists=$(sqlite3 "$db_file" "SELECT EXISTS(SELECT 1 FROM "$net_table" WHERE ipv4='$ipv4');")

# Verify the result
if [[ "$exists" -eq 1 ]]; then
    echo "The ipv4 '$ipv4' already exists in the database."
    exit 1
fi

# Get the highest end_port from the database
highest_end_port=$(sqlite3 "$db_file" \
    "SELECT MAX(end_port) FROM $net_table;")

# Check if the highest_end_port is valid (not NULL)
if [[ -z "$highest_end_port" || "$highest_end_port" == "NULL" ]]; then
    echo "No existing entries in the database. Proceeding."
else
    # Compare user input with the highest_end_port
    if (( ssh_port <= highest_end_port || start_port <= highest_end_port || end_port <= highest_end_port )); then
        echo "Error: ssh_port, start_port and end_port must be higher than the highest end_port in the database ($highest_end_port)."
        exit 1
    fi
fi

# Insert data into the SQLite database
sqlite3 $db_file <<EOF
INSERT INTO $net_table (vm_name, ipv4, ssh_port, start_port, end_port)
VALUES ("$vm_name", "$ipv4", "$ssh_port", "$start_port", "$end_port");
EOF

echo "#!/bin/bash" >> /etc/libvirt/hooks/qemu

# Identifier for deleting if needed
echo "#$vm_name#" >> /etc/libvirt/hooks/qemu            

# Keep out of loop
nat_script=' 
if [ "${1}" = "'$vm_name'" ]; then

    if [ "${2}" = "stopped" ] || [ "${2}" = "reconnect" ]; then'

echo "$nat_script" >> /etc/libvirt/hooks/qemu

# Reserve a port for SSH
echo '      /sbin/iptables -D FORWARD -o '"$int_name"' -p tcp -d '"$ipv4"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '"$ipv4"':22' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -D FORWARD -o '"$int_name"' -p udp -d '"$ipv4"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p udp --dport '$ssh_port' -j DNAT --to '"$ipv4"':22' >> /etc/libvirt/hooks/qemu

# Port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -D FORWARD -o '"$int_name"' -p tcp -d '"$ipv4"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$port' -j DNAT --to '"$ipv4"':'$port'' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -D FORWARD -o '"$int_name"' -p udp -d '"$ipv4"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p udp --dport '$port' -j DNAT --to '"$ipv4"':'$port'' >> /etc/libvirt/hooks/qemu
done

# Keep out of loop
middle_script='    fi
    if [ "${2}" = "start" ] || [ "${2}" = "reconnect" ]; then'
echo "$middle_script" >> /etc/libvirt/hooks/qemu

# Reserve for SSH
echo '      /sbin/iptables -I FORWARD -o '"$int_name"' -p tcp -d '"$ipv4"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '"$ipv4"':22' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -I FORWARD -o '"$int_name"' -p udp -d '"$ipv4"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p udp --dport '$ssh_port' -j DNAT --to '"$ipv4"':22' >> /etc/libvirt/hooks/qemu
# port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -I FORWARD -o '"$int_name"' -p tcp -d '"$ipv4"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$port' -j DNAT --to '"$ipv4"':'$port'' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -I FORWARD -o '"$int_name"' -p udp -d '"$ipv4"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p udp --dport '$port' -j DNAT --to '"$ipv4"':'$port'' >> /etc/libvirt/hooks/qemu
done

# Keep out of loop
last_script='    fi
fi'
echo "$last_script" >> /etc/libvirt/hooks/qemu

# End Identifier
echo "###$vm_name###" >> /etc/libvirt/hooks/qemu

# libvirt needs the file to be executable
chmod +x /etc/libvirt/hooks/qemu

# Check to see if other virtual machines are running.
vm_on=$(virsh list --all | grep -E '^\s+[0-9]+' | wc -l)

# If only 1 then restart libvirtd
if [ "$vm_on" == 1 ]; then
systemctl restart libvirtd
fi

echo ""
echo "========== Info for $vm_name ==========" 
echo "" 
echo "SSH port: $ssh_port" 
echo "Ports: $start_port to $end_port" 
echo "" 
echo "====================================================" 
echo ""
echo "You will need to stop then start the vm for the changes to take effect"
