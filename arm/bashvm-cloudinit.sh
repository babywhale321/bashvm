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
#echo "2 = ubuntu22.04"
#echo "3 = almalinux9"
read -ep "Enter the OS you would like (e.g., 1): " qcow2_question

if [ "$qcow2_question" == 1 ];then
    qcow2_image="debian-12-generic-arm64.qcow2"
    qcow2_download="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-arm64.qcow2"
    os_info="debian11"
    
#elif [ "$qcow2_question" == 2 ];then
#    qcow2_image="ubuntu-22.04-minimal-cloudimg-amd64.img"
#    qcow2_download="https://cloud-images.ubuntu.com/minimal/releases/jammy/release/ubuntu-22.04-minimal-cloudimg-amd64.img"
#    os_info="ubuntu22.04"

#elif [ "$qcow2_question" == 3 ];then
#    qcow2_image="AlmaLinux-8-GenericCloud-latest.aarch64.qcow2"
#    qcow2_download="https://raw.repo.almalinux.org/almalinux/8/cloud/aarch64/images/AlmaLinux-8-GenericCloud-latest.aarch64.qcow2"
#    os_info="almalinux9"
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

vm_net="default"

log_file="/var/log/bashvm/used_ip.log"

# Create log file if it doesn't exist
if [ -f $log_file ];then
ip_address=$(tail -n 1 "$log_file")
# Value to add
increment=1
else
mkdir /var/log/bashvm
chmod 600 -R /var/log/bashvm
touch $log_file
chmod 600 $log_file
ip_address="192.168.122.1"
# Value to add
increment=1
fi

# Check to see if there is an unused ip
unused_ip_log="/var/log/bashvm/unused_ip.log"
if [ -f $unused_ip_log ];then
unused_ip=$(tail -n 1 /var/log/bashvm/unused_ip.log)
    if [ ! -z "$unused_ip" ];then
        #unused ip will become the ip
        ip_address=$unused_ip
        increment=0
        # Remove unused ip from unused log file
        sed -i '/'"$unused_ip"'/d' /var/log/bashvm/unused_ip.log
    fi
fi

# Extract the last octet
last_octet="${ip_address##*.}"

# Increment the last octet
((last_octet += increment))

# Construct the new IP address
vm_ip="${ip_address%.*}.$last_octet"

echo "$vm_ip" >> "$log_file"

# Sort the IP address in the log file
sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n "$log_file" > "$log_file.sort"

# Rename sorted log file
mv "$log_file.sort" "$log_file"

echo "Setting DHCP reservation..."

virsh net-update $vm_net add ip-dhcp-host "<host mac='$vm_mac' name='$vm_name' ip='$vm_ip' />" --live --config

if [ ! $? == 0 ]; then
echo "Failed to set DHCP reservation in $vm_net"
echo "Check to see if the ip or vm already exists in $vm_net"
exit
fi

# -----------------port forwarding ---------------------

echo "Setting Port Forwarding..."

int_name="virbr0"

log_file="/var/log/bashvm/used_ports.log"
unused_port_log="/var/log/bashvm/unused_ports.log"

# Create log file if it doesn't exist
if [ -f $log_file ];then
# The startport will the end of the file output
start_port=$(tail -n 1 "$log_file")

# Create log file
else
touch $log_file
chmod 600 $log_file
start_port=49153
fi

# Check to see if there is an unused port
if [ -f $unused_port_log ];then
unused_port=$(tail -n 1 /var/log/bashvm/unused_ports.log)

    if [ ! -z "$unused_port" ];then
        
        #unused port will become the port
        start_port=$(($unused_port - 22))
        # Remove unused port from unused log file
        sed -i '/'"$unused_port"'/d' /var/log/bashvm/unused_ports.log
    fi
    
fi

# Add a range of 20 ports
end_port=$(($start_port + 20))

# Reserve for next block calculation
echo $(($end_port + 2)) >> $log_file

# Sort then rename
sort -n "$log_file" > "$log_file".sort
mv "$log_file.sort" "$log_file"

echo "#!/bin/bash" >> /etc/libvirt/hooks/qemu

# Identifier for deleting if needed
echo "#$vm_name#" >> /etc/libvirt/hooks/qemu            

# Keep out of loop
nat_script=' 
if [ "${1}" = "'$vm_name'" ]; then

    if [ "${2}" = "stopped" ] || [ "${2}" = "reconnect" ]; then'

echo "$nat_script" >> /etc/libvirt/hooks/qemu

# Reserve a port for SSH
ssh_port=$(($start_port - 1))
echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '"$vm_ip"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '"$vm_ip"':22' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -D FORWARD -o '$int_name' -p udp -d '"$vm_ip"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p udp --dport '$ssh_port' -j DNAT --to '"$vm_ip"':22' >> /etc/libvirt/hooks/qemu
# Port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '"$vm_ip"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$port' -j DNAT --to '"$vm_ip"':'$port'' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -D FORWARD -o '$int_name' -p udp -d '"$vm_ip"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p udp --dport '$port' -j DNAT --to '"$vm_ip"':'$port'' >> /etc/libvirt/hooks/qemu
done

# Keep out of loop
middle_script='    fi
    if [ "${2}" = "start" ] || [ "${2}" = "reconnect" ]; then'
echo "$middle_script" >> /etc/libvirt/hooks/qemu

# Reserve for SSH
echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '"$vm_ip"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '"$vm_ip"':22' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -I FORWARD -o '$int_name' -p udp -d '"$vm_ip"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p udp --dport '$ssh_port' -j DNAT --to '"$vm_ip"':22' >> /etc/libvirt/hooks/qemu
# port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '"$vm_ip"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$port' -j DNAT --to '"$vm_ip"':'$port'' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -I FORWARD -o '$int_name' -p udp -d '"$vm_ip"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p udp --dport '$port' -j DNAT --to '"$vm_ip"':'$port'' >> /etc/libvirt/hooks/qemu
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
echo "========== Info for $vm_name ==========" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "IPv4: $vm_ip" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "SSH port: $ssh_port" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "Ports: $start_port to $end_port" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "Username: $user_name" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "Password: $user_pass" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "====================================================" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo ""
chmod 600 /var/log/bashvm/"$vm_name".info.txt
echo "Info for $vm_name has been saved to /var/log/bashvm/$vm_name.info.txt"
echo "You can access the VM with the console option."
