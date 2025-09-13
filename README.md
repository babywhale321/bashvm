# bashvm

bashvm is a console based virtual machine manager

## How to use

### Getting Started

`apt install git -y`

`git clone https://github.com/babywhale321/bashvm.git`

`cd bashvm/`

`bash bashvm-installer.sh`

`bash bashvm.sh`

### Updating bashvm

Copy the bashvm.db file somewhere else

`cp bashvm.db ../`

Remove the current bashvm directory

`cd ../`

`rm -r bashvm/`

Download the new version

`git clone https://github.com/babywhale321/bashvm.git`

Copy the database file back into the bashvm directory

`cp bashvm.db bashvm/`

### Recommended OS for bashvm
#### amd64
- Debian 13 (64-bit)
- Debian 12 (64-bit)
- Ubuntu 22.04 (64-bit)
- Ubuntu 24.04 (64-bit)

#### arm64
- Raspberry Pi OS Lite (64-bit)
- Ubuntu Server 22.04.5 LTS (64-bit)


### bashvm-installer.sh
The bashvm installer script installs the following packages

- qemu-kvm, libvirt-daemon-system, libvirt-clients, virt-manager, qemu-utils, cloud-init, bridge-utils, net-tools, ufw, ifstat, ndppd, dnsmasq, btop, bc, sqlite3
    
### Screenshots
https://bashvm.com/screenshots.html

### Guide
https://bashvm.com/guide.html

### Donations:
https://www.paypal.com/paypalme/babywhale123

### Sponsors:
Huge thanks to https://metalvps.com for their contribution and support!
