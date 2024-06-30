#!/bin/bash

read -ep "Enter the VM name: " domain

# Setting the virtual disk and virtual interface variables
disk=$(virsh domblklist $domain | grep v | awk '{print $1}')
interface=$(virsh domiflist $domain | grep v | awk '{print $1}')

# Setting the vcpu core count
cpu_count=$(virsh dominfo $domain | grep "CPU(s)" | awk '{print $2}')
# Counting starts at 0 so take away 1
cpu_count=$(( $cpu_count - 1 ))

# Loop through each core to output the usage
for ((i = 0; i <= $cpu_count; i++)); do
    # Begin init time of vcpu
    cpu_time_1=$(virsh domstats $domain | grep "vcpu.$i.time" | cut -d= -f2)
    # Sleep
    sleep 1
    # End of init time of vcpu
    cpu_time_2=$(virsh domstats $domain | grep "vcpu.$i.time" | cut -d= -f2)
    # Delta is to be equal of time between recordings
    delta_t=1
    # convert delta_t to nanoseconds
    delta_t_ns=$(echo "$delta_t * 1000000000" | bc)
    # Calculate the scaling factor
    scaling_factor=$(echo "scale=10; 100 / $delta_t_ns" | bc)
    # Calculate the individual core usage
    cpu_usage=$(echo "scale=2; (($cpu_time_2 - $cpu_time_1) * $scaling_factor)" | bc)
    echo "CPU $i Usage: $cpu_usage%"
done

echo ""
# Set the memory reported by the guest as being actively used
mem_rss=$(virsh domstats $domain | grep "balloon.rss" | cut -d= -f2)
# Set the memory reported by the guest as being available
mem_ava=$(virsh domstats $domain | grep "balloon.available" | cut -d= -f2)
# Calculate the usage percentage
memory_usage=$(echo "scale=2; ($mem_rss / ($mem_rss + $mem_ava)) * 100" | bc)
echo "Memory Usage: $memory_usage%"

echo ""
# Set the total allocated disk space
disk_total=$(virsh guestinfo $domain | grep fs.0 | grep "total" | cut -d: -f2)
# Set the used disk space
disk_used=$(virsh guestinfo $domain | grep fs.0 | grep "used" | cut -d: -f2)
# Calculate the percentage value of the used disk space
disk_usage=$(echo "scale=2; ($disk_used / $disk_total) * 100" | bc)
echo "Disk Usage: $disk_usage%"

echo ""
# Show the virtual interface assigned to the vm and output the usage
ifstat -i $interface 1 1
