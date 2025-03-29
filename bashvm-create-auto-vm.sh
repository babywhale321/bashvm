#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

read -ep "Enter the hostname of the VM (e.g., test-vm): " vm_name
read -ep "Enter the amount of memory in MB (e.g., 1024): " vm_memory
read -ep "Enter the number of virtual CPUs (e.g., 2): " vm_vcpus
read -ep "Enter the amount of disk space in GB (e.g., 50): " vm_disk
read -ep "Enter the username for the new VM (e.g., joe): " user_name
read -ep "Enter the password for the new VM (e.g., password): " user_pass
echo "1 = debian12"
echo "2 = ubuntu22.04"
echo "3 = almalinux9"
echo "4 = opensuse15.6"
read -ep "Enter the OS you would like (e.g., 1): " qcow2_question

if [ "$qcow2_question" == 1 ];then
    qcow2_image="debian-12-generic-amd64.qcow2"
    qcow2_download="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
    os_info="debian11"
    
elif [ "$qcow2_question" == 2 ];then
    qcow2_image="ubuntu-22.04-minimal-cloudimg-amd64.img"
    qcow2_download="https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img"
    os_info="ubuntu22.04"

elif [ "$qcow2_question" == 3 ];then
    qcow2_image="AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
    qcow2_download="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"
    os_info="almalinux9"

elif [ "$qcow2_question" == 4 ];then
    qcow2_image="openSUSE-Leap-15.6.x86_64-NoCloud.qcow2"
    qcow2_download="https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.6/images/openSUSE-Leap-15.6.x86_64-NoCloud.qcow2"
    os_info="opensuse15.4"

else
    echo "Error: Please select a valid response."
    exit
fi

echo "#cloud-config

# hostname
hostname: '$vm_name'
locale: en_US.UTF-8

# disable ssh access as root.
disable_root: true

# ssh with password enabled
ssh_pwauth: true

# users
users:
  - name: '$user_name'
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, adm
    shell: /bin/bash
    lock_passwd: false
    plain_text_passwd: '$user_pass'

# list of packages to install after the VM is up
packages:
  - qemu-guest-agent

# shutdown system for port forwarding to work
runcmd:
  - shutdown -P 0

# output to /var/log/cloud-init-output.log
final_message: "The system is up, after "$UPTIME" seconds"
" > bashvm-cloudinit.yaml

# Copy cloudinit file to default location
mv bashvm-cloudinit.yaml /var/lib/libvirt/images

echo ""
echo "Starting download of cloud image..."

# Check to see if the qcow2 file is there
if [ -f "/var/lib/libvirt/images/$qcow2_image" ]; then
    # Dont download
    echo "File $qcow2_image already there. Canceling re-download..."
else
    # Download
    wget $qcow2_download
    mv $qcow2_image /var/lib/libvirt/images/$qcow2_image
fi

virsh net-info default | grep "Active:" | grep "yes" >> /dev/null
if [ ! $? == 0 ]; then
#start default
virsh net-start default
# Enable autostart of default network
virsh net-autostart default
fi

shebang=$(cat /etc/libvirt/hooks/qemu 2>/dev/null | grep '#!/bin/bash')

if [ -z "$shebang" ]; then
    echo "#!/bin/bash" >> /etc/libvirt/hooks/qemu
    chmod +x /etc/libvirt/hooks/qemu
fi

# Deploy the new VM
virt-install --name "$vm_name" --memory "$vm_memory" --vcpus "$vm_vcpus" --disk=size="$vm_disk",backing_store=/var/lib/libvirt/images/$qcow2_image --cloud-init user-data=/var/lib/libvirt/images/bashvm-cloudinit.yaml,disable=on --network bridge=virbr0 --osinfo=$os_info --noautoconsole

if [ ! $? == 0 ]; then
echo "Please see the errors above for possible solutions"
exit
fi

# Cleanup
rm /var/lib/libvirt/images/bashvm-cloudinit.yaml

# -----------------dhcp reservation ---------------------

while true; do
  vm_mac=$(virsh domiflist "$vm_name" | grep virtio | awk '{print $5}')

  if [ -z "$vm_mac" ]; then
  echo "Waiting for vm to set a DHCP reservation. Please wait..."
  sleep 5

  else

    break
  fi
    continue

done

# Database Variables
db_file="bashvm.db"
net_table="default_table"

# SQL Queries
create_net_table="CREATE TABLE IF NOT EXISTS $net_table (
    vm_name TEXT PRIMARY KEY,
    ipv4 TEXT UNIQUE NOT NULL,
    ssh_port INTEGER,
    start_port INTEGER,
    end_port INTEGER
);"

get_highest_assigned_port="SELECT MAX(end_port) FROM $net_table;"

# Resource Values
default_ipv4_prefix="192.168.122." # Base IPv4 prefix for auto-generation
default_start_port=49152           # Default starting port for new ranges
port_range_size=21                 # Port range size for each VM
reserved_ipv4=(0 1 255)            # Reserved IPs for the last octet
vm_net="default"                   # Default network name

# Function to initialize the database
initialize_db() {
    sqlite3 "$db_file" <<< "$create_net_table"
}

# Function to generate a unique IPv4 address
generate_unique_ipv4() {
    while :; do
        last_octet=$((RANDOM % 256))
        if [[ " ${reserved_ipv4[@]} " =~ " $last_octet " ]]; then
            continue
        fi
        ipv4="${default_ipv4_prefix}${last_octet}"
        ip_exists=$(sqlite3 "$db_file" "SELECT COUNT(*) FROM $net_table WHERE ipv4 = '$ipv4';")
        if [ "$ip_exists" -eq 0 ]; then
            echo "$ipv4"
            return
        fi
    done
}

# Function to generate a new unique port range
generate_new_port_range() {
    highest_port=$(sqlite3 "$db_file" <<< "$get_highest_assigned_port")
    if [ -z "$highest_port" ]; then
        highest_port=$default_start_port
    else
        highest_port=$((highest_port + 1))
    fi

    ssh_port=$highest_port
    start_port=$((ssh_port + 1))
    end_port=$((start_port + port_range_size - 2))
    echo "$ssh_port|$start_port|$end_port"
}

# Function to add a VM, reusing IPs and ports if available
add_vm() {
    ipv4=$(generate_unique_ipv4)
    port_range=$(generate_new_port_range)
    ssh_port=$(echo "$port_range" | cut -d'|' -f1)
    start_port=$(echo "$port_range" | cut -d'|' -f2)
    end_port=$(echo "$port_range" | cut -d'|' -f3)
    
    sqlite3 "$db_file" <<EOF
INSERT INTO $net_table (vm_name, ipv4, ssh_port, start_port, end_port)
VALUES ('$vm_name', '$ipv4', $ssh_port, $start_port, $end_port);
EOF

    if [ ! $? -eq 0 ]; then
        echo "Error adding VM. Ensure the VM name and IP are unique."
    fi
}

# Main Script
initialize_db
add_vm

echo "Setting DHCP reservation..."

virsh net-update $vm_net add ip-dhcp-host "<host mac='$vm_mac' name='$vm_name' ip='$ipv4' />" --live --config

if [ ! $? == 0 ]; then
    echo "Failed to set DHCP reservation in $vm_net"
    echo "Check to see if the ip or vm already exists in $vm_net"
    exit
fi

# -----------------port forwarding ---------------------

echo "Setting Port Forwarding..."

int_name="virbr0"

# Identifier for deleting if needed
echo "#$vm_name#" >> /etc/libvirt/hooks/qemu            

# Keep out of loop
nat_script=' 
if [ "${1}" = "'$vm_name'" ]; then

    if [ "${2}" = "stopped" ] || [ "${2}" = "reconnect" ]; then'

echo "$nat_script" >> /etc/libvirt/hooks/qemu

# Reserve a port for SSH
echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '"$ipv4"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '"$ipv4"':22' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -D FORWARD -o '$int_name' -p udp -d '"$ipv4"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p udp --dport '$ssh_port' -j DNAT --to '"$ipv4"':22' >> /etc/libvirt/hooks/qemu
# Port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '"$ipv4"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$port' -j DNAT --to '"$ipv4"':'$port'' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -D FORWARD -o '$int_name' -p udp -d '"$ipv4"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p udp --dport '$port' -j DNAT --to '"$ipv4"':'$port'' >> /etc/libvirt/hooks/qemu
done

# Keep out of loop
middle_script='    fi
    if [ "${2}" = "start" ] || [ "${2}" = "reconnect" ]; then'
echo "$middle_script" >> /etc/libvirt/hooks/qemu

# Reserve for SSH
echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '"$ipv4"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '"$ipv4"':22' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -I FORWARD -o '$int_name' -p udp -d '"$ipv4"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p udp --dport '$ssh_port' -j DNAT --to '"$ipv4"':22' >> /etc/libvirt/hooks/qemu
# port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '"$ipv4"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$port' -j DNAT --to '"$ipv4"':'$port'' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -I FORWARD -o '$int_name' -p udp -d '"$ipv4"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
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
echo "IPv4: $ipv4" 
echo "SSH port: $ssh_port" 
echo "Ports: $start_port to $end_port" 
echo "Username: $user_name" 
echo "Password: $user_pass" 
echo "" 
echo "====================================================" 
echo ""
echo "You can access the VM with the console option."
