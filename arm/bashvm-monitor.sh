#!/bin/bash

read -ep "Enter the VM name: " vm_name

vm_check=$(virsh dominfo "$vm_name")
if [ ! $? == 0 ];then
    exit
fi

# Setting the virtual disk and virtual interface variables
disk=$(virsh domblklist $vm_name | grep v | awk '{print $1}')
interface=$(virsh domiflist $vm_name | grep v | awk '{print $1}')

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

echo ""
# Set the memory reported by the guest as being actively used
mem_rss=$(virsh domstats $vm_name | grep "balloon.rss" | cut -d= -f2)
# Set the memory reported by the guest as being available
mem_ava=$(virsh domstats $vm_name | grep "balloon.available" | cut -d= -f2)
# Calculate the usage percentage
memory_usage=$(echo "scale=2; ($mem_rss / ($mem_rss + $mem_ava)) * 100" | bc)
echo "Memory Usage: $memory_usage%"

echo ""
# Set the total allocated disk space
disk_total=$(virsh guestinfo $vm_name | grep fs.0 | grep "total" | cut -d: -f2)
# Set the used disk space
disk_used=$(virsh guestinfo $vm_name | grep fs.0 | grep "used" | cut -d: -f2)
# Calculate the percentage value of the used disk space
disk_usage=$(echo "scale=2; ($disk_used / $disk_total) * 100" | bc)
echo "Disk Usage: $disk_usage%"

echo ""
# Show the virtual interface assigned to the vm and output the usage
ifstat -i $interface 1 1
