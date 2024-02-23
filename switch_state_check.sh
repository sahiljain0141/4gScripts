#!/bin/bash
METHOD="ssh"
MODULE="$1"      #Module Name for Which State is to be tracked
VERBOSE="false"  #Verbose will print the entire output
FILE=""
SWITCH_IP=""
SWITCH_NAME="all"
######################################## Declare Arrays ######################################
declare -A ssh_cmds
declare -A restapi_cmds
############## Declare CLI Commands here to be executed via SSH #################
ssh_cmds["ospf"]="show ip ospf neighbor"
ssh_cmds["bgp"]="show ip bgp neighbor"
ssh_cmds["lldp"]="show lldp neighbour brief"
ssh_cmds["interface_config"]="show interface configuration brief"
ssh_cmds["interface_packet_statistics"]="show interface packet-statistics"
ssh_cmds["ipv4_interface_address"]="show ipv4 interface address"
ssh_cmds["ipv6_interface_address"]="show ipv6 interface address"
ssh_cmds["ipv4_interface_statistics"]="show ipv4 interface statistics"
ssh_cmds["ipv6_interface_staticstics"]="show ipv6 interface-statistics"
ssh_cmds["resource_table"]="show system resource-table"
ssh_cmds["vrrp_detail"]="show vrrp detail"
ssh_cmds["copp"]="show copp statistics"
ssh_cmds["bridge_add_interface"]="show-bridge/aware-add-interface"
ssh_cmds["bridge_interface_detail"]="show-bridge/aware-interface/aware-interface-detail"
ssh_cmds["ospfv3_neighbors"]=" show ipv6 ospf neighbor"
ssh_cmds["sla_track"]="show ip sla track"
ssh_cmds["lacp_ports"]="lacp-ports"
ssh_cmds["mclag_state"]="mclag-state"
ssh_cmds["acl_stats"]="show access-lists statistics"

############## Declare HTTPS Commands here to be executed via RESTAPI #################
restapi_cmds["ospf"]="ip/ospf/all-ospf-neighbours"
restapi_cmds["bgp"]="ip/bgp/all-bgp-neighbours"
restapi_cmds["lldp"]="show-lldp/lldp/neighbour/detail"
restapi_cmds["interface_config"]="show-if/interface/configuration/detail"
restapi_cmds["interface_packet_statistics"]="show-if/interface/packet-statistics/detail"
restapi_cmds["ipv4_interface_address"]="ipv4/show-ipv4-interface/interface-ipv4-address-if?deep"
restapi_cmds["ipv6_interface_address"]="ipv6/show-ipv6-ipv6/interface-address-ipv6?deep"
restapi_cmds["ipv4_interface_statistics"]="ipv4/show-ipv4-interface/interface-statistics"
restapi_cmds["ipv6_interface_statistics"]="ipv6/show-ipv6-ipv6/ipv6-interface-statistics"
restapi_cmds["resource_table"]="configure-system/resource-table"
restapi_cmds["vrrp_detail"]="show-vrrp/vrrp/detail/detail"
restapi_cmds["copp_stats"]="copp/copp_statistics/copp-stats"
restapi_cmds["bridge_add_interface"]="show-bridge/aware-add-interface"
restapi_cmds["bridge_interface_detail"]="show-bridge/aware-interface/aware-interface-detail"
restapi_cmds["ospfv3_neighbors"]="ipv6/ospfv3/all-ospfv3-neighbours"
restapi_cmds["sla_track"]="ip/sla/track"
restapi_cmds["lacp_ports"]="lacp-ports"
restapi_cmds["mclag_state"]="mclag-state"
restapi_cmds["acl_stats"]="access-lists/l3-acl-rules/acl-statistics/acl-stats?deep"

############## Declare strings for extracting the json using awk for RESTAPI outputs #################

awk_string["bgp"]="router-bgp:all-bgp-neighbours"
awk_string["ospf"]="router-ospf:all-ospf-neighbours"
awk_string["lldp"]="show-lldp:detail"
awk_string["interface_config"]="show-interface:detail"
awk_string["interface_packet_statistics"]="show-interface:detail"
awk_string["ipv4_interface_address"]="show-ipv4:interface-ipv4-address-if"
awk_string["ipv6_interface_address"]="show-ipv6:interface-address-ipv6"
awk_string["ipv4_interface_statistics"]=""
awk_string["ipv6_interface_statistics"]=""
awk_string["resource_table"]="cdpm-sys:resource-table"
awk_string["vrrp_detail"]=""
awk_string["copp_stats"]="router-copp:copp-stats"
awk_string["bridge_add_interface"]=""
awk_string["bridge_interface_detail"]=""
awk_string["ospfv3_neighbors"]=""
awk_string["sla_track"]=""
awk_string["lacp_ports"]=""
awk_string["mclag_state"]=""
awk_string["acl_stats"]=""
awk_string["lacp_ports"]="bonding:lacp-ports"

############################### Declare Functions ######################################
########################## Below function prints the message in Red ####################
print_error(){
  text=$1
  RED='\033[0;31m'
  NC='\033[0m' # No Color

  echo -e "${RED}${text}${NC}"
}

########################## Below function prints the script help message  ####################

show_help() {
  echo "Usage: switch_state_check.sh <module_name> OPTIONS"
  echo "Supported Module Names : "
  echo "Options:"
  echo "  -m, --method <method_name>   Specify the get method (restapi, ssh)"
  echo "  -d, --debug <debug_flag>     Enable debugging (true/false)"
  echo "  -v, --verbose <verbose_flag> Enable verbose mode (true/false)"
  echo "  -s, --switch <switch_name>   Specify switch_names : spine1, spien2, leaf1, leaf2, leaf3, leaf"
  echo "  -f, --file   <true/false>    Will generate the output in txt file"
  echo "  -h, --help                   Display this help message"
  echo "  -e, --example                Will display examples" 
}

# Check the number of arguments
if [ "$#" -lt 1 ]; then
  show_help
  exit 1
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 1
fi

{
	if [[ -z $MODULE ]];then
		echo "Please enter the module name."
		exit 1
	fi
}

OPTIONS=$(getopt -o s:z:v:m:d: --long switch:zone:,method:,debug:,verbose: -n 'switch_state_check.sh' -- "$@")

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    -m|--method)
      METHOD="$2"
      shift 2
      ;;
   -s|--switch)
      SWITCH_NAME="$2"
      shift 2
      ;;
      
    -d|--debug)
      DEBUG="$2"
      shift 2
      ;;
    -z|--zone)
      ZONE="$2"
      shift 2
      ;;

    -v|--verbose)
      VERBOSE="$2"
      shift 2
      ;;
    -f|--file)
      FILE="$2"
      shift 2
      ;;
     
    -s|--switch)
      SWITCH_NAME="$2"
      shift 2
      ;;
 
    --)
      shift
      break
      ;;
    *)
      echo "Internal error!"
      exit 1
      ;;
  esac
done


echo "Argument for -m: $METHOD"
echo "Argument for -d: $DEBUG"
echo "Argument for -v: $VERBOSE"
echo "Argument for -f: $FILE"
echo "Argument for -z: $ZONE"
echo "Argument for -s: $SWITCH_NAME"



###########################SOurce Config File Containing Leaf and Spine Information#######
source switch_config.sh $ZONE


### Allow SSH to automatically accept new host keys without prompting for confirmation.####
# Define the SSH configuration settings
ssh_config="
Host *
    StrictHostKeyChecking no
"

# Set the SSH configuration as an environment variable
export SSH_CONFIG="$ssh_config"

######################## Declare Functions ###################################
tbswitch_cmd()
{
  local switch_name=$1
  local cmd=$2

    case $switch_name in
    "spine1")
        ip="10.145.3.0"
        ;;
    "spine2")
        ip="10.145.3.2"
        ;;
    "leaf1")
        ip="10.145.3.4"
        ;;
    "leaf2")
        ip="10.145.3.6"
        ;;
    "leaf3")
       ip="10.145.3.8"
        ;;
    "leaf4")
       ip="10.145.3.10"
       ;;
    esac

    SWITCH_IP=$ip

    if [[ "$METHOD" == "ssh" ]]; then
      switch_cmd="sshpass -p $PASSWORD ssh -q -o StrictHostKeyChecking=no $USER@$ip \"$cmd\""
      printf "%s \n" "------------------------- Executing Command----------------------------------"  
      printf "%s \n" "$switch_cmd"
      printf "%s \n" "-----------------------------------------------------------------------------"
      eval $switch_cmd
    else
      switch_cmd="curl -kisu $USER:$PASSWORD -X GET -H  \"Accept: application/vnd.yang.collection+json\" https://$ip/api/operational/$cmd"
      printf "%s \n" "------------------------- Executing Command----------------------------------"  
      printf "%s" "$switch_cmd"
      printf "%s" "--------------------------------------------------------------------------------"
      eval $switch_cmd
    fi


}

switch_cmd()
{
  local switch_name=$1
  local cmd=$2
  
  ####### Fech swithc_ip #################
  ip="${switches_lo1_ip[$switch_name]}"
  SWITCH_IP=$ip


  if [[ "$METHOD" == "ssh" ]]; then
    switch_cmd="sshpass -p $PASSWORD ssh -q -o StrictHostKeyChecking=no $USER@$ip \"$cmd\""
    if [[ "$DEBUG" == "true" ]];then
	    printf "%s \n" "------------------------- Executing Command----------------------------------"  
	    printf "%s \n" "$switch_cmd"
	    printf "%s \n" "-----------------------------------------------------------------------------"
    fi

    eval $switch_cmd 

  else
    switch_cmd="curl -kisu $USER:$PASSWORD -X GET -H  \"Accept: application/vnd.yang.collection+json\" https://$ip/api/operational/$cmd"
    if [[ "$DEBUG" == "true" ]];then
	    printf "%s \n" "------------------------- Executing Command----------------------------------"  
	    printf "%s" "$switch_cmd"
	    printf "%s" "--------------------------------------------------------------------------------"
    fi

    eval $switch_cmd
  fi

 } 

verify_state_count()
{
    local switch_name=$1
    local input_state_count=$2
    local state_count=0
    local match="true"

      echo "input_state_count: $2"
 
    if [[ $VERSBOSE == "-v" ]];then
      echo "input_state_count: $2"
    fi
    case $MODULE in
      "bgp")
        if [[ $switch_name == *"$spine"* ]]; then
          match=$( [ "$input_state_count" == "8" ] && echo "true" || echo "false" )
        else
          match=$( [ "$input_state_count" == "2" ] && echo "true" || echo "false" )
        fi	    
        ;;
      "ospf")
        if [[ $switch_name == *"$spine"* ]]; then
          match=$( [ "$input_state_count" == "6" ] && echo "true" || echo "false" )
        else
          match=$( [ "$input_state_count" == "2" ] && echo "true" || echo "false" )
        fi	   
        ;;
    esac

    echo "$match"
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
    match=$(verify_state_count "$switch" "${#peer_states[@]}") 

    if [[ $match == "false" ]];then
	    echo "INCORRECT_STATE!!! state count ${#peer_states[@]} mismatched for $switch"
    fi

    
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

process_ospf_data(){
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

declare -A switch_ports

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

if [[ -d $ZONE ]];then
  mkdir -p $ZONE
fi

###################################################################################################################################################
index=0 #SPINE1 INDEX
for switch in ${switch_names[@]}; do

OUTPUT_FILE="$ZONE/$MODULE_${switch}.txt"	
# Check if the SWITCH_NAME variable string has the switch	
if [[ !( "$SWITCH_NAME" =~ "$switch" || "$SWITCH_NAME" == "all" ) ]];then
   continue
fi	

# Read the entire content of the file into a variable
if [[ "$METHOD" == "restapi" ]];then
	exec_cmd=${restapi_cmds["$MODULE"]}
else
	exec_cmd=${ssh_cmds["$MODULE"]}
fi

############### EXCUTE COMMAND USING FUNCTION CALL ################################
output=$(switch_cmd "$switch" "${exec_cmd}")
echo $output > input.json
###################### Filter Json from Output #####################################
json_output=$(echo "$output" | awk '/{/,/}/')

printf "%-24s %s\n" "switch_name : $switch" "switch_lo1_ip : ${switches_lo1_ip[$switch]}"
printf "%-24s %s\n" "-----------------------" "-----------------------"

if [[ $VERBOSE == "true" ]];then
	# Echo Module Output Data #
	if [[ $METHOD == ssh ]];then
	  output=$(echo "$output" |  grep -v -e "Connection via ssh from VRF global (method: local)" -e "Running CLI command" -e "show" )
	fi
	echo "$output" 
	#> ${OUTPUT_FILE}
fi

process_${MODULE}_data "$json_output"
printf "%-24s %s\n" "-----------------------" "-----------------------"

index=$(( index+1 ))

: <<'COMMENT'
# Extract the lines containing the JSON-like content for the given key
json_lines=$(echo "$input" | awk '/"${awk_string[$MODULE]}"/{flag=1} flag; /\}/{flag=0}' RS="")
echo "----------------------------------------------------------"
echo "json_lines : $json_lines" 

# Remove leading asterisks and TLSv1.2 lines
cleaned_json=$(echo "$json_lines" | sed -e '/^\*/d' -e '/^$/d')
echo "$cleaned_json"
COMMENT

done

