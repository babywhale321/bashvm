#!/bin/bash
#
# bashvm.com - IPv6 Routed Network Creator
#
# Author: Kyle Schroeder "BabyWhale"

echo "A routed network is for static IPv4 and IPv6 configurations"
echo "Routes traffic between VMs and external network"
echo "No NAT translation or DHCP service"
echo "(Ctrl+C to exit)"
echo ""

read -ep "Enter the new network name: " net_name
read -ep "Enter the main physical interface (e.g., eth0): " int_name

read -ep "Enter the IPv6 network address that will act as the gateway for this new interface (e.g., 2001:db8::): " ip_network
read -ep "Enter the IPv6 prefix length (e.g., 64): " ip_prefix

# Validate network doesn't already exist
if virsh net-info "$net_name" &>/dev/null; then
    echo "Error: Network '$net_name' already exists"
    exit 1
fi

# Create accept_ra configuration if needed
if ! grep -q "net.ipv6.conf.$int_name.accept_ra = 2" /etc/sysctl.conf; then
    echo "net.ipv6.conf.$int_name.accept_ra = 2" >> /etc/sysctl.conf
    sysctl -p &>/dev/null
    
    # Create persistent service
    cat > /etc/systemd/system/bashvm-ipv6-accept-ra.service <<EOF
[Unit]
Description=Apply accept_ra settings for bashvm
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/sysctl -p

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable bashvm-ipv6-accept-ra.service &>/dev/null
fi

# Generate network XML
net_xml=$(cat <<EOF
<network>
  <name>$net_name</name>
  <forward mode='route'/>
  <bridge name='virbr${RANDOM:0:3}' stp='on' delay='0'/>
  <ip family='ipv6' address='$ip_network' prefix='$ip_prefix'/>
</network>
EOF
)

# Define and start network
echo "$net_xml" > /etc/libvirt/qemu/networks/"$net_name".xml
virsh net-define /etc/libvirt/qemu/networks/"$net_name".xml
virsh net-start "$net_name"
virsh net-autostart "$net_name"

# Configure ndppd
cat > /etc/ndppd.conf <<EOF
route-ttl 30000

proxy $int_name {
    router yes
    timeout 500
    ttl 30000
    rule ${ip_network}/${ip_prefix} {
        static
    }
}
EOF

# Enable ndppd service
systemctl restart ndppd
systemctl enable ndppd &>/dev/null

echo "When adding a static IPv6 to a vm the gateway address will be "$ip_network""
echo "If no errors above then the new network "$net_name" is ready to use"