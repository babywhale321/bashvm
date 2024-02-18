#!/bin/bash
echo ""
model=$(lscpu | grep "Model" | grep "name")
cpu=$(lscpu | grep "Core(s)")
mem=$(lsmem | grep Total | grep online | grep memory)

echo "Hostname: "$HOSTNAME""
echo ""$model" "$cpu""
echo $mem
echo "------------------------------------------------------------------------------------------------"
free -h
echo "------------------------------------------------------------------------------------------------"
sensors | grep Core
echo "------------------------------------------------------------------------------------------------"
iostat --human
echo ""
