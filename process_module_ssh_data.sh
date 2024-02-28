process_ospf_data() {
   local output=$1
   echo "$output"
}

process_bgp_data()
{
    local output=$1
    echo "$output"

}

process_evpn_es_data() {
    local output=$1
    echo "$output"
}

process_lldp_data() {
    local output="$1"
    local line=""
    local file="trichy/lldp_leaf1.txt"
    local header_printed=false

    local neighbour=""
    local port_description=""
    local chassis_mac=""
    local chassis_name=""
    local protocol=""

    printf "%-15s %-40s %-20s %-20s %-8s\n" "Neighbour" "Port Description" "Chassis MAC" "Chassis Name" "Protocol"
    printf "%-15s %-40s %-20s %-20s %-8s\n" "---------" "----------------" "------------" "------------" "--------"

    while IFS= read -r line; do
        if [[ $line =~ ^lldp\ neighbour\ brief\ (.+) ]]; then
            neighbour="${BASH_REMATCH[1]}"
	    neighbour=$(echo "${neighbour}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        elif [[ $line =~ ^\ +remote-port-description\ (.+) ]]; then
            port_description="${BASH_REMATCH[1]}"
	    port_description=$(echo "${port_description}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        elif [[ $line =~ ^\ +remote-chassis-mac\ (.+) ]]; then
            chassis_mac="${BASH_REMATCH[1]}"
	    chassis_mac=$(echo "${chassis_mac}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        elif [[ $line =~ ^\ +remote-chassis-name\ (.+) ]]; then
            chassis_name="${BASH_REMATCH[1]}"
	    chassis_name=$(echo "${chassis_name}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        elif [[ $line =~ ^\ +protocol\ (.+) ]]; then
            protocol="${BASH_REMATCH[1]}"
            protocol=$(echo "${protocol}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            printf "%-15s %-40s %-20s %-20s %-8s\n" "$neighbour" "$port_description" "$chassis_mac" "$chassis_name" "$protocol"

	fi
    done < "$file"  
    ###<<< "$output"
}


process_interface_config_data() {
    echo "Processing interface configuration data"
    local output=$1
    echo "$output"
}

process_interface_packet_statistics_data() {
    echo "Processing interface packet statistics data"
    local output=$1
    echo "$output"


}

process_ipv4_interface_address_data() {
    echo "Processing IPv4 interface address data"
    local output=$1
    echo "$output"

}

process_ipv6_interface_address_data() {
    local output="$1"
    local interface=""
    local address=""
    local prefix_length=""
    local address_type=""
    local address_status=""

    # Check if the output is empty
    if [ -z "$output" ]; then
        echo "No data to process."
        return
    fi

    # Print table header
    printf "%-20s %-45s %-15s %-15s %-15s\n" "Interface" "Address" "Prefix Length" "Address Type" "Address Status"
    printf "%-20s %-45s %-15s %-15s %-15s\n" "---------" "-------" "-------------" "------------" "--------------"

    # Loop through each line of the output
    while IFS= read -r line; do
        # Check if the line starts with "ipv6 interface-address"
        if [[ $line =~ ^ipv6\ interface-address\ (.+) ]]; then
            interface="${BASH_REMATCH[1]}"
        elif [[ $line =~ ^\ ([a-f0-9:]+)$ ]]; then
            address="${BASH_REMATCH[1]}"
        elif [[ $line =~ prefix-length\ +([0-9]+)$ ]]; then
            prefix_length="${BASH_REMATCH[1]}"
        elif [[ $line =~ address-type\ +(.+)$ ]]; then
            address_type="${BASH_REMATCH[1]}"
        elif [[ $line =~ address-status\ +(.+)$ ]]; then
            address_status="${BASH_REMATCH[1]}"
            # Print the data in table format
            printf "%-20s %-45s %-15s %-15s %-15s\n" "$interface" "$address" "$prefix_length" "$address_type" "$address_status"
            # Reset variables for the next entry
            interface=""
            address=""
            prefix_length=""
            address_type=""
            address_status=""
        fi
    done <<< "$output"
}


process_ipv4_interface_statistics_data() {
    echo "Processing IPv4 interface statistics data"
}

process_ipv6_interface_staticstics_data() {
    echo "Processing IPv6 interface statistics data"
}

process_resource_table_data() {
    echo "Processing resource table data"
}

process_vrrp_detail_data() {
    echo "Processing VRRP detail data"
}

process_copp_data() {
    echo "Processing COPP data"
}

process_bridge_add_interface_data() {
    echo "Processing bridge add interface data"
}

process_bridge_interface_detail_data() {
    echo "Processing bridge interface detail data"
}

process_ospfv3_neighbors_data() {
    echo "Processing OSPFv3 neighbors data"
}

process_sla_track_data() {
    echo "Processing SLA track data"
}

process_lacp_ports_data() {
    echo "Processing LACP ports data"
}

process_mclag_state_data() {
    echo "Processing MCLAG state data"
}

process_acl_stats_data() {
    echo "Processing ACL stats data"
}

