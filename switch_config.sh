#!/bin/bash
ZONE=$1
TESTBED="false"
USER="operator"
PASSWORD="Operator@123"

# Read switch names and IPs from the configuration file
source switch_config_$ZONE.txt

# Validate the data
if [ "${#switch_names[@]}" -ne "${#switch_ips[@]}" ]; then
    echo "Error: Number of switch names and switch IPs should be the same."
    exit 1
fi

# Associative arrays to store switch information
declare -A switch_names_by_ip
declare -A switches_lo1_ip
declare -A switches_lo2_ip

# Populate associative arrays
for ((i=0; i<${#switch_names[@]}; i++)); do
    switch_name="${switch_names[$i]}"
    switch_ip="${switch_ips[$i]}"
    switches_lo1_ip["$switch_name"]=$switch_ip
    switches_lo2_ip["$switch_name"]="$(echo "$switch_ip" | awk -F. '{print $1"."$2"."$3"."($4+1)}')"
done

for ((i=0; i<${#switch_names[@]}; i++)); do
    switch_name="${switch_names[$i]}"
    switch_names_by_ip["${switches_lo1_ip["$switch_name"]}"]=${switch_name}
    switch_names_by_ip["${switches_lo2_ip["$switch_name"]}"]=${switch_name}
done 
