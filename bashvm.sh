#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

while true; do
    # Display the main menu
    main_choice=$(whiptail --title "Main Menu" --menu "Choose an option" 20 78 10 \
    "1" "Virtual Machines" \
    "2" "Storage Pools" \
    "3" "Networks" \
    "4" "Snapshots" \
    "5" "Edit Properties" \
    "6" "Firewall Settings" \
    "7" "Port Forwarding" \
    "8" "VNC / Console Access" \
    "9" "System Monitor" \
    "10" "VM Monitor" \
    "q" "Exit" 3>&1 1>&2 2>&3)

    case $main_choice in
        1)
            # Virtual Machines Menu    
            while true; do
                vm_manage_choice=$(whiptail --title "Manage Virtual Machine" --menu "Choose an option" 20 78 15 \
                "s" "Show all virtual machines" \
                "1" "Show more details of a VM" \
                "2" "Start a VM" \
                "3" "Reboot a VM" \
                "4" "Shutdown a VM (graceful)" \
                "5" "Shutdown a VM (force)" \
                "6" "Enable autostart of a VM" \
                "7" "Disable autostart of a VM" \
                "8" "Create a new / existing VM" \
                "9" "Undefine a VM" \
                "10" "Create a new VM (Automated)" \
                "11" "Console into a VM" \
                "12" "Change resources of a VM" \
                "13" "Delete a VM" \
                "14" "Clone a VM" \
                "15" "Rename a VM" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $vm_manage_choice in
                    s)
                        # Show all virtual machines
                        virsh list --all
                        whiptail --title "Virtual Machines" --msgbox "$(virsh list --all)" 20 78
                        ;;

                    1)
                        # Show details of a virtual machine
                        vm_name=$(whiptail --inputbox "Enter the VM name:" 8 78 --title "VM Details" 3>&1 1>&2 2>&3)
                        details=$(virsh dominfo "$vm_name"; virsh domblkinfo "$vm_name" --all --human)
                        whiptail --title "VM Details" --msgbox "$details" 20 78
                        ;;

                    2)
                        # Start a virtual machine
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine to start:" 8 78 --title "Start VM" 3>&1 1>&2 2>&3)
                        virsh start "$vm_name"
                        ;;

                    3)
                        # Reboot a VM
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine to restart:" 8 78 --title "Reboot VM" 3>&1 1>&2 2>&3)
                        virsh reboot "$vm_name"
                        ;;

                    4)
                        # Shutdown a VM (graceful)
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine to shutdown:" 8 78 --title "Shutdown VM" 3>&1 1>&2 2>&3)
                        virsh shutdown "$vm_name"
                        ;;

                    5)
                        # Shutdown a VM (force)
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine to force shutdown:" 8 78 --title "Force Shutdown VM" 3>&1 1>&2 2>&3)
                        virsh destroy "$vm_name"
                        ;;

                    6)
                        # Enable autostart
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine to autostart on boot:" 8 78 --title "Enable Autostart" 3>&1 1>&2 2>&3)
                        virsh autostart "$vm_name"
                        ;;
                    
                    7)
                        # Disable autostart
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine to disable autostart on boot:" 8 78 --title "Disable Autostart" 3>&1 1>&2 2>&3)
                        virsh autostart --disable "$vm_name"
                        ;;
                        
                    8)
                        # Create a new VM
                        bash bashvm-create-vm.sh
                        ;;

                     9)
                        # Undefine a virtual machine
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine to undefine:" 8 78 --title "Undefine VM" 3>&1 1>&2 2>&3)
                        
                        vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
                        
                        if [ "$vm_state" == "running" ];then
                            whiptail --title "Error" --msgbox "Please shutdown the vm before running this again" 8 78
                            break
                        fi
                        
                        virsh destroy "$vm_name" > /dev/null 2>&1
                        virsh undefine "$vm_name"
                        ;;
                    
                    10)
                        # Create a VM (Automated)
                        bash bashvm-create-auto-vm.sh
                        ;;
                    
                    11)
                        # Console into a VM
                        hostname=$(whiptail --inputbox "Enter the VM name to console into:" 8 78 --title "Console into VM" 3>&1 1>&2 2>&3)
                        virsh console "$hostname"
                        ;;

                    12)
                        # Change resources of a VM
                        bash bashvm-change-resources.sh
                        ;;
                    13)
                        # Delete a VM
                        bash bashvm-delete-vm.sh
                        ;;

                    14)
                        # Clone a VM
                        vm_name=$(whiptail --inputbox "Enter the name of the vm to clone (e.g., test-vm):" 8 78 --title "Clone VM" 3>&1 1>&2 2>&3)
                        clone_num=$(whiptail --inputbox "Enter the amount of clones of this vm to create (e.g., 1):" 8 78 --title "Clone VM" 3>&1 1>&2 2>&3)
                        counter=1
                        while [ "$counter" -le "$clone_num" ]
                        do
                            virt-clone --original "$vm_name" --auto-clone
                            ((counter++))
                        done
                        ;;
                    15)
                        # Rename a VM
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine:" 8 78 --title "Rename VM" 3>&1 1>&2 2>&3)
                        vm_name_new=$(whiptail --inputbox "Enter the new name of the virtual machine:" 8 78 --title "Rename VM" 3>&1 1>&2 2>&3)
                        virsh domrename "$vm_name" "$vm_name_new"
                        ;;
                        
                    q)
                        # Back to Menu
                        break
                        ;;

                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
            ;;

        2)
            # Storage Pools Menu
            while true; do
                storage_manage_choice=$(whiptail --title "Manage Storage Pool" --menu "Choose an option" 20 78 10 \
                "s" "Show all storage pools" \
                "1" "Show all volumes in a pool" \
                "2" "Activate a storage pool" \
                "3" "Deactivate a storage pool" \
                "4" "Create a storage pool" \
                "5" "Delete a storage pool" \
                "6" "Create a storage volume" \
                "7" "Delete a storage volume" \
                "8" "Clone a storage volume" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $storage_manage_choice in
                    s)
                        # Show all pools
                        pools=$(virsh pool-list --details)
                        whiptail --title "Storage Pools" --msgbox "$pools" 20 78
                        ;;

                    1)
                        #Show all volumes in a pool
                        pool_name=$(whiptail --inputbox "Enter the name of the storage pool [default]:" 8 78 --title "Show Volumes" 3>&1 1>&2 2>&3)
                        if [ -z "$pool_name" ]; then
                            pool_name="default"
                        fi
                        volumes=$(virsh vol-list --pool "$pool_name")
                        whiptail --title "Storage Volumes" --msgbox "$volumes" 20 78
                        ;;
                    
                    2)
                        # Activate a storage pool
                        pool_name=$(whiptail --inputbox "Enter the name of the storage pool to activate [default]:" 8 78 --title "Activate Storage Pool" 3>&1 1>&2 2>&3)
                        if [ -z "$pool_name" ]; then
                            pool_name="default"
                        fi
                        virsh pool-start "$pool_name"
                        ;;
                        
                    3)
                        # Deactivate a storage pool
                        pool_name=$(whiptail --inputbox "Enter the name of the storage pool to deactivate [default]:" 8 78 --title "Deactivate Storage Pool" 3>&1 1>&2 2>&3)
                        if [ -z "$pool_name" ]; then
                            pool_name="default"
                        fi
                        virsh pool-destroy "$pool_name"
                        ;;

                    4)
                        # Create a new storage pool
                        new_pool_name=$(whiptail --inputbox "Enter the name of the new storage pool:" 8 78 --title "Create Storage Pool" 3>&1 1>&2 2>&3)
                        pool_type=$(whiptail --inputbox "Enter the type of the new storage pool (e.g., dir, logical, fs):" 8 78 --title "Create Storage Pool" 3>&1 1>&2 2>&3)
                        pool_source=$(whiptail --inputbox "Enter the target path or source for the new storage pool:" 8 78 --title "Create Storage Pool" 3>&1 1>&2 2>&3)
                        virsh pool-define-as "$new_pool_name" "$pool_type" --target "$pool_source"
                        virsh pool-start "$new_pool_name"
                        virsh pool-autostart "$new_pool_name"
                        ;;

                    5)
                        # Delete a storage pool
                        delete_pool_name=$(whiptail --inputbox "Enter the name of the storage pool to delete:" 8 78 --title "Delete Storage Pool" 3>&1 1>&2 2>&3)
                        virsh pool-destroy "$delete_pool_name"
                        virsh pool-undefine "$delete_pool_name"
                        ;;

                    6)
                        # Create a storage volume
                        pool_name=$(whiptail --inputbox "Enter the name of the storage pool to use [default]:" 8 78 --title "Create Storage Volume" 3>&1 1>&2 2>&3)
                        if [ -z "$pool_name" ]; then
                            pool_name="default"
                        fi
                        volume_name=$(whiptail --inputbox "Enter the name of the new storage volume (e.g., new-vm):" 8 78 --title "Create Storage Volume" 3>&1 1>&2 2>&3)
                        volume_capacity=$(whiptail --inputbox "Enter the size of the volume (e.g., 10G):" 8 78 --title "Create Storage Volume" 3>&1 1>&2 2>&3)
                        virsh vol-create-as --pool "$pool_name" --name "$volume_name.qcow2" --capacity "$volume_capacity" --format qcow2
                        ;;
                    
                    7)
                        # Delete a storage volume
                        pool_name=$(whiptail --inputbox "Enter the storage pool name that the volume is under [default]:" 8 78 --title "Delete Storage Volume" 3>&1 1>&2 2>&3)
                        if [ -z "$pool_name" ]; then
                            pool_name="default"
                        fi
                        volume_name=$(whiptail --inputbox "Enter the name of the volume to delete (e.g., new-vm):" 8 78 --title "Delete Storage Volume" 3>&1 1>&2 2>&3)
                        virsh vol-delete --pool "$pool_name" "$volume_name.qcow2"
                        ;;
                    
                    8)
                        # Clone a storage volume
                        vm_name=$(whiptail --inputbox "Enter the name of the volume to clone (e.g., test-vm):" 8 78 --title "Clone Storage Volume" 3>&1 1>&2 2>&3)
                        new_vm_name=$(whiptail --inputbox "Enter the new volume name (e.g., new-test-vm):" 8 78 --title "Clone Storage Volume" 3>&1 1>&2 2>&3)
                        pool_name=$(whiptail --inputbox "Enter the storage pool name that the volume is under [default]:" 8 78 --title "Clone Storage Volume" 3>&1 1>&2 2>&3)
                        if [ -z "$pool_name" ]; then
                            pool_name="default"
                        fi
                        virsh vol-clone "$vm_name.qcow2" "$new_vm_name.qcow2" --pool "$pool_name"
                        ;;
                    
                    q)
                        # Back to Menu
                        break
                        ;;

                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
            ;;
        3)
            # Networks Menu       
            while true; do
                network_manage_choice=$(whiptail --title "Manage Network" --menu "Choose an option" 20 78 12 \
                "s" "Show all networks" \
                "1" "Show more details of a network" \
                "2" "Start a network" \
                "3" "Stop a network" \
                "4" "Create a NAT network" \
                "5" "Create a macvtap network" \
                "6" "Delete a network" \
                "7" "Add a IPv4 reservation to a network" \
                "8" "Remove a IPv4 reservation" \
                "9" "Add dhcpv6 to a network (auto)" \
                "10" "Add dhcpv6 to a network (manual)" \
                "11" "Add a IPv6 reservation to a network" \
                "12" "Edit a network" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $network_manage_choice in
                    s)
                        # List all networks
                        networks=$(virsh net-list --all)
                        whiptail --title "Networks" --msgbox "$networks" 20 78
                        ;;

                    1)
                        # Show details of a network
                        network_name=$(whiptail --inputbox "Enter the network name [default]:" 8 78 --title "Network Details" 3>&1 1>&2 2>&3)
                        if [ -z "$network_name" ]; then
                            network_name="default"
                        fi
                        details=$(virsh net-info "$network_name"; virsh net-dhcp-leases "$network_name")
                        whiptail --title "Network Details" --msgbox "$details" 20 78
                        ;;

                    2)
                        # Start a network
                        network_name=$(whiptail --inputbox "Enter the name of the network to start [default]:" 8 78 --title "Start Network" 3>&1 1>&2 2>&3)
                        if [ -z "$network_name" ]; then
                            network_name="default"
                        fi
                        virsh net-start "$network_name"
                        virsh net-autostart "$network_name"
                        ;;

                    3)
                        # Stop a network
                        network_name=$(whiptail --inputbox "Enter the name of the network to stop [default]:" 8 78 --title "Stop Network" 3>&1 1>&2 2>&3)
                        if [ -z "$network_name" ]; then
                            network_name="default"
                        fi
                        virsh net-destroy "$network_name"
                        ;;

                    4)
                        # Prompt user for NAT network configuration
                        network_name=$(whiptail --inputbox "Enter the new network name (e.g., natbr0):" 8 78 --title "Create NAT Network" 3>&1 1>&2 2>&3)
                        bridge_name=$(whiptail --inputbox "Enter the virtual bridge name (e.g., natbr0):" 8 78 --title "Create NAT Network" 3>&1 1>&2 2>&3)
                        network_ip=$(whiptail --inputbox "Enter the new gateway ip address (e.g., 192.168.100.1):" 8 78 --title "Create NAT Network" 3>&1 1>&2 2>&3)
                        netmask=$(whiptail --inputbox "Enter the new subnet mask (e.g., 255.255.255.0):" 8 78 --title "Create NAT Network" 3>&1 1>&2 2>&3)
                        dhcp_start=$(whiptail --inputbox "Enter the starting ip for the DHCP range (e.g., 192.168.100.2):" 8 78 --title "Create NAT Network" 3>&1 1>&2 2>&3)
                        dhcp_end=$(whiptail --inputbox "Enter the ending ip for the DHCP range (e.g., 192.168.100.254):" 8 78 --title "Create NAT Network" 3>&1 1>&2 2>&3)

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

                        net_xml_file="/etc/libvirt/qemu/networks/$network_name.xml"
                        echo "${network_xml}" > "${net_xml_file}"

                        virsh net-define "${net_xml_file}"
                        virsh net-start "${network_name}"
                        virsh net-autostart "${network_name}"
                        ;;

                    5) 
                        # Prompt user for macvtap network configuration
                        network_name=$(whiptail --inputbox "Enter the new network name:" 8 78 --title "Create Macvtap Network" 3>&1 1>&2 2>&3)
                        int_name=$(whiptail --inputbox "Enter the physical network interface to attach:" 8 78 --title "Create Macvtap Network" 3>&1 1>&2 2>&3)

                        network_xml="
                        <network>
                        <name>$network_name</name>
                        <forward mode='bridge'>
                            <interface dev='$int_name'/>
                        </forward>
                        </network>"

                        net_xml_file="/etc/libvirt/qemu/networks/$network_name.xml"
                        echo "${network_xml}" > "${net_xml_file}"

                        virsh net-define "${net_xml_file}"
                        virsh net-start "${network_name}"
                        virsh net-autostart "${network_name}"
                        ;;

                    6)
                        # Delete a network
                        delete_network_name=$(whiptail --inputbox "Enter the name of the network to delete:" 8 78 --title "Delete Network" 3>&1 1>&2 2>&3)
                        virsh net-destroy "$delete_network_name"
                        virsh net-undefine "$delete_network_name"
                        ;;

                    7)
                        # Add a dhcpv4 reservation to a network
                        vm_name=$(whiptail --inputbox "Enter the virtual machines name:" 8 78 --title "Add DHCPv4 Reservation" 3>&1 1>&2 2>&3)
                        vm_mac=$(whiptail --inputbox "Enter the virtual machines mac address:" 8 78 --title "Add DHCPv4 Reservation" 3>&1 1>&2 2>&3)
                        vm_ip=$(whiptail --inputbox "Enter the new ip address for the virtual machine:" 8 78 --title "Add DHCPv4 Reservation" 3>&1 1>&2 2>&3)
                        vm_net=$(whiptail --inputbox "Enter the network name [default]:" 8 78 --title "Add DHCPv4 Reservation" 3>&1 1>&2 2>&3)

                        if [ -z "$vm_net" ]; then
                            vm_net="default"
                        fi

                        virsh net-update "$vm_net" add ip-dhcp-host "<host mac='$vm_mac' name='$vm_name' ip='$vm_ip' />" --live --config
                        
                        if [ ! $? == 0 ]; then
                            whiptail --title "Error" --msgbox "Failed to set DHCP reservation in $vm_net" 8 78
                        else
                            whiptail --title "Success" --msgbox "DHCP reservation set successfully. You may need to start / stop the vm for the changes to take effect" 8 78
                        fi
                        ;;
                    8)
                        # Remove a dhcpv4 reservation
                        vm_name=$(whiptail --inputbox "Enter the VM name:" 8 78 --title "Remove DHCPv4 Reservation" 3>&1 1>&2 2>&3)
                        net_name=$(whiptail --inputbox "Enter the network name [default]:" 8 78 --title "Remove DHCPv4 Reservation" 3>&1 1>&2 2>&3)

                        if [ -z "$net_name" ]; then
                            net_name="default"
                        fi

                        vm_mac=$(virsh net-dumpxml "$net_name" | grep "$vm_name" | head -n 1 | awk '{print $2}'| cut -d"'" -f2)
                        vm_ip=$(virsh net-dumpxml "$net_name" | grep "$vm_name" | head -n 1 | awk '{print $4}'| cut -d"'" -f2)

                        virsh net-update "$net_name" delete ip-dhcp-host "<host mac='$vm_mac' name='$vm_name' ip='$vm_ip' />" --live --config
                        
                        if [ ! $? == 0 ]; then
                            whiptail --title "Error" --msgbox "Failed to remove DHCP reservation from $net_name" 8 78
                        else
                            whiptail --title "Success" --msgbox "DHCP reservation removed successfully. You may need to start / stop the vm for the changes to take effect" 8 78
                        fi
                        ;;

                    9)  
                        # Add dhcpv6 to a network (auto)
                        bash bashvm-dhcpv6-network-auto.sh
                        ;; 
                    
                    10)
                        # Add dhcpv6 to a network (manual)
                        bash bashvm-dhcpv6-network-manual.sh
                        ;;

                    11)
                        # Add a dhcpv6 reservation to a network
                        vm_name=$(whiptail --inputbox "Enter the vm name you are assigning a IPv6 address to:" 8 78 --title "Add DHCPv6 Reservation" 3>&1 1>&2 2>&3)
                        net_address=$(whiptail --inputbox "Enter the desired IPv6 address to assign the vm (e.g., xxxx::3):" 8 78 --title "Add DHCPv6 Reservation" 3>&1 1>&2 2>&3)
                        net_name=$(whiptail --inputbox "Enter the network name [default]:" 8 78 --title "Add DHCPv6 Reservation" 3>&1 1>&2 2>&3)

                        if [ -z "$net_name" ]; then
                            net_name="default"
                        fi

                        virsh net-update "$net_name" add-last ip-dhcp-host "<host name='$vm_name' ip='$net_address'/>" --live --config --parent-index 1
                        
                        if [ ! $? == 0 ]; then
                            whiptail --title "Error" --msgbox "Failed to set DHCP reservation in $net_name" 8 78
                        else
                            whiptail --title "Success" --msgbox "DHCP reservation set successfully. You may need to restart the vm for the changes to take effect" 8 78
                        fi
                        ;;

                   12)
                        # Edit a network
                        net_name=$(whiptail --inputbox "Enter the network name [default]:" 8 78 --title "Edit Network" 3>&1 1>&2 2>&3)
                        if [ -z "$net_name" ]; then
                            net_name="default"
                        fi
                        virsh net-edit "$net_name"
                        ;;

                    q)
                        # Back to Menu
                        break
                        ;;

                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
            ;;
        4)
            # Managing a snapshot
            while true; do
                snapshot_manage_choice=$(whiptail --title "Manage Snapshot" --menu "Choose an option" 20 78 4 \
                "s" "Show all snapshots of a VM" \
                "1" "Create a snapshot" \
                "2" "Delete a snapshot" \
                "3" "Revert to a snapshot" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $snapshot_manage_choice in
                    s)
                        # List all snapshots of a virtual machine
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine:" 8 78 --title "Show Snapshots" 3>&1 1>&2 2>&3)
                        snapshots=$(virsh snapshot-list "$vm_name")
                        whiptail --title "Snapshots" --msgbox "$snapshots" 20 78
                        ;;
                    1)
                        # Create a snapshot of a virtual machine
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine:" 8 78 --title "Create Snapshot" 3>&1 1>&2 2>&3)
                        snapshot_name=$(whiptail --inputbox "Enter the name for the new snapshot:" 8 78 --title "Create Snapshot" 3>&1 1>&2 2>&3)
                        virsh snapshot-create-as "$vm_name" "$snapshot_name"
                        ;;
                    2)
                        # Delete a snapshot of a virtual machine
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine:" 8 78 --title "Delete Snapshot" 3>&1 1>&2 2>&3)
                        snapshot_name=$(whiptail --inputbox "Enter the name of the snapshot to delete:" 8 78 --title "Delete Snapshot" 3>&1 1>&2 2>&3)
                        virsh snapshot-delete "$vm_name" "$snapshot_name"
                        ;;
                    3)
                        # Revert to a snapshot of a virtual machine
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine:" 8 78 --title "Revert to Snapshot" 3>&1 1>&2 2>&3)
                        snapshot_name=$(whiptail --inputbox "Enter the name of the snapshot to revert to:" 8 78 --title "Revert to Snapshot" 3>&1 1>&2 2>&3)
                        virsh snapshot-revert "$vm_name" "$snapshot_name"
                        ;;
                    q)
                        # Back to main menu
                        break
                        ;;
                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
            ;;
        
        5)
            # Edit Properties
            while true; do
                xml_manage_choice=$(whiptail --title "Edit Properties" --menu "Choose an option" 20 78 5 \
                "1" "Edit a VM" \
                "2" "Edit a storage pool" \
                "3" "Edit a network" \
                "4" "Edit a snapshot" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $xml_manage_choice in
                    1)  
                        # edit a vm
                        vm_name=$(whiptail --inputbox "Enter the VM name:" 8 78 --title "Edit VM" 3>&1 1>&2 2>&3)
                        virsh edit "$vm_name"
                        ;;
                    2)
                        # edit a storage pool
                        pool_name=$(whiptail --inputbox "Enter the storage pool name [default]:" 8 78 --title "Edit Storage Pool" 3>&1 1>&2 2>&3)
                        if [ -z "$pool_name" ]; then
                            pool_name="default"
                        fi
                        virsh pool-edit "$pool_name"
                        ;;
                    3)
                        # edit a network
                        net_name=$(whiptail --inputbox "Enter the network name [default]:" 8 78 --title "Edit Network" 3>&1 1>&2 2>&3)
                        if [ -z "$net_name" ]; then
                            net_name="default"
                        fi
                        virsh net-edit "$net_name"
                        ;;
                    4)
                        # edit a snapshot
                        vm_name=$(whiptail --inputbox "Enter the VM name:" 8 78 --title "Edit Snapshot" 3>&1 1>&2 2>&3)
                        snap_name=$(whiptail --inputbox "Enter the snapshot name:" 8 78 --title "Edit Snapshot" 3>&1 1>&2 2>&3)
                        virsh snapshot-edit --snapshotname "$snap_name" --domain "$vm_name"
                        ;;
                    q)
                        # Back to Main Menu
                        break
                        ;;
                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
            ;;
        
        6)

            # Firewall Settings
            while true; do
                firewall_choice=$(whiptail --title "Firewall Settings" --menu "Choose an option" 20 78 9 \
                "s" "Show ufw status" \
                "1" "Show listening ports" \
                "2" "Allow port range" \
                "3" "Deny port range" \
                "4" "Allow single port" \
                "5" "Deny single port" \
                "6" "Delete a rule" \
                "7" "Enable and reload ufw" \
                "8" "Disable and reset ufw" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $firewall_choice in
                    s)  
                        # Show ufw status
                        ufw_status=$(ufw status numbered)
                        whiptail --title "UFW Status" --msgbox "$ufw_status" 20 78
                        ;;
                    1)
                        # Show listening ports
                        listening_ports=$(netstat -l | grep "tcp\|udp")
                        whiptail --title "Listening Ports" --msgbox "$listening_ports" 20 78
                        ;;
                    2)
                        # Allow port range
                        port_start=$(whiptail --inputbox "Enter starting port:" 8 78 --title "Allow Port Range" 3>&1 1>&2 2>&3)
                        port_end=$(whiptail --inputbox "Enter ending port:" 8 78 --title "Allow Port Range" 3>&1 1>&2 2>&3)
                        ufw allow "$port_start":"$port_end"/tcp
                        ufw allow "$port_start":"$port_end"/udp
                        ufw reload
                        ;;
                    3)
                        # Deny Port range
                        port_start=$(whiptail --inputbox "Enter starting port:" 8 78 --title "Deny Port Range" 3>&1 1>&2 2>&3)
                        port_end=$(whiptail --inputbox "Enter ending port:" 8 78 --title "Deny Port Range" 3>&1 1>&2 2>&3)
                        ufw deny "$port_start":"$port_end"/tcp
                        ufw deny "$port_start":"$port_end"/udp
                        ufw reload
                        ;;
                    4)
                        # Allow single port
                        port=$(whiptail --inputbox "Enter the port number:" 8 78 --title "Allow Single Port" 3>&1 1>&2 2>&3)
                        ufw allow "$port"
                        ufw reload
                        ;;
                    5)
                        # Deny single port
                        port=$(whiptail --inputbox "Enter the port number:" 8 78 --title "Deny Single Port" 3>&1 1>&2 2>&3)
                        ufw deny "$port"
                        ufw reload
                        ;;
                    6)
                        # Delete a rule
                        rule_number=$(whiptail --inputbox "Enter the rule number to delete:" 8 78 --title "Delete Rule" 3>&1 1>&2 2>&3)
                        ufw delete "$rule_number"
                        ufw reload
                        ;;
                    7)
                        # ufw enable and reload
                        ufw enable
                        ufw reload
                        ;;
                    8)
                        # ufw disable and reset
                        ufw disable
                        ufw reset
                        ;;
                    q)
                        # Back to Main Menu
                        break
                        ;;
                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
            ;;
        7) 
            # Manage Port forwarding
            while true; do
                port_choice=$(whiptail --title "Manage Port Forwarding" --menu "Choose an option" 20 78 6 \
                "s" "Show port forwarding rules" \
                "1" "List DHCP leases from a network" \
                "2" "Add port forwarding to a VM" \
                "3" "Remove port forwarding from a VM" \
                "4" "Edit port forwarding rule file" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $port_choice in
                    s)  
                        # Show port forwarding rules
                        port_rules=$(iptables -t nat -L -n -v)
                        whiptail --title "Port Forwarding Rules" --msgbox "$port_rules" 20 78
                        bash bashvm-show-port-forwarding.sh
                        ;;

                    1)
                        # List DHCP leases
                        network_name=$(whiptail --inputbox "Enter the network name [default]:" 8 78 --title "List DHCP Leases" 3>&1 1>&2 2>&3)
                        if [ -z "$network_name" ]; then
                            network_name="default"
                        fi
                        leases=$(virsh net-dhcp-leases "$network_name")
                        whiptail --title "DHCP Leases" --msgbox "$leases" 20 78
                        ;;

                    2)
                        # Add port forwarding rules to a VM behind a NAT
                        bash bashvm-add-port-forwarding.sh
                        ;;

                    3)
                        # Delete port forwarding rules of vm
                        bash bashvm-remove-port-forwarding.sh
                        ;;

                    4)
                        # Edit port forwarding rules
                        nano /etc/libvirt/hooks/qemu || vim /etc/libvirt/hooks/qemu
                        ;;

                    q)
                        # Back to Main Menu
                        break
                        ;;

                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
            ;;

        8)
            # VNC / Console Access
            while true; do
                vnc_manage_choice=$(whiptail --title "VNC / Console Access" --menu "Choose an option" 20 78 4 \
                "s" "Show listening ports" \
                "1" "Add VNC port with password" \
                "2" "Remove VNC port" \
                "3" "Console into a vm" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $vnc_manage_choice in
                    s)
                        # Show listening ports
                        listening_ports=$(netstat -l | grep "tcp\|udp")
                        whiptail --title "Listening Ports" --msgbox "$listening_ports" 20 78
                        ;;

                    1)
                        # Add vnc access with password
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine (e.g., vm1):" 8 78 --title "Add VNC Port" 3>&1 1>&2 2>&3)
                        vnc_pass=$(whiptail --inputbox "Enter a VNC password to use (e.g., pass123):" 8 78 --title "Add VNC Port" 3>&1 1>&2 2>&3)

                        add_vnc=" <channel type='unix'>
                            <target type='virtio' name='org.qemu.guest_agent.0'/>
                            <address type='virtio-serial' controller='0' bus='0' port='1'/>
                            </channel>
                            <input type='tablet' bus='usb'>
                            <address type='usb' bus='0' port='1'/>
                            </input>
                            <input type='mouse' bus='ps2'/>
                            <input type='keyboard' bus='ps2'/>
                            <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0' passwd='"$vnc_pass"'>
                            <listen type='address' address='0.0.0.0'/>
                            </graphics>
                            <sound model='ich9'>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
                            </sound>
                            <audio id='1' type='none'/>
                            <video>
                            <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
                            </video>
                            <memballoon model='virtio'>
                            <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
                            </memballoon>
                            <rng model='virtio'>
                            <backend model='random'>/dev/urandom</backend>
                            <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
                            </rng>
                        </devices>
                        </domain>"

                        virsh dumpxml "$vm_name" | sed -n '/console/q;p' > "$vm_name".xml
                        echo "$add_vnc" >> "$vm_name".xml
                        virsh define "$vm_name".xml
                        rm "$vm_name".xml
                        whiptail --title "Success" --msgbox "Please shutdown then start the vm for the changes to take effect" 8 78
                        ;;
                    2)
                        # Remove VNC Port
                        vm_name=$(whiptail --inputbox "Enter the name of the virtual machine:" 8 78 --title "Remove VNC Port" 3>&1 1>&2 2>&3)
                        remove_vnc=" <channel type='unix'>
                            <target type='virtio' name='org.qemu.guest_agent.0'/>
                            <address type='virtio-serial' controller='0' bus='0' port='1'/>
                            </channel>
                            <input type='tablet' bus='usb'>
                            <address type='usb' bus='0' port='1'/>
                            </input>
                            <input type='mouse' bus='ps2'/>
                            <input type='keyboard' bus='ps2'/>
                            <sound model='ich9'>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
                            </sound>
                            <audio id='1' type='none'/>
                            <video>
                            <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
                            <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
                            </video>
                            <memballoon model='virtio'>
                            <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
                            </memballoon>
                            <rng model='virtio'>
                            <backend model='random'>/dev/urandom</backend>
                            <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
                            </rng>
                        </devices>
                        </domain>"

                        virsh dumpxml "$vm_name" | sed -n '/console/q;p' > "$vm_name".xml
                        echo "$remove_vnc" >> "$vm_name".xml
                        virsh define "$vm_name".xml
                        rm "$vm_name".xml
                        whiptail --title "Success" --msgbox "Please shutdown then start the vm for the changes to take effect" 8 78
                        ;;

                    3)
                        # Console into a VM
                        hostname=$(whiptail --inputbox "Enter the VM name to console into:" 8 78 --title "Console into VM" 3>&1 1>&2 2>&3)
                        virsh console "$hostname"
                        ;;
                        
                    q)
                        # Back to Main Menu
                        break
                        ;;
                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
            ;;
        9)
            # System Monitor
            btop
            ;;
        10)
            # Manage Port forwarding
            while true; do
                port_choice=$(whiptail --title "VM Monitor" --menu "Choose an option" 20 78 6 \
                "s" "Show all virtual machines" \
                "1" "VCPU usage of a VM" \
                "2" "Memory usage of a VM" \
                "3" "Disk usage of a VM" \
                "4" "Network usage of a VM" \
                "5" "All usage metrics of a VM" \
                "q" "Back to main menu" 3>&1 1>&2 2>&3)

                case $port_choice in
                    s)  
                        # Show all virtual machines
                        vms=$(virsh list --all)
                        whiptail --title "Virtual Machines" --msgbox "$vms" 20 78
                        ;;

                    1)
                        vm_name=$(whiptail --inputbox "Enter the name of the VM:" 8 78 --title "VCPU Usage" 3>&1 1>&2 2>&3)
                        vm_check=$(virsh dominfo "$vm_name")
                        if [ ! $? == 0 ];then
                            break
                        fi

                        # Setting the vcpu core count
                        cpu_count=$(virsh dominfo $vm_name | grep "CPU(s)" | awk '{print $2}')
                        # Counting starts at 0 so take away 1
                        cpu_count=$(( $cpu_count - 1 ))

                        # Loop through each core to output the usage
                        for ((i = 0; i <= $cpu_count; i++)); do
                            # Begin init time of vcpu
                            cpu_time_1=$(virsh domstats $vm_name | grep "vcpu.$i.time" | cut -d= -f2)
                            # Sleep
                            sleep 1
                            # End of init time of vcpu
                            cpu_time_2=$(virsh domstats $vm_name | grep "vcpu.$i.time" | cut -d= -f2)
                            # Delta is to be equal of time between recordings
                            delta_t=1
                            # Calculate the difference in CPU time (nanoseconds)
                            delta_cpu_time=$((cpu_time_2 - cpu_time_1))
                            # Normalize CPU usage as a percentage of total time available
                            cpu_usage=$(echo "scale=2; ($delta_cpu_time / ($delta_t * 1000000000)) * 100" | bc)
                            printf "CPU %d Usage: %.2f%%\n" "$i" "$cpu_usage"
                        done
                        ;;
                    2)
                        vm_name=$(whiptail --inputbox "Enter the name of the VM:" 8 78 --title "Memory Usage" 3>&1 1>&2 2>&3)
                        vm_check=$(virsh dominfo "$vm_name")
                        if [ ! $? == 0 ];then
                            break
                        fi

                        # Set the memory reported by the guest as being actively used
                        mem_rss=$(virsh domstats $vm_name | grep "balloon.rss" | cut -d= -f2)
                        # Set the memory reported by the guest as being available
                        mem_ava=$(virsh domstats $vm_name | grep "balloon.available" | cut -d= -f2)
                        # Calculate the usage percentage
                        memory_usage=$(echo "scale=2; ($mem_rss / ($mem_rss + $mem_ava)) * 100" | bc)
                        whiptail --title "Memory Usage" --msgbox "Memory Usage: $memory_usage%" 8 78
                    ;;

                    3)  
                        #Disk usage
                        vm_name=$(whiptail --inputbox "Enter the name of the VM:" 8 78 --title "Disk Usage" 3>&1 1>&2 2>&3)
                        vm_check=$(virsh dominfo "$vm_name")
                        if [ ! $? == 0 ];then
                            break
                        fi

                        disk=$(virsh domblklist $vm_name | grep v | awk '{print $1}')
                        # Set the total allocated disk space
                        disk_total=$(virsh guestinfo $vm_name | grep fs.0 | grep "total" | cut -d: -f2)
                        # Set the used disk space
                        disk_used=$(virsh guestinfo $vm_name | grep fs.0 | grep "used" | cut -d: -f2)
                        # Calculate the percentage value of the used disk space
                        disk_usage=$(echo "scale=2; ($disk_used / $disk_total) * 100" | bc)
                        whiptail --title "Disk Usage" --msgbox "Disk Usage: $disk_usage%" 8 78
                    ;;

                    4)
                        vm_name=$(whiptail --inputbox "Enter the name of the VM:" 8 78 --title "Network Usage" 3>&1 1>&2 2>&3)
                        vm_check=$(virsh dominfo "$vm_name")
                        if [ ! $? == 0 ];then
                            break
                        fi

                        # Show the virtual interface assigned to the vm and output the usage
                        interface=$(virsh domiflist $vm_name | grep v | awk '{print $1}')
                        ifstat -i $interface 1 1
                    ;;

                    5)
                        #show all metrics
                        bash bashvm-monitor.sh
                    ;;

                    q)
                        # Back to Main Menu
                        break
                        ;;

                    *)
                        whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
                        ;;
                esac
            done
        ;;

        q)
            # Exit the script
            whiptail --title "Exit" --msgbox "Exiting." 8 78
            exit 0
            ;;
        *)
            whiptail --title "Error" --msgbox "Invalid choice. Please enter a valid option." 8 78
            ;;
    esac
done
