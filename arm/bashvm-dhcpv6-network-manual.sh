#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

read -ep "Enter the ipv6 address that will be served as the gateway ( e.g., xxxx::1 ): " ip_gateway
read -ep "Enter the prefix of the gateway (e.g., 64): " ip_prefix
read -ep "Enter the starting range ( e.g., xxxx::2 ): " ip_start
read -ep "Enter the ending range ( e.g., xxxx::300 ): " ip_end
read -ep "Enter the main interface name (e.g., eth0): " int_name
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
