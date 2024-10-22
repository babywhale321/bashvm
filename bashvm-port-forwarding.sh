#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

read -ep "Enter the VM name: " vm_name

# If the variable is empty then don't continue
if [ -z "$vm_name" ]; then
    echo "Invalid response. Please enter a VM name."
    exit
fi

read -ep "Enter the name of the virtual bridge [virbr0]: " int_name

# Default if empty
if [ -z "$int_name" ]; then
    int_name="virbr0"
fi

read -ep "Enter the ip of the VM (e.g., 192.168.122.2 ): " nat_ip
read -ep "Enter the start port range (e.g., 1024): " start_port
read -ep "Enter the ending port (e.g., 1048): " end_port

echo "#!/bin/bash" >> /etc/libvirt/hooks/qemu

# Identifier for deleting if needed
echo "#$vm_name#" >> /etc/libvirt/hooks/qemu            

# Keep out of loop
nat_script=' 
if [ "${1}" = "'$vm_name'" ]; then

    if [ "${2}" = "stopped" ] || [ "${2}" = "reconnect" ]; then'

echo "$nat_script" >> /etc/libvirt/hooks/qemu

# Reserve a port for SSH
ssh_port="$start_port"
echo '      /sbin/iptables -D FORWARD -o '"$int_name"' -p tcp -d '"$nat_ip"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '"$nat_ip"':22' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -D FORWARD -o '"$int_name"' -p udp -d '"$nat_ip"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -D PREROUTING -p udp --dport '$ssh_port' -j DNAT --to '"$nat_ip"':22' >> /etc/libvirt/hooks/qemu
start_port=$(($ssh_port + 1))
# Port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -D FORWARD -o '"$int_name"' -p tcp -d '"$nat_ip"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$port' -j DNAT --to '"$nat_ip"':'$port'' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -D FORWARD -o '"$int_name"' -p udp -d '"$nat_ip"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -D PREROUTING -p udp --dport '$port' -j DNAT --to '"$nat_ip"':'$port'' >> /etc/libvirt/hooks/qemu
done

# Keep out of loop
middle_script='    fi
    if [ "${2}" = "start" ] || [ "${2}" = "reconnect" ]; then'
echo "$middle_script" >> /etc/libvirt/hooks/qemu

# Reserve for SSH
echo '      /sbin/iptables -I FORWARD -o '"$int_name"' -p tcp -d '"$nat_ip"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$ssh_port' -j DNAT --to '"$nat_ip"':22' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -I FORWARD -o '"$int_name"' -p udp -d '"$nat_ip"' --dport 22 -j ACCEPT' >> /etc/libvirt/hooks/qemu
echo '      /sbin/iptables -t nat -I PREROUTING -p udp --dport '$ssh_port' -j DNAT --to '"$nat_ip"':22' >> /etc/libvirt/hooks/qemu
# port forward rules to loop until it reaches end port
for ((port=start_port; port<=end_port; port++)); do

    echo '      /sbin/iptables -I FORWARD -o '"$int_name"' -p tcp -d '"$nat_ip"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$port' -j DNAT --to '"$nat_ip"':'$port'' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -I FORWARD -o '"$int_name"' -p udp -d '"$nat_ip"' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
    echo '      /sbin/iptables -t nat -I PREROUTING -p udp --dport '$port' -j DNAT --to '"$nat_ip"':'$port'' >> /etc/libvirt/hooks/qemu
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
echo "SSH port: $ssh_port" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "Ports: $start_port to $end_port" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo "====================================================" | tee -a /var/log/bashvm/"$vm_name".info.txt
echo ""
chmod 600 /var/log/bashvm/"$vm_name".info.txt
echo "Info for $vm_name has been saved to /var/log/bashvm/$vm_name.info.txt"
echo "You will need to stop then start the vm for the changes to take effect"
