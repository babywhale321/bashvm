#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

# Required packages to download
# Function to check the exit status and exit if failed
check_status() {
    if [ "$1" -ne 0 ]; then
        echo "Error: $2 failed to install."
        exit 1
    fi
}

# Install packages
apt install qemu-kvm -y
check_status $? "qemu-kvm"
echo ""
apt install libvirt-daemon-system -y
check_status $? "libvirt-daemon-system"
echo ""
apt install libvirt-clients -y
check_status $? "libvirt-clients"
echo ""
apt install bridge-utils -y
check_status $? "bridge-utils"
echo ""
apt install qemu-utils -y
check_status $? "qemu-utils"
echo ""
apt install virt-manager -y
check_status $? "virt-manager"
echo ""
apt install cloud-init -y
check_status $? "cloud-init"
echo ""
apt install net-tools -y
check_status $? "net-tools"
echo ""
apt install ufw -y
check_status $? "ufw"
echo ""
apt install btop -y
check_status $? "btop"
echo ""
apt install bc -y
check_status $? "bc"
echo ""
apt install ifstat -y
check_status $? "ifstat"
echo ""
apt install ndppd -y
check_status $? "ndppd"
echo ""
apt install sqlite3 -y
check_status $? "sqlite3"
echo ""

# Check and install dnsmasq
dpkg --list | grep dnsmasq >> /dev/null
if [ ! $? == 0 ]; then
    apt install dnsmasq -y
else
    echo "dnsmasq is already installed."
fi
echo ""

# Check and start libvirtd service if not active
if ! systemctl is-active --quiet libvirtd; then
    echo "Starting libvirtd service..."
    systemctl start libvirtd
    systemctl enable libvirtd
else
    echo "libvirtd is already active."
fi
echo ""

# Check and manage the default pool
if ! virsh pool-info default &>/dev/null; then
    echo "Default storage pool not found. Creating it..."
    virsh pool-define-as default dir --target /var/lib/libvirt/images
    virsh pool-start default
    virsh pool-autostart default
else
    if ! virsh pool-list --all | grep -q "default .* active"; then
        echo "Default storage pool exists but is inactive. Starting it..."
        virsh pool-start default
        virsh pool-autostart default
    else
        echo "Default storage pool is already active."
    fi
fi
echo ""

# Check and manage the default network
if ! virsh net-info default &>/dev/null; then
    echo "Default network not found. Creating it..."
    virsh net-define /etc/libvirt/qemu/networks/default.xml
    virsh net-start default
    virsh net-autostart default
else
    if ! virsh net-list --all | grep -q "default .* active"; then
        echo "Default network exists but is inactive. Starting it..."
        virsh net-start default
        virsh net-autostart default
    else
        echo "Default network is already active."
    fi
fi

# Enable TLS For VNC

# Certificate dir
CERT_DIR="/etc/pki/libvirt-vnc"
# CA validity
CA_DAYS=3650

mkdir -p "$CERT_DIR"
chmod 755 "$CERT_DIR"

echo "Generating Certificate Authority (CA)..."
cd "$CERT_DIR"

# CA template
cat > ca.info <<EOF
cn = "VNC CA"
ca
cert_signing_key
expiration_days = $CA_DAYS
EOF

# Generate CA private key
(umask 277 && certtool --generate-privkey > ca-key.pem)
certtool --generate-self-signed \
    --load-privkey ca-key.pem \
    --template ca.info \
    --outfile ca-cert.pem
rm -f ca.info

echo "Generating server certificate..."

# Determine hostname and IPs
HOSTNAME_FQDN=$(hostname -f 2>/dev/null || hostname)
HOSTNAME_SHORT=$(hostname -s)
IP_ADDRS=$(hostname -I | tr ' ' '\n' | grep -v '^$' || true)

# Server template
cat > server.info <<EOF
organization = "Libvirt VNC"
cn = "$HOSTNAME_FQDN"
EOF

# Add all detected IPv4/IPv6 addresses
for ip in $IP_ADDRS; do
    echo "ip_address = $ip" >> server.info
done

cat >> server.info <<EOF
tls_www_server
encryption_key
signing_key
EOF

# Generate server private key
(umask 277 && certtool --generate-privkey > server-key.pem)
certtool --generate-certificate \
    --load-ca-certificate ca-cert.pem \
    --load-ca-privkey ca-key.pem \
    --load-privkey server-key.pem \
    --template server.info \
    --outfile server-cert.pem
rm -f server.info


# Ensure private keys are only readable by root
chmod 600 "$CERT_DIR"/*-key.pem
chmod 644 "$CERT_DIR"/*.pem

# Configure /etc/libvirt/qemu.conf
QEMU_CONF="/etc/libvirt/qemu.conf"
BACKUP_CONF="${QEMU_CONF}.bak.$(date +%Y%m%d%H%M%S)"

echo "Backing up $QEMU_CONF to $BACKUP_CONF"
cp -a "$QEMU_CONF" "$BACKUP_CONF"

# Function to set a configuration option in qemu.conf. It uncomments the line if present, or appends it.
set_qemu_option() {
local key="$1"
local value="$2"
local escaped_key
escaped_key=$(echo "$key" | sed 's/\./\\./g')

# If line exists (commented or uncommented) with the key, replace it.
if grep -qE "^\s*#?\s*${escaped_key}\s*=" "$QEMU_CONF"; then
    sed -i -E "s|^\s*#?\s*${escaped_key}\s*=.*|${key} = ${value}|" "$QEMU_CONF"
else
    # Append if not found
    echo "${key} = ${value}" >> "$QEMU_CONF"
fi
}

echo "Updating VNC configuration in $QEMU_CONF"

# Enable TLS
set_qemu_option "vnc_tls" "1"

# Set certificate directory
set_qemu_option "vnc_tls_x509_cert_dir" "\"$CERT_DIR\""

echo "Configuration updated."

# Check to see if other virtual machines are running.
vm_on=$(virsh list --all | grep -E '^\s+[0-9]+' | wc -l)

# If only 1 then restart libvirtd
if [ "$vm_on" -eq 0 ]; then
    systemctl restart libvirtd
else
    echo "You will need to restart libvirtd for vnc to use tls"
    echo "run the command below to restart libvirtd"
    echo "systemctl restart libvirtd"
    echo "NOTE: this will be disruptive to already running vm's"
fi

echo ""

echo "==========================================================="
echo "If no errors above then you can run bashvm with"
echo "bash bashvm.sh"
echo ""
