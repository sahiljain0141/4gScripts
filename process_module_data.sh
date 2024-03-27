
process_bgp_data()
{
    local input_json="$1"
    local error="true"
    local match="true"
    
    # Extract "peer-address" values using awk
    peer_addresses=($(echo "$input_json" | awk -F'"remote-addr-config":' '{print $2}' | tr -d '," '))
    
    # Extract "peer-state" values using awk
    peer_states=($(echo "$input_json" | awk -F'"peer-state":' '{print $2}' | tr -d '," '))

    ######## Verify the state count for switch using function call#########
    verify_state_count "$switch" "${#peer_states[@]}" 

    for ((i=0; i<${#peer_addresses[@]}; i++)); do
      ###############Reset Value of match flag #############################
      local match="true"

      address="${peer_addresses[i]}"
      state="${peer_states[i]}"
      if [[ $state != "Established" ]]; then
        match="false"	
        printf "%-24s %s\n" "INCORRECT-STATE!!! peer_state: $state"   "peer_address: $address"
      fi

      if [[ $match == "false" ]];then
        printf "%-24s %s\n" "peer_state: $state"   "peer_address: $address"
      fi
    done

    if [[ $match == "true" ]];then
	     printf "%-24s \n" "SWITCH $switch is in CORRECT-STATE :)"
	     
    fi	
}  

process_ospf_data()
{
    local json_input=$1
    local match="true"

    # Extract "peer-address" and "peer-state" values using awk
    peer_addresses=($(echo "$json_input" | awk -F'"peer-address":' '{print $2}' | tr -d '," '))
    peer_states=($(echo "$json_input" | awk -F'"peer-state":' '{print $2}' | tr -d '," '))
    
    ######## Verify the state count for switch using function call#########
    match=$(verify_state_count "$switch" "${#peer_states[@]}")
    if [[ $match == "false" ]];then
	    echo "INCORRECT-STATE!!! state count mismatched for $switch"
: <<'COMMENT'
	    exec_cmd=${ssh_cmds["$MODULE"]}
	    METHOD="ssh"
	    switch_cmd "$switch" "${exec_cmd}"
	    return 1;
COMMENT

    fi


    for ((i=0; i<${#peer_addresses[@]}; i++)); do
        ###############Reset Value of match flag #############################
        match="true"
        ################# Extract address and state###########################
        address="${peer_addresses[i]}"
        state="${peer_states[i]}"
	
	if [[ $state != "full" ]]; then
          match="false"
	  printf "%-24s %s\n" "INCORRECT-STATE!!! peer_state: $state"   "peer_address: $address"
	fi

	if [[ $match == "false" ]];then
          printf "%-24s %s\n" "peer_state : $state"   "peer_address : $address"
	fi
    done

    if [[ $match == "true" ]];then
	     printf "%-24s \n" "SWITCH $switch is in CORRECT-STATE :)"
    fi	
} 
process_lldp_data()
{
    local input_json="$1"
    local error="true"
    local match="true"


echo "$input_json" | awk -F'[:,]' '{
  gsub(/[{}"[:space:]]/, "");
  for (i = 1; i <= NF; i++) {
    if ($i == "local-port" || $i == "remote-port-description" || $i == "rid" || $i == "age" || $i == "remote-chassis-mac" || $i == "remote-chassis-name" || $i == "remote-chassis-description" || $i == "remote-chassis-capability" || $i == "remote-chassis-primary-ip" || $i == "remote-port" || $i == "protocol" || $i == "ttl") {
      printf "%s%s", $(i+1), (i < NF - 1) ? "," : "\n";
    }
  }
}'
  
# Set the field order
field_order=("local-port" "remote-port-description" "rid" "age" "remote-chassis-mac" "remote-chassis-name" "remote-chassis-description" "remote-chassis-capability" "remote-chassis-primary-ip" "remote-port" "protocol" "ttl")

# Store values in an associative array
declare -A fields

# Process the JSON input
for field in "${field_order[@]}"; do
  value=$(echo "$input_json" | awk -F'[:,]' -v field="$field" '{ gsub(/[{}"[:space:]]/, ""); for (i = 1; i <= NF; i++) { if ($i == field) { print $(i+1) } } }')
  fields["$field"]=$value
done

# Print the table format
#for field in "${field_order[@]}"; do
#  printf "%-25s" "${fields[$field]}"
#done
echo  # Move to the next line after printing a row


}
#End of process_lldp_data  

process_evpn_es_data(){
     return 
}



process_interface_config_data() {
    echo "Processing interface configuration data"
}

process_interface_packet_statistics_data() {
    echo "Processing interface packet statistics data"
}

process_ipv4_interface_address_data() {
    echo "Processing IPv4 interface address data"
}

process_ipv6_interface_address_data() {
    echo "Processing IPv6 interface address data"
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

process_lacp_ports_data(){
    local json_data=$1
    local switch_name=$2
    local match="true"

    ############## Extract individual elements of the JSON array ######################
    interfaces=($(echo "$json_data" | awk -F'"interface":' '{print $2}' | tr -d '," '))
: <<'COMMENT'
     interfaces=($(echo "$json_data" | grep -o '"interface": "[^"]*' | awk -F'"' '{print $4}'))
     priorities=($(echo "$json_data" | grep -o '"priority": "[^"]*' | awk -F'"' '{print $4}'))
     partner_ports=($(echo "$json_data" | grep -o '"partner-port": "[^"]*' | awk -F'"' '{print $4}'))
COMMENT
    ports=($(echo "$json_data" | grep -o '"port": "[^"]*' | awk -F'"' '{print $4}'))
    lacp_modes=($(echo "$json_data" | grep -o '"lacp-mode": "[^"]*' | awk -F'"' '{print $4}'))
    states=($(echo "$json_data" | grep -o '"state": "[^"]*' | awk -F'"' '{print $4}'))
    system_ids=($(echo "$json_data" | grep -o '"system-id": "[^"]*' | awk -F'"' '{print $4}'))
    partner_ids=($(echo "$json_data" | grep -o '"partner-id": "[^"]*' | awk -F'"' '{print $4}'))
    partner_system_ids=$(echo "$json_data" | awk -F'"partner-system-id":' '{print $2}')
    partner_system_ids=($(echo "$json_data" | awk -F'"partner-system-id":' '{for(i=2;i<=NF;i++){gsub(/[,"]/,"",$i);print $i}}'))


    # Assuming $switch_name contains the name
    switch_ports["$switch_name"]=("${ports[@]}")

# Access the array using the switch_name
echo "Elements for switch $switch_name: ${switch_ports["$switch_name"][@]}"



    # Iterate over elements and print or process them
    for ((i=0; i<${#interfaces[@]}; i++)); do
        ###############Reset Value of match flag #############################
        match="true"
        if [[ ${states[i]} != "current" ]]; then
          match="false"
	  printf "%-30s %s\n" "INCORRECT-STATE!!! State : ${states[i]}" "Interface: ${interfaces[i]}, Port: ${ports[i]}"
	fi
        if [[ ${lacp_modes[i]} != "active" ]]; then
          match="false"
	  printf "%-30s %s\n" "INCORRECT-STATE!!! LACP Mode: ${lacp_modes[i]}" "Interface: ${interfaces[i]}, Port: ${ports[i]}"
	fi

	if [[ $match == "false" ]];then
		echo "Interface: ${interfaces[i]}, Port: ${ports[i]}, LACP Mode: ${lacp_modes[i]}, State: ${states[i]}, System ID: ${system_ids[i]}, PartnerSys ID: ${partner_system_ids[i]}, Partner ID: ${partner_ids[i]}"
	fi
      done

} 
#End of process_lacp_ports_data 

process_mclag_state_data() {
    echo "Processing MCLAG state data"
}

process_acl_stats_data() {
    echo "Processing ACL stats data"
}

