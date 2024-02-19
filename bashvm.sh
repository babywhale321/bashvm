#!/bin/bash
#
#bashvm is a console tool to manage your virtual machines.
#
#Author: Kyle Schroeder "BabyWhale"

while true; do
    # Display the main menu
    echo -e "\n========================== Main Menu =========================="
    echo "1. Virtual Machines   2. Storage Pools    3. Networks"
    echo "4. Snapshots          5. Edit Properties  6. Firewall Settings"
    echo "7. Port Forwarding    8. System Monitor   q. Exit"
    echo ""
    # Prompt user for input
    read -ep "Enter your choice: " main_choice
    case $main_choice in
        1)
            # Virtual Machines Menu    
            while true; do
                    echo -e "\n==================== Manage Virtual Machine ===================="
                    echo "s. Show all virtual machines     1. Show more details of a VM"
                    echo "2. Start a VM                    3. Reboot a VM"               
                    echo "4. Shutdown a VM (graceful)      5. Shutdown a VM (force)"     
                    echo "6. Enable autostart of a VM      7. Disable autostart of a VM"
                    echo "8. Create a new VM               9. Undefine a VM"                  
                    echo "10.Create a new VM (Automated)   11.Console into a VM"        
                    echo "12.Change resources of a VM      q. Back to main menu"
                    echo ""
                    read -ep "Enter your choice: " vm_manage_choice
                    case $vm_manage_choice in
                    s)
                        # Show all virtual machines
                        virsh list --all
                        ;;

                    1)
                        # Show details of a virtual machine
                        read -ep "Enter the VM name: " vm_name
                        virsh dominfo "$vm_name"
                        virsh domfsinfo "$vm_name"
                        virsh domblkinfo "$vm_name" --all --human
                        ;;

                    2)
                        # Start a virtual machine
                        read -ep "Enter the name of the virtual machine to start: " vm_name
                        virsh start "$vm_name"
                        ;;

                    3)
                        # Reboot a VM
                        read -ep "Enter the name of the virtual machine to restart: " vm_name
                        virsh reboot "$vm_name"
                        ;;

                    4)
                        # Shutdown a VM (graceful)
                        read -ep "Enter the name of the virtual machine to shutdown: " vm_name
                        virsh shutdown "$vm_name"
                        ;;

                    5)
                        # Shutdown a VM (force)
                        read -ep "Enter the name of the virtual machine to force shutdown: " vm_name
                        virsh destroy "$vm_name"
                        ;;

                    6)
                        # Enable autostart
                        read -ep "Enter the name of the virtual machine to autostart on boot: " vm_name
                        virsh autostart "$vm_name"
                        ;;
                    
                    7)
                        # Disable autostart
                        read -ep "Enter the name of the virtual machine to disable autostart on boot: " vm_name
                        virsh autostart --disable "$vm_name"
                        ;;
                        
                    8)
                        # Create a new VM
                        bash bashvm-create-vm.sh
                        ;;

                    9)
                        # Undefine a virtual machine
                        read -ep "Enter the name of the virtual machine to undefine: " vm_name
                        virsh destroy "$vm_name"
                        virsh undefine "$vm_name"
                        ;;
                    
                    10)
                        # Create a VM (Automated)                                                       
                        echo "This will create a debian12 VM with (2 vcores, 2GB ram, 20GB disk)"
                        echo "Press Enter to confirm this is what you want or q to exit"
                        read -ep ": " auto_choice 
                        if [[ ! "$auto_choice" == q ]];then
                            bash bashvm-cloudinit.sh
                        else
                            echo "Aborted"
                        fi
                        ;;
                    
                    11)
                        # Console into a VM
                        read -ep "Enter the VM name to console into: " hostname
                        virsh console $hostname
                        ;;

                    12)
                        # Change resources of a VM
                        while true; do
                            echo -e "\n===================== Manage Resources ====================="
                            echo "s. Show resources of a VM     1. Add disk space to a VM"
                            echo "2. Shrink disk space of a VM  3. Change the number of vcpu in a VM"
                            echo "4. Change the memory of a VM  q. Back to main menu"
                            echo ""
                            read -ep "Enter your choice: " manage_choice

                            case $manage_choice in
                                s)
                                    # Show resources of a VM
                                    read -ep "Enter the VM name: " vm_name
                                    virsh dominfo "$vm_name"
                                    virsh domfsinfo "$vm_name"
                                    virsh domblkinfo "$vm_name" --all --human
                                    ;;

                                1)
                                    # Add disk space to a VM
                                    read -ep "Enter the name of the virtual machine: " vm_name
                                    read -ep "Enter the new disk size (e.g., 40GB): " disk_size
                                    read -ep "Enter the pool name [default]: " pool_name
                                    if [ -z "$pool_name" ]; then
                                        pool_name="default"
                                    fi
                                    virsh vol-resize "$vm_name".qcow2 "$disk_size" --pool "$pool_name"
                                    ;;

                                2)
                                    # Shrink disk space of a VM
                                    read -ep "Enter the name of the virtual machine: " vm_name
                                    read -ep "Enter the new disk size (e.g., 40GB): " disk_size
                                    read -ep "Enter the pool name [default]: " pool_name
                                    if [ -z "$pool_name" ]; then
                                        pool_name="default"
                                    fi
                                    virsh vol-resize "$vm_name".qcow2 "$disk_size" --pool "$pool_name" --shrink
                                    ;;

                                3)
                                    # Change vcpus
                                    read -ep "Enter the name of the virtual machine: " vm_name
                                    read -ep "Enter the new vcpu number (e.g., 4): " vcpu_num
                                    virsh setvcpus --domain "$vm_name" --count "$vcpu_num" --config --maximum
                                    virsh setvcpus --domain "$vm_name" --count "$vcpu_num" --config
                                    ;;

                                4)
                                    # Change memory
                                    read -ep "Enter the name of the virtual machine: " vm_name
                                    read -ep "Enter the new memory size (e.g., 1GB): " mem_num
                                    virsh setmaxmem --domain "$vm_name" --size "$mem_num" --current
                                    virsh setmem --domain "$vm_name" --size "$mem_num" --current
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
                echo -e "\n====================== Manage Storage Pool ======================"
                echo "s. Show all storage pools         1. Show all volumes in a pool"
                echo "2. Activate a storage pool        3. Deactivate a storage pool"
                echo "4. Create a storage pool          5. Delete a storage pool"
                echo "6. Create a storage volume        7. Delete a storage volume"
                echo "q. Back to main menu"
                echo ""
                read -ep "Enter your choice: " storage_manage_choice

                case $storage_manage_choice in
                    s)
                        # Show all pools
                        virsh pool-list --details
                        ;;

                    1)
                        #Show all volumes in a pool
                        read -ep "Enter the name of the storage pool: " pool_name
                        virsh vol-list --pool "$pool_name"
                        ;;
                    
                    2)
                        # Activate a storage pool
                        read -ep "Enter the name of the storage pool to activate: " pool_name
                        virsh pool-start "$pool_name"
                        ;;
                        
                    3)
                        # Deactivate a storage pool
                        read -ep "Enter the name of the storage pool to deactivate: " pool_name
                        virsh pool-destroy "$pool_name"
                        ;;

                    4)
                        # Create a new storage pool
                        read -ep "Enter the name of the new storage pool: " new_pool_name
                        read -ep "Enter the type of the new storage pool (e.g., dir, logical, fs): " pool_type
                        read -ep "Enter the target path or source for the new storage pool: " pool_source
                        virsh pool-define-as "$new_pool_name" "$pool_type" --target "$pool_source"
                        virsh pool-start "$new_pool_name"
                        virsh pool-autostart "$new_pool_name"
                        ;;

                    5)
                        # Delete a storage pool
                        read -ep "Enter the name of the storage pool to delete: " delete_pool_name
                        virsh pool-destroy "$delete_pool_name"
                        virsh pool-delete "$delete_pool_name"
                        ;;

                    6)
                        # Create a storage volume
                        read -ep "Enter the name of the storage pool to use: " pool_name
                        read -ep "Enter the name of the new storage volume (e.g., new-vm): " volume_name
                        read -ep "Enter the size of the volume (e.g., 10G): " volume_capacity
                        virsh vol-create-as --pool "$pool_name" --name "$volume_name.qcow2" --capacity "$volume_capacity" --format qcow2
                        ;;
                    
                    7)
                        # Delete a storage volume
                        read -ep "Enter the storage pool name that the volume is under (e.g., default): " pool_name
                        read -ep "Enter the name of the volume to delete (e.g., new-vm): " volume_name

                        # Delete the storage volume
                        virsh vol-delete --pool "$pool_name" "$volume_name.qcow2"
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
                echo -e "\n========================== Manage Network =========================="
                echo "s. Show all networks               1. Show more details of a network"
                echo "2. Start a network                 3. Stop a network"
                echo "4. Create a NAT network            5. Create a macvtap network"      
                echo "6. Delete a network                7. Add a static ip to a network"
                echo "q. Back to main menu"
                echo ""
                read -ep "Enter your choice: " network_manage_choice

                case $network_manage_choice in
                    s)
                        # List all networks
                        virsh net-list --all
                        ;;

                    1)
                        # Show details of a network
                        read -ep "Enter the network name [default]: " network_name
                        if [ -z "$network_name" ]; then
                            network_name="default"
                        fi

                        virsh net-info "$network_name"
                        virsh net-dhcp-leases "$network_name"
                        ;;

                    2)
                        # Start a network
                        read -ep "Enter the name of the network to start: " network_name
                        virsh net-start "$network_name"
                        virsh net-autostart "$network_name"
                        ;;

                    3)
                        # Stop a network
                        read -ep "Enter the name of the network to stop: " network_name
                        virsh net-destroy "$network_name"
                        ;;

                    4)
                        # Prompt user for NAT network configuration
                        read -ep "Enter the new network name (e.g., natbr0): " network_name
                        read -ep "Enter the virtual bridge name (e.g., natbr0): " bridge_name
                        read -ep "Enter the new gateway ip address (e.g., 192.168.100.1): " network_ip
                        read -ep "Enter the new subnet mask (e.g., 255.255.255.0): " netmask
                        read -ep "Enter the starting ip for the DHCP range (e.g., 192.168.100.2): " dhcp_start
                        read -ep "Enter the ending ip for the DHCP range (e.g., 192.168.100.254): " dhcp_end

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
                        ;;

                    5) 
                        # Prompt user for macvtap network configuration
                        read -ep "Enter the new network name: " network_name
                        read -ep "Enter the physical network interface to attach: " int_name

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
                        ;;

                    6)
                        # Delete a network
                        read -ep "Enter the name of the network to delete: " delete_network_name
                        virsh net-destroy "$delete_network_name"
                        virsh net-undefine "$delete_network_name"
                        ;;

                    7)
                        # Add a static ip to a network
                        read -ep "Enter the virtual machines name: " vm_name
                        read -ep "Enter the virtual machines mac address: " vm_mac
                        read -ep "Enter the new ip address for the virtual machine: " vm_ip
                        read -ep "Enter the network name[default]: " vm_net

                        if [ -z "$vm_net" ]; then
                        vm_net="default"
                        fi

                        # Adds under dhcp line with new host info
                        sed -i '/<dhcp>/a \    <host mac="'$vm_mac'" name="'$vm_name'" ip="'$vm_ip'"/>' /etc/libvirt/qemu/networks/"$vm_net".xml

                        # Define new network xml
                        virsh net-define /etc/libvirt/qemu/networks/"$vm_net".xml
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
                echo -e "\n================== Manage Snapshot =================="
                echo "s. Show all snapshots of a VM   1. Create a snapshot"
                echo "2. Delete a snapshot            3. Revert to a snapshot"
                echo "q. Back to main menu"
                echo ""
                read -ep "Enter your choice: " snapshot_manage_choice

                case $snapshot_manage_choice in
                    s)
                        # List all snapshots of a virtual machine
                        read -ep "Enter the name of the virtual machine: " vm_name
                        virsh snapshot-list "$vm_name"
                        ;;
                    1)
                        # Create a snapshot of a virtual machine
                        read -ep "Enter the name of the virtual machine: " vm_name
                        read -ep "Enter the name for the new snapshot: " snapshot_name
                        virsh snapshot-create-as "$vm_name" "$snapshot_name"
                        ;;
                    2)
                        # Delete a snapshot of a virtual machine
                        read -ep "Enter the name of the virtual machine: " vm_name
                        read -ep "Enter the name of the snapshot to delete: " snapshot_name
                        virsh snapshot-delete "$vm_name" "$snapshot_name"
                        ;;
                    3)
                        # Revert to a snapshot of a virtual machine
                        read -ep "Enter the name of the virtual machine: " vm_name
                        read -ep "Enter the name of the snapshot to revert to: " snapshot_name
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
            # Edit Properties
            while true; do
                echo -e "\n====================== Edit Properties ======================"
                echo "1. Edit a VM            2. Edit a storage pool"
                echo "3. Edit a network       4. Edit a snapshot"
                echo "q. Back to main menu"
                echo ""
                read -ep "Enter your choice: " xml_manage_choice

                case $xml_manage_choice in
                    1)  
                        # edit a vm
                        read -ep "Enter the VM name: " vm_name
                        virsh edit $vm_name
                        ;;
                    2)
                        # edit a storage pool
                        read -ep "Enter the storage pool name: " pool_name
                        virsh pool-edit $pool_name
                        ;;
                    3)
                        # edit a network
                        read -ep "Enter the network name: " net_name
                        virsh net-edit $net_name
                        ;;
                    4)
                        # edit a snapshot
                        read -ep "Enter the VM name: " vm_name
                        read -ep "Enter the snapshot name: " snap_name
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

            # Firewall Settings
            while true; do
                echo -e "\n================== Firewall Settings =================="
                echo "s. Show ufw status         1. Show listening ports"
                echo "2. Allow port range        3. Deny port range"
                echo "4. Allow single port       5. Deny single port"
                echo "6. Delete a rule           7. Enable and reload ufw"
                echo "8. Disable and reset ufw   q. Back to main menu"
                echo ""
                read -ep "Enter your choice: " firewall_choice

                case $firewall_choice in
                    s)  
                        # Show ufw status
                        ufw status numbered
                        ;;
                    1)
                        # Show listening ports
                        netstat -l | grep "tcp\|udp"
                        ;;
                    2)
                        # Allow port range
                        read -ep "Enter starting port: " port_start
                        read -ep "Enter ending port: " port_end
                        ufw allow $port_start:$port_end/tcp
                        ufw reload
                        ;;
                    3)
                        # Deny Port range
                        read -ep "Enter starting port: " port_start
                        read -ep "Enter ending port: " port_end
                        ufw deny $port_start:$port_end/tcp
                        ufw reload
                        ;;
                    4)
                        # Allow single port
                        read -ep "Enter the port number: " port
                        ufw allow $port
                        ufw reload
                        ;;
                    5)
                        # Deny single port
                        read -ep "Enter the port number: " port
                        ufw deny $port
                        ufw reload
                        ;;
                    6)
                        # Delete a rule
                        read -ep "Enter the rule number to delete: " rule_number
                        ufw delete $rule_number
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
                        echo "Invalid choice. Please enter a valid option."
                        ;;
                esac
            done
            ;;
        7) 
            # Manage Port forwarding
            while true; do
                echo -e "\n=================== Manage Port Forwarding ==================="
                echo "s. Show port forwarding rules     1. List DHCP leases from a network"  
                echo "2. Add port forwarding to a VM    3. Remove port forwarding from a VM"
                echo "4. Edit port forwarding rule file q. Back to main menu"
                echo ""
                read -ep "Enter your choice: " port_choice

                case $port_choice in
                    s)  
                        # Show port forwarding ruless
                        iptables -t nat -L -n -v
                        ;;

                    1)
                        # List DHCP leases
                        read -ep "Enter the network name [default]: " network_name
                        if [ -z "$network_name" ]; then
                            network_name="default"
                        fi

                        virsh net-dhcp-leases "$network_name"
                        ;;

                    2)
                        # Add port forwarding rules to a VM behind a NAT
                        bash bashvm-port-forwarding.sh
                        ;;


                    3)
                        # Delete port forwarding rules of vm
                        read -ep "Enter the VM name: " vm_name

                        sed -i "/#$vm_name/,/###$vm_name/d" /etc/libvirt/hooks/qemu
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
                        echo "Invalid choice. Please enter a valid option."
                        ;;
                esac
            done
            ;;

        8)
            # System Monitor
            watch -n 1 bash bashvm-monitor.sh
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
