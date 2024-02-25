#!/bin/bash

read -ep "Enter the hostname of the new VM: " vm_name
read -ep "Enter the username for the new VM: " user_name
read -ep "Enter the password for the new VM: " user_pass

cp bashvm-cloudinit.yaml bashvm-cloudinit.yaml.backup

sed -i "s/default-vm/$vm_name/g" bashvm-cloudinit.yaml
sed -i "s/bashvm/$user_name/g" bashvm-cloudinit.yaml
sed -i "s/password/$user_pass/g" bashvm-cloudinit.yaml

# Copy cloudinit file to default location
cp bashvm-cloudinit.yaml /var/lib/libvirt/images
cp bashvm-cloudinit.yaml.backup bashvm-cloudinit.yaml
rm bashvm-cloudinit.yaml.backup

echo ""
echo "Starting download of debian 12 cloud image..."
# Check to see if the qcow2 file is there
if [ -f "/var/lib/libvirt/images/debian-12-generic-amd64.qcow2" ]; then
    # Dont download
    echo "File debian-12-generic-amd64.qcow2 already there. Canceling re-download..."
else
    # Download
    wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
    mv debian-12-generic-amd64.qcow2 /var/lib/libvirt/images/debian-12-generic-amd64.qcow2
fi

virsh net-info default | grep "Active:" | grep "yes" >> /dev/null
if [ ! $? == 0 ]; then
#start default
virsh net-start default
# Enable autostart of default network
virsh net-autostart default
fi


# Deploy the new VM
virt-install --name $vm_name --memory 2048 --vcpus 2 --disk=size=20,backing_store=/var/lib/libvirt/images/debian-12-generic-amd64.qcow2 --cloud-init user-data=/var/lib/libvirt/images/bashvm-cloudinit.yaml,disable=on --network bridge=virbr0 --osinfo=debian10 --noautoconsole

# Cleanup
rm /var/lib/libvirt/images/bashvm-cloudinit.yaml


if [ ! $? == 0 ]; then
echo "Failed to start $vm_name"
echo "Check to see if $vm_name already exists"
exit
fi


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
else
mkdir /var/log/bashvm
touch $log_file
ip_address="192.168.122.1"
fi

# Value to add
increment=1

# Extract the last octet
last_octet="${ip_address##*.}"

# Increment the last octet
((last_octet += increment))

# Construct the new IP address
vm_ip="${ip_address%.*}.$last_octet"

echo "$vm_ip" >> "$log_file"

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

# Create log file if it doesn't exist
if [ -f $log_file ];then

# The startport will the end of the file output
start_port=$(tail -n 1 "$log_file")

# Create log file
else
touch $log_file
start_port=1025
fi

# Add a range of 20 ports
end_port=$(($start_port + 20))

# Reserve for next block calculation
echo $(($end_port + 2)) >> $log_file

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
echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '$vm_ip' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '$vm_ip':22' >> /etc/libvirt/hooks/qemu

# Port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '$vm_ip' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$port' -j DNAT --to '$vm_ip':'$port'' >> /etc/libvirt/hooks/qemu
done

# Keep out of loop
middle_script='    fi
    if [ "${2}" = "start" ] || [ "${2}" = "reconnect" ]; then'
echo "$middle_script" >> /etc/libvirt/hooks/qemu

# Reserve for SSH
echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '$vm_ip' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '$vm_ip':22' >> /etc/libvirt/hooks/qemu

# port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '$vm_ip' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$port' -j DNAT --to '$vm_ip':'$port'' >> /etc/libvirt/hooks/qemu
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
if [ $vm_on == 1 ]; then
systemctl restart libvirtd
fi

echo "Restarting vm..."

# Restart new vm for portforwarding to work
while true; do
  vm_state=$(virsh dominfo $vm_name | grep State: | awk '{print $2}')

  if [ $vm_state == "running" ]; then
    virsh shutdown $vm_name >> /dev/null
    echo "Waiting for $vm_name to shutdown..."
    sleep 5
  else
    virsh start $vm_name
    break
  fi
    continue

done

echo ""
echo "========== Info for $vm_name ==========" | tee -a /var/log/bashvm/$vm_name.info.txt
echo "" | tee -a /var/log/bashvm/$vm_name.info.txt
echo "IPv4: $vm_ip" | tee -a /var/log/bashvm/$vm_name.info.txt
echo "SSH port: $ssh_port" | tee -a /var/log/bashvm/$vm_name.info.txt
echo "Ports: $start_port to $end_port" | tee -a /var/log/bashvm/$vm_name.info.txt
echo "Username: $user_name" | tee -a /var/log/bashvm/$vm_name.info.txt
echo "Password: $user_pass" | tee -a /var/log/bashvm/$vm_name.info.txt
echo "" | tee -a /var/log/bashvm/$vm_name.info.txt
echo "====================================================" | tee -a /var/log/bashvm/$vm_name.info.txt
echo ""
echo "Info for $vm_name has been saved to /var/log/bashvm/$vm_name.info.txt"
echo "You may need to restart libvirtd, networking and the vm for the changes to take effect"
