#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

read -ep "Enter the main interface name that already has a IPv6 address (e.g., eth0): " int_name
read -ep "Enter a IPv6 prefix that is a higher number then your main interface ( e.g., if 64 then 80 ): " ip_prefix 
read -ep "Enter the network name [default]: " net_name

if [ -z "$net_name" ]; then
    net_name="default"
fi

cat /etc/libvirt/qemu/networks/"$net_name".xml | grep "ipv6" >> /dev/null

if [ $? == 0 ];then
    echo "There is already a dhcpv6 configuration in ""$net_name"""
    echo "Please remove the dhcpv6 information from ""$net_name"" before running this again."
    exit
fi

ip address show dev "$int_name" | grep inet6 | grep global >> /dev/null

if [ ! $? == 0 ];then
    echo "There is no IPv6 address detected on the main interface"
    exit
fi

# Check to see if the line is there
accept_ra=$(cat /etc/sysctl.conf | grep "accept_ra = 2")

if [ -z "$accept_ra" ]; then
    # Accept router advertisements for the main interface
    echo "
    net.ipv6.conf."$int_name".accept_ra = 2" >> /etc/sysctl.conf
    # Reload service so no need for a reboot
    sysctl -p >> /dev/null
    # Create service to apply accept_ra settings on boot
    echo "[Unit]
Description=bashvm service to apply accept_ra = 2 settings
After=network.target

[Service]
Type=oneshot
ExecStart=sysctl -p

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/bashvm-ipv6-accept-ra.service
# Enable service
systemctl enable bashvm-ipv6-accept-ra.service
fi

# Detect the ipv6 address
ipv6_address=$(ifconfig | grep inet6 | grep global | awk '{print $2}')

# Function to increment a hexadecimal digit
increment_hex() {
    local hex=$1
    printf '%x' $(( 0x$hex + 1 ))
}

# Function to calculate the next IPv6 address
next_ipv6_address() {
    local ipv6_address=$1

    # Split the IPv6 address into parts
    IFS=':' read -ra address_parts <<< "$ipv6_address"

    # Increment the last digit
    last_index=$((${#address_parts[@]} - 1))
    new_last_digit=$(increment_hex "${address_parts[last_index]}")
    address_parts[last_index]=$new_last_digit

    # Reconstruct the next IPv6 address
    next_ipv6_address=$(IFS=':'; echo "${address_parts[*]}")
    echo "$next_ipv6_address"
}

# Find the next 2 IPv6 addresses
ip_gateway=$(next_ipv6_address "$ipv6_address")
ip_start=$(next_ipv6_address "$ip_gateway")

# Loop to find the next 300 IPv6 addresses
ip_end="$ip_start"
for ((i = 1; i <= 300; i++)); do
    ip_end=$(next_ipv6_address "$ip_end")
done

# dhcpv6 info
vm_info="  </ip>
<ip family='ipv6' address='$ip_gateway' prefix='$ip_prefix'>
    <dhcp>
    <range start='$ip_start' end='$ip_end'/>
    </dhcp>
</ip>
</network>"

# Remove the last 2 ending tags in $net_name.xml
sed -i "s/<\/ip>//g" /etc/libvirt/qemu/networks/"$net_name".xml
sed -i "s/<\/network>//g" /etc/libvirt/qemu/networks/"$net_name".xml

# Add dhcpv6 info and closing tags
echo "$vm_info" >> /etc/libvirt/qemu/networks/"$net_name".xml

# Stop, define, start then autostart $net_name network
virsh net-destroy "$net_name" > /dev/null 2>&1
virsh net-define /etc/libvirt/qemu/networks/"$net_name".xml
virsh net-start "$net_name"
virsh net-autostart "$net_name"

# ndppd config file
ndppd_file="route-ttl 30000

proxy "$int_name" {
router yes
timeout 500
ttl 30000
rule "$ip_gateway/$ip_prefix" {
    static
}
}"

echo "$ndppd_file" > /etc/ndppd.conf

# enable and restart ndppd
systemctl enable ndppd
systemctl restart ndppd

echo ""
echo "If no errors above then dhcpv6 has been added to ""$net_name"""
