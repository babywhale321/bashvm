#!/bin/bash

read -ep "Enter the VM name: " vm_name
read -ep "Enter the name of the virtual bridge [virbr0]: " int_name

# Default if empty
if [ -z "$int_name" ]; then
    int_name="virbr0"
fi

read -ep "Enter the NAT ip of the VM (e.g., 192.168.122.2 ): " nat_ip
log_file="used_ports.log"

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
echo "#$vm_name" >> /etc/libvirt/hooks/qemu            

# Keep out of loop
nat_script=' 
if [ "${1}" = "'$vm_name'" ]; then

    if [ "${2}" = "stopped" ] || [ "${2}" = "reconnect" ]; then'

echo "$nat_script" >> /etc/libvirt/hooks/qemu

# Reserve a port for SSH
ssh_port=$(($start_port - 1))
echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '$nat_ip' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '$nat_ip':22' >> /etc/libvirt/hooks/qemu

# Port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '$nat_ip' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$port' -j DNAT --to '$nat_ip':'$port'' >> /etc/libvirt/hooks/qemu
done

# Keep out of loop
middle_script='    fi
    if [ "${2}" = "start" ] || [ "${2}" = "reconnect" ]; then'
echo "$middle_script" >> /etc/libvirt/hooks/qemu

# Reserve for SSH
echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '$nat_ip' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '$nat_ip':22' >> /etc/libvirt/hooks/qemu

# port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '$nat_ip' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$port' -j DNAT --to '$nat_ip':'$port'' >> /etc/libvirt/hooks/qemu
done

# Keep out of loop
last_script='    fi
fi'
echo "$last_script" >> /etc/libvirt/hooks/qemu

# End Identifier
echo "###$vm_name" >> /etc/libvirt/hooks/qemu

# libvirt needs the file to be executable
chmod +x /etc/libvirt/hooks/qemu

echo ""
echo "========== Port Forward Info for $vm_name =========="
echo ""
echo "ssh port = $ssh_port"
echo "$start_port to $end_port"
echo "Is the port range of $vm_name"
echo ""
echo "Please restart the VM for the changes to take effect."
echo "You might also need to reboot the system."
