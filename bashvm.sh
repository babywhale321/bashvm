#!/bin/bash
#
# vps-manager written in Bash
#
# Author: Kyle Schroeder "BabyWhale"

while true; do
    # Display the main menu
    echo -e "\n===== Main Menu ====="
    echo "1. Virtual Machines"
    echo "2. Storage Pools"
    echo "3. Networks"
    echo "4. Snapshots"
    echo "5. Edit XML"
    echo "6. VNC Access"
    echo "7. System Monitor"
    echo "q. Exit"

    # Prompt user for input
    read -p "Enter your choice: " main_choice

    case $main_choice in
        1)
            # Virtual Machines Menu    
            while true; do
                echo -e "\n===== Manage Virtual Machine ====="
                echo "s. List all virtual machines"
                echo "1. Show details"
                echo "2. Start a VM"
                echo "3. Shutdown a VM (graceful)"
                echo "4. Shutdown a VM (force)"
                echo "5. Configure vCPU and memory of a VM"
                echo "6. Create a VM"
                echo "7. Delete a VM"
                echo "q. Back to main menu"

                read -p "Enter your choice: " vm_manage_choice

                case $vm_manage_choice in
                    s)
                        # List all virtual machines
                        echo "All virtual machines:"
                        virsh list --all
                        ;;
                    1)
                        # Show details of a virtual machine
                        read -p "Enter the name of the virtual machine: " vm_name
                        virsh dominfo "$vm_name"
                        ;;
                    2)
                        # Start a virtual machine
                        read -p "Enter the name of the virtual machine to start: " vm_name
                        virsh start "$vm_name"
                        virsh autostart "$vm_name"
                        ;;
                    3)
                        # Shutdown a VM (graceful)
                        read -p "Enter the name of the virtual machine to stop: " vm_name
                        virsh shutdown "$vm_name"
                        ;;

                    4)
                        # Shutdown a VM (force)
                        read -p "Enter the name of the virtual machine to stop: " vm_name
                        virsh destroy "$vm_name"
                        ;;

                    5)
                        # Configure CPU and Memory for a virtual machine
                        read -p "Enter the name of the virtual machine to configure: " vm_name
                        read -p "Enter the new number of virtual CPUs: " vcpus
                        read -p "Enter the new amount of memory in MB: " memory
                        virsh setvcpus "$vm_name" "$vcpus"
                        virsh setmem "$vm_name" "$memory"MB --live
                        ;;
                    6)
                        # Function to generate a random MAC address
                        generate_random_mac() {
                            printf '52:54:%02x:%02x:%02x:%02x\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
                        }
                    
                        # Prompt user for VM details
                        read -p "Enter the name for the new virtual machine: " new_vm_name
                        read -p "Enter the amount of memory in MB: " new_memory
                        read -p "Enter the number of virtual CPUs: " new_vcpus
                        read -p "Enter the full path to the ISO file (e.g., /var/lib/libvirt/images/mini.iso): " iso_path
                        read -p "Enter the full path of the virtual machine disk (e.g., /var/lib/libvirt/qemu/vm.qcow2): " disk_path
                        read -p "Enter the network name to connect the virtual machine to (e.g., default): " network_name
                        
                        # Generate a random MAC address
                        random_mac=$(generate_random_mac)

                        # Generate a UUID
                        uuid=$(cat /proc/sys/kernel/random/uuid)

                        # Define the XML configuration for the new virtual machine
                        vm_xml="<domain type='kvm'>
                        <name>$new_vm_name</name>
                        <uuid>$uuid</uuid>
                        <memory unit='KiB'>$((new_memory * 1024))</memory>
                        <currentMemory unit='KiB'>$((new_memory * 1024))</currentMemory>
                        <vcpu placement='static'>$new_vcpus</vcpu>
                        <os>
                            <type arch='x86_64' machine='q35'>hvm</type>
                            <boot dev='hd'/>
                            <boot dev='cdrom'/>
                        </os>
                        <features>
                            <acpi/>
                            <apic/>
                            <vmport state='off'/>
                        </features>
                        <cpu mode='host-passthrough' check='none' migratable='on'>
                            <topology sockets='1' dies='1' cores='$new_vcpus' threads='1'/>
                        </cpu>
                        <clock offset='utc'>
                            <timer name='rtc' tickpolicy='catchup'/>
                            <timer name='pit' tickpolicy='delay'/>
                            <timer name='hpet' present='no'/>
                        </clock>
                        <on_poweroff>destroy</on_poweroff>
                        <on_reboot>restart</on_reboot>
                        <on_crash>destroy</on_crash>
                        <pm>
                            <suspend-to-mem enabled='no'/>
                            <suspend-to-disk enabled='no'/>
                        </pm>
                        <devices>
                            <emulator>/usr/bin/qemu-system-x86_64</emulator>
                            <disk type='file' device='disk'>
                            <driver name='qemu' type='qcow2' cache='none' io='native'/>
                            <source file='$disk_path'/>
                            <target dev='vda' bus='virtio'/>
                            <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
                            </disk>
                            <disk type='file' device='cdrom'>
                            <driver name='qemu' type='raw'/>
                            <source file='$iso_path'/>
                            <target dev='sda' bus='sata'/>
                            <readonly/>
                            <address type='drive' controller='0' bus='0' target='0' unit='0'/>
                            </disk>
                            <controller type='usb' index='0' model='qemu-xhci' ports='15'>
                            <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
                            </controller>
                            <controller type='sata' index='0'>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
                            </controller>
                            <controller type='pci' index='0' model='pcie-root'/>
                            <controller type='virtio-serial' index='0'>
                            <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
                            </controller>
                            <controller type='pci' index='1' model='pcie-root-port'>
                            <model name='pcie-root-port'/>
                            <target chassis='1' port='0x10'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
                            </controller>
                            <controller type='pci' index='2' model='pcie-root-port'>
                            <model name='pcie-root-port'/>
                            <target chassis='2' port='0x11'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
                            </controller>
                            <controller type='pci' index='3' model='pcie-root-port'>
                            <model name='pcie-root-port'/>
                            <target chassis='3' port='0x12'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
                            </controller>
                            <controller type='pci' index='4' model='pcie-root-port'>
                            <model name='pcie-root-port'/>
                            <target chassis='4' port='0x13'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
                            </controller>
                            <controller type='pci' index='5' model='pcie-root-port'>
                            <model name='pcie-root-port'/>
                            <target chassis='5' port='0x14'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
                            </controller>
                            <controller type='pci' index='6' model='pcie-root-port'>
                            <model name='pcie-root-port'/>
                            <target chassis='6' port='0x15'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
                            </controller>
                            <controller type='pci' index='7' model='pcie-root-port'>
                            <model name='pcie-root-port'/>
                            <target chassis='7' port='0x16'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
                            </controller>
                            <interface type='network'>
                            <mac address='$random_mac'/>
                            <source network='$network_name'/>
                            <model type='virtio'/>
                            <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
                            </interface>
                            <serial type='pty'>
                            <target type='isa-serial' port='0'>
                                <model name='isa-serial'/>
                            </target>
                            </serial>
                            <console type='pty'>
                            <target type='serial' port='0'/>
                            </console>
                            <channel type='unix'>
                            <target type='virtio' name='org.qemu.guest_agent.0'/>
                            <address type='virtio-serial' controller='0' bus='0' port='1'/>
                            </channel>
                            <channel type='spicevmc'>
                            <target type='virtio' name='com.redhat.spice.0'/>
                            <address type='virtio-serial' controller='0' bus='0' port='2'/>
                            </channel>
                            <input type='tablet' bus='usb'>
                            <address type='usb' bus='0' port='1'/>
                            </input>
                            <input type='mouse' bus='ps2'/>
                            <input type='keyboard' bus='ps2'/>
                            <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0'>
                            <listen type='address' address='0.0.0.0'/>
                            </graphics>
                            <graphics type='spice' autoport='yes' listen='0.0.0.0'>
                            <listen type='address' address='0.0.0.0'/>
                            <image compression='off'/>
                            </graphics>
                            <sound model='ich9'>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
                            </sound>
                            <audio id='1' type='spice'/>
                            <video>
                            <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
                            </video>
                            <redirdev bus='usb' type='spicevmc'>
                            <address type='usb' bus='0' port='2'/>
                            </redirdev>
                            <redirdev bus='usb' type='spicevmc'>
                            <address type='usb' bus='0' port='3'/>
                            </redirdev>
                            <memballoon model='virtio'>
                            <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
                            </memballoon>
                            <rng model='virtio'>
                            <backend model='random'>/dev/urandom</backend>
                            <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
                            </rng>
                        </devices>
                        </domain>"


                        # Define the path for the new VM XML file
                        vm_xml_file="/etc/libvirt/qemu/$new_vm_name.xml"

                        # Save the XML configuration to the file
                        echo "$vm_xml" > "$vm_xml_file"

                        # Create the new virtual machine
                        virsh define "$vm_xml_file"

                        echo "Virtual machine $new_vm_name created successfully."
                        ;;

                    7)
                        # Delete a virtual machine
                        read -p "Enter the name of the virtual machine to delete: " delete_vm_name
                        virsh destroy "$delete_vm_name"
                        virsh undefine "$delete_vm_name"
                        ;;
                    
                    q)
                        # Back to Menu
                        break
                        ;;
                    *)
                        echo "Invalid choice. Please enter a valid option."
                        ;;
                esac
            done
            ;;

        2)
            # Storage Pools Menu
            while true; do
                echo -e "\n===== Manage Storage Pool ====="
                echo "s. Show details of storage pools"
                echo "1. Show all volumes from a pool"
                echo "2. Activate a storage pool"
                echo "3. Deactivate a storage pool"
                echo "4. Create a storage pool"
                echo "5. Delete a storage pool"
                echo "6. Create a storage volume"
                echo "7. Delete a storage volume"
                echo "q. Back to main menu"

                read -p "Enter your choice: " storage_manage_choice

                case $storage_manage_choice in
                    s)
                        # Show details of pools
                        virsh pool-list --details
                        ;;

                    1)
                        read -p "Enter the name of the storage pool: " pool_name
                        virsh vol-list --pool "$pool_name"
                        ;;
                    
                    2)
                        # Activate a storage pool
                        read -p "Enter the name of the storage pool to activate: " pool_name
                        virsh pool-start "$pool_name"
                        ;;
                    3)
                        # Deactivate a storage pool
                        read -p "Enter the name of the storage pool to deactivate: " pool_name
                        virsh pool-destroy "$pool_name"
                        ;;
                    4)
                        # Create a new storage pool
                        read -p "Enter the name of the new storage pool: " new_pool_name
                        read -p "Enter the type of the new storage pool (e.g., dir, logical, fs): " pool_type
                        read -p "Enter the target path or source for the new storage pool: " pool_source
                        virsh pool-define-as "$new_pool_name" "$pool_type" --target "$pool_source"
                        virsh pool-start "$new_pool_name"
                        virsh pool-autostart "$new_pool_name"
                        ;;
                    5)
                        # Delete a storage pool
                        read -p "Enter the name of the storage pool to delete: " delete_pool_name
                        virsh pool-destroy "$delete_pool_name"
                        virsh pool-delete "$delete_pool_name"
                        ;;

                    6)
                        # Create a storage volume
                        read -p "Enter the name of the storage pool to use: " pool_name
                        read -p "Enter the name of the new storage volume (e.g., new-vm.qcow2): " volume_name
                        read -p "Enter the size of the volume (e.g., 10G): " volume_capacity
                        virsh vol-create-as --pool "$pool_name" --name "$volume_name" --capacity "$volume_capacity" --format qcow2
                        ;;
                    
                    7)
                        # Delete a storage volume
                        # Prompt user for details
                        read -p "Enter the storage pool name that the volume is under: " pool_name
                        read -p "Enter the name of the volume to delete: " volume_name

                        # Delete the storage volume
                        virsh vol-delete --pool "$pool_name" "$volume_name"

                        echo "Storage volume $volume_name deleted successfully from pool $pool_name."
                        ;;
                    q)
                        # Back to Menu
                        break
                        ;;
                    *)
                        echo "Invalid choice. Please enter a valid option."
                        ;;
                esac
            done
            ;;
        3)
            # Networks Menu       
            while true; do
                echo -e "\n===== Manage Network ====="
                echo "s. Show all networks"
                echo "1. Show details of a network"
                echo "2. Start a network"
                echo "3. Stop a network"
                echo "4. Create a NAT network"
                echo "5. Create a macvtap network"
                echo "6. Add portforwarding rules to a VM behind a NAT"
                echo "7. Delete a network"
                echo "q. Back to main menu"

                read -p "Enter your choice: " network_manage_choice

                case $network_manage_choice in
                    s)
                        # List all networks
                        virsh net-list --all
                        ;;
                    1)
                        # Show detailnano 1.shs of a network
                        read -p "Enter the name of the network: " network_name
                        virsh net-info "$network_name"
                        ;;
                    2)
                        # Start a network
                        read -p "Enter the name of the network to start: " network_name
                        virsh net-start "$network_name"
                        virsh net-autostart "$network_name"
                        ;;
                    3)
                        # Stop a network
                        read -p "Enter the name of the network to stop: " network_name
                        virsh net-destroy "$network_name"
                        ;;
                    4)
                        # Prompt user for network configuration
                        read -p "Enter network name: " network_name
                        read -p "Enter bridge name: " bridge_name
                        read -p "Enter network IP address (e.g., 192.168.100.1): " network_ip
                        read -p "Enter network netmask (e.g., 255.255.255.0): " netmask
                        read -p "Enter DHCP range start (e.g., 192.168.100.2): " dhcp_start
                        read -p "Enter DHCP range end (e.g., 192.168.100.254): " dhcp_end

                        # Create network XML file
                        network_xml="
                        <network>
                        <name>${network_name}</name>
                        <forward mode='nat'/>
                        <bridge name='${bridge_name}'/>
                        <ip address='${network_ip}' netmask='${netmask}'>
                            <dhcp>
                            <range start='${dhcp_start}' end='${dhcp_end}'/>
                            </dhcp>
                        </ip>
                        </network>"

                        # Save the network XML to a file
                        net_xml_file="/etc/libvirt/qemu/networks/$network_name.xml"
                        echo "${network_xml}" > "${net_xml_file}"

                        # Define and start network
                        virsh net-define "${net_xml_file}"
                        virsh net-start "${network_name}"
                        virsh net-autostart "${network_name}"

                        echo "Network $network_name created and started successfully."
                        ;;
                    5) 
                    
                        read -p "Enter the new network name: " network_name
                        read -p "Enter the physical network interface to attach: " int_name

                        network_xml="
                        <network>
                        <name>$network_name</name>
                        <forward mode='bridge'>
                            <interface dev='$int_name'/>
                        </forward>
                        </network>"

                        net_xml_file="/etc/libvirt/qemu/networks/$network_name.xml"
                        echo "${network_xml}" > "${net_xml_file}"

                        # Define and start network
                        virsh net-define "${net_xml_file}"
                        virsh net-start "${network_name}"
                        virsh net-autostart "${network_name}"

                        echo "Network $network_name created and started successfully."
                        ;;
                    6)

                        # Add portforwarding rules to a VM behind a NAT
                        read -p "Enter the VM name: " vm_name
                        read -p "Enter the NAT interface name: " int_name
                        read -p "Enter the NAT ip of the VM: " nat_ip
                        read -p "Enter the starting port for the host to listen on: " nat_start_port
                        read -p "Enter the ending port for the host to listen on (next 20 ports): " nat_end_port

                        start_port=22
                        end_port=42

                        nat_script='#!/bin/bash
                        if [ "${1}" = "'$vm_name'" ]; then

                            # Update the following variables to fit your setup

                            if [ "${2}" = "stopped" ] || [ "${2}" = "reconnect" ]; then'

                        echo "$nat_script" >> /etc/libvirt/hooks/qemu
                        

                        for ((port=start_port; port<=end_port; port++)); do
                            nat_port=$((port - start_port + nat_start_port))

                            echo '      /sbin/iptables -D FORWARD -o '$int_name' -p tcp -d '$nat_ip' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
                            echo '      /sbin/iptables -t nat -D PREROUTING -p tcp --dport '$nat_port' -j DNAT --to '$nat_ip':'$port'' >> /etc/libvirt/hooks/qemu
                        done

                        middle_script='    fi
                            if [ "${2}" = "start" ] || [ "${2}" = "reconnect" ]; then'

                        echo "$middle_script" >> /etc/libvirt/hooks/qemu


                        for ((port=start_port; port<=end_port; port++)); do
                            nat_port=$((port - start_port + nat_start_port))

                            echo '      /sbin/iptables -I FORWARD -o '$int_name' -p tcp -d '$nat_ip' --dport '$port' -j ACCEPT' >> /etc/libvirt/hooks/qemu
                            echo '      /sbin/iptables -t nat -I PREROUTING -p tcp --dport '$nat_port' -j DNAT --to '$nat_ip':'$port'' >> /etc/libvirt/hooks/qemu
                        done

                        last_script='    fi
                        fi'

                        echo "$last_script" >> /etc/libvirt/hooks/qemu

                        chmod +x /etc/libvirt/hooks/qemu

                        echo "Please shutdown $vm_name then restart libvirtd."



                        ;;
                    7)
                        # Delete a network
                        read -p "Enter the name of the network to delete: " delete_network_name
                        virsh net-destroy "$delete_network_name"
                        virsh net-undefine "$delete_network_name"
                        ;;
                    q)
                        # Back to Menu
                        break
                        ;;
                    *)
                        echo "Invalid choice. Please enter a valid option."
                        ;;
                esac
            done
            ;;
        4)
            # Managing a snapshot
            while true; do
                echo -e "\n===== Manage Snapshot ====="
                echo "s. List all snapshots of a virtual machine"
                echo "1. Create a snapshot"
                echo "2. Delete a snapshot"
                echo "3. Revert to a snapshot"
                echo "q. Back to main menu"

                read -p "Enter your choice: " snapshot_manage_choice

                case $snapshot_manage_choice in
                    s)
                        # List all snapshots of a virtual machine
                        read -p "Enter the name of the virtual machine: " vm_name
                        virsh snapshot-list "$vm_name"
                        ;;
                    1)
                        # Create a snapshot of a virtual machine
                        read -p "Enter the name of the virtual machine: " vm_name
                        read -p "Enter the name for the new snapshot: " snapshot_name
                        virsh snapshot-create-as "$vm_name" "$snapshot_name"
                        ;;
                    2)
                        # Delete a snapshot of a virtual machine
                        read -p "Enter the name of the virtual machine: " vm_name
                        read -p "Enter the name of the snapshot to delete: " snapshot_name
                        virsh snapshot-delete "$vm_name" "$snapshot_name"
                        ;;
                    3)
                        # Revert to a snapshot of a virtual machine
                        read -p "Enter the name of the virtual machine: " vm_name
                        read -p "Enter the name of the snapshot to revert to: " snapshot_name
                        virsh snapshot-revert "$vm_name" "$snapshot_name"
                        ;;
                    q)
                        # Back to main menu
                        break
                        ;;
                    *)
                        echo "Invalid choice. Please enter a valid option."
                        ;;
                esac
            done
            ;;
        
        5)
            # Edit XML
            while true; do
                echo -e "\n===== Edit XML ====="
                echo "1. Edit a VM"
                echo "2. Edit a storage pool"
                echo "3. Edit a network"
                echo "4. Edit a snapshot"
                echo "q. Back to main menu"

                read -p "Enter your choice: " xml_manage_choice

                case $xml_manage_choice in
                    1)  
                        # edit a vm
                        read -p "Enter the VM name: " vm_name
                        virsh edit $vm_name
                        ;;
                    2)
                        # edit a storage pool
                        read -p "Enter the storage pool name: " pool_name
                        virsh pool-edit $pool_name
                        ;;
                    3)
                        # edit a network
                        read -p "Enter the network name: " net_name
                        virsh net-edit $net_name
                        ;;
                    4)
                        # edit a snapshot
                        read -p "Enter the VM name: " vm_name
                        read -p "Enter the snapshot name: " snap_name
                        virsh snapshot-edit --snapshotname $snap_name --domain $vm_name
                        ;;
                    q)
                        # Back to Main Menu
                        break
                        ;;
                    *)
                        echo "Invalid choice. Please enter a valid option."
                        ;;
                esac
            done
            ;;
        6)
            # VNC Access
            echo ""
            echo "Please use a VNC client to access the vm (e.g., remmina)"
            echo "The port thats associated with the vm can be found with (netstat -l)"
            echo "Please note that vnc access will always be on unless you block the port with a firewall (e.g., ufw)"
            ;;
        7)
            # System Monitor
            htop
            ;;
        q)
            # Exit the script
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter a valid option."
            ;;
    esac
done
