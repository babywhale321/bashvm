#!/bin/bash
#
#bashvm.com
#
#Author: Kyle Schroeder "BabyWhale"

# Manage Resources of a VM
while true; do
    echo -e "\n=================================== Manage Resources ==================================="
    echo "s. Show resources of a VM             1. Add disk space to a VM     2. Shrink disk space of a VM"
    echo "3. Change the number of vcpu in a VM  4. Change the memory of a VM  5. Attach a disk to a VM"
    echo "6. Detach a disk from a VM            7. Attach Network to a VM     8. Detach Network from a VM"
    echo "q. Back to main menu"
    echo ""
    read -ep "Enter your choice: " manage_choice

    case $manage_choice in
        s)
            # Show resources of a VM
            read -ep "Enter the VM name: " vm_name

            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            virsh dominfo "$vm_name"
            virsh domfsinfo "$vm_name"
            virsh domblkinfo "$vm_name" --all --human
            ;;

        1)
            # Add disk space to a VM
            read -ep "Enter the name of the virtual machine: " vm_name
            
            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            # Check VM state
            vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
            if [ "$vm_state" == "running" ]; then
                echo "Please shutdown the VM before running this action."
                continue
            fi

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
            
            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            # Check VM state
            vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
            if [ "$vm_state" == "running" ]; then
                echo "Please shutdown the VM before running this action."
                continue
            fi

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

            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            # Check VM state
            vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
            if [ "$vm_state" == "running" ]; then
                echo "Please shutdown the VM before running this action."
                continue
            fi

            read -ep "Enter the new vcpu number (e.g., 4): " vcpu_num
            virsh setvcpus --domain "$vm_name" --count "$vcpu_num" --config --maximum
            if [ ! $? == 0 ]; then
                echo "Failed to set new vcpu maximum"
                break
            fi
            virsh setvcpus --domain "$vm_name" --count "$vcpu_num" --config
            if [ ! $? == 0 ]; then
                echo "Failed to set new vcpu count"
                break
            fi
            echo "New vcpu count has been set successfully"
            ;;

        4)
            # Change memory
            read -ep "Enter the name of the virtual machine: " vm_name

            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            # Check VM state
            vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
            if [ "$vm_state" == "running" ]; then
                echo "Please shutdown the VM before running this action."
                continue
            fi

            read -ep "Enter the new memory size (e.g., 1GB): " mem_num
            virsh setmaxmem --domain "$vm_name" --size "$mem_num" --current
            if [ ! $? == 0 ]; then
                echo "Failed to set new memory maximum"
                break
            fi
            virsh setmem --domain "$vm_name" --size "$mem_num" --current
            if [ ! $? == 0 ]; then
                echo "Failed to set new memory size"
                break
            fi
            echo "New memory size has been set successfully"
            ;;

        5)
            # Attach a disk to a VM
            read -ep "Enter the name of the virtual machine: " vm_name

            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            # Check VM state
            vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
            if [ "$vm_state" == "running" ]; then
                echo "Please shutdown the VM before running this action."
                continue
            fi

            read -ep "Enter the new target device: (e.g., vdb): " vm_target
            read -ep "Enter the qcow2 virtual disk name: (e.g., /var/lib/libvirt/images/vm1.qcow2): " vm_qcow2
            virsh attach-disk "$vm_name" "$vm_qcow2" "$vm_target" --current --subdriver qcow2
            ;;

        6)
            # Detach a disk from a VM
            read -ep "Enter the name of the virtual machine: " vm_name
            
            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            # Check VM state
            vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
            if [ "$vm_state" == "running" ]; then
                echo "Please shutdown the VM before running this action."
                continue
            fi

            read -ep "Enter the qcow2 virtual disk name: (e.g., /var/lib/libvirt/images/vm1.qcow2): " vm_qcow2
            virsh detach-disk "$vm_name" "$vm_qcow2" --current
            ;;

        7)
            # Attach network to a VM
            read -ep "Enter the name of the virtual machine: " vm_name

            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            # Check VM state
            vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
            if [ "$vm_state" == "running" ]; then
                echo "Please shutdown the VM before running this action."
                continue
            fi

            read -ep "Enter the name of the network to attach: " network_name
            NETWORK_XML="/tmp/${network_name}-network.xml"
            cat > "$NETWORK_XML" <<EOF
<interface type='network'>
    <source network='${network_name}'/>
    <model type='e1000'/>
</interface>
EOF
            virsh attach-device "$vm_name" "$NETWORK_XML" --config
            rm -f "$NETWORK_XML"
            ;;

        8)
            # Detach network from a VM
            read -ep "Enter the name of the virtual machine: " vm_name

            # If the vm name is empty then don't continue
            if [ -z "$vm_name" ]; then
                echo "Invalid response. Please enter a VM name."
                continue
            fi

            # Check if VM exists
            if ! virsh dominfo "$vm_name" &>/dev/null; then
                echo "'$vm_name' not found. Please enter a valid VM name."
                continue
            fi

            # Check VM state
            vm_state=$(virsh list --all | grep "$vm_name" | awk '{print $3}')
            if [ "$vm_state" == "running" ]; then
                echo "Please shutdown the VM before running this action."
                continue
            fi

            read -ep "Enter the name of the network to detach: " network_name
            NETWORK_XML="/tmp/${network_name}-network.xml"
            cat > "$NETWORK_XML" <<EOF
<interface type='network'>
    <source network='${network_name}'/>
    <model type='e1000'/>
</interface>
EOF
            virsh detach-device "$vm_name" "$NETWORK_XML" --config
            rm -f "$NETWORK_XML"
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
