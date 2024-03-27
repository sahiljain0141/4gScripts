#!/bin/bash
#set -x
METHOD="restapi"
MODULE="$1"      #Module Name for Which State is to be tracked
VERBOSE="false"  #Verbose will print the entire output
FILE=""
SWITCH_IP=""
SWITCH_NAME="all"
DEBUG="false"
ZONE=""
CONSOLE_OUTPUT="false"

####################################### Install Pre-requisites #############################
# Path to the script
SCRIPT_PATH="./install_prereq.sh"

# Check if the script exists
if [ -f "$SCRIPT_PATH" ]; then
    echo "Checking dependencies and installing them if not already installed."
    # Execute the script
    bash "$SCRIPT_PATH"
else
    echo "Error: Script $SCRIPT_PATH not found."
    exit 1
fi
######################################## Declare Arrays ######################################
declare -A ssh_cmds
declare -A restapi_cmds
####################################### Declare modules ######################################
modules=("ospf" "bgp" "evpn_es" "lldp" "interface_config" "interface_packet_statistics" "ipv4_interface_address" "ipv6_interface_address" "ipv4_interface_statistics" "ipv6_interface_staticstics" "resource_table" "vrrp_detail" "copp_stats" "bridge_add_interface" "bridge_interface_detail" "ospfv3_neighbors" "sla_track" "lacp_ports" "mclag_state" "acl_stats")


############## Declare CLI Commands here to be executed via SSH #################
ssh_cmds["ospf"]="show ip ospf neighbor"
ssh_cmds["bgp"]="show ip bgp neighbor"
ssh_cmds["evpn_es"]="show l2vpn evpn es"
ssh_cmds["lldp"]="show lldp neighbour brief"
ssh_cmds["interface_config"]="show interface configuration brief"
ssh_cmds["interface_packet_statistics"]="show interface packet-statistics"
ssh_cmds["ipv4_interface_address"]="show ipv4 interface address"
ssh_cmds["ipv6_interface_address"]="show ipv6 interface-address"
ssh_cmds["ipv4_interface_statistics"]="show ipv4 interface statistics"
ssh_cmds["ipv6_interface_staticstics"]="show ipv6 interface-statistics"
ssh_cmds["resource_table"]="show system resource-table"
ssh_cmds["vrrp_detail"]="show vrrp detail"
ssh_cmds["copp_stats"]="show copp statistics"
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
restapi_cmds["evpn_es"]=""
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
### Below function prints the message in Red ###
RED='\033[0;31m'
NC='\033[0m' # No Color


print_error(){
  text=$1
  echo -e "${RED}${text}${NC}"
}

moduledump()
{
	for module in "${modules[@]}"; do
		echo " - $module"
	done
}
### Below function prints the script help message  ###

show_help() {
  echo "Usage: switch_state_check.sh <module_name> OPTIONS"
  echo "Supported Module Names : "
  ####### Call function ############ 
  moduledump 
  echo "Supported Options:"
  echo "  -c, --console <console_flag> Dump output to console (true/false)"
  echo "  -m, --method <method_name>   Specify the get method (default : restapi) (restapi(json output), ssh (cli tablular output)"
  echo "  -d, --debug <debug_flag>     Enable debugging (true/false)"
  echo "  -v, --verbose <verbose_flag> Enable verbose mode (true/false)"
  echo "  -s, --switch <switch_name>   Specify switch_names : spine1, spine2, leaf1, leaf2, leaf<n>"
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
		echo "List of modules : "
		echo "${modules[@]}"
		exit 1
	fi
}

OPTIONS=$(getopt -o c:s:z:v:m:d: --long console:,switch:,zone:,method:,debug:,verbose: -n '$0' -- "$@")

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    -c|--console)
      CONSOLE_OUTPUT="$2"
      shift 2
      ;;
  
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


echo "Argument for -m, --method: $METHOD"
echo "Argument for -d, --debug: $DEBUG"
echo "Argument for -v, --verbose: $VERBOSE"
echo "Argument for -z, --zone: $ZONE"
echo "Argument for -s, --switch: $SWITCH_NAME"
echo "Argument for -c, --console: $CONSOLE_OUTPUT"


###########################SOurce Config File Containing Leaf and Spine Information#######
source switch_config.sh $ZONE



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
  
  ####### Fetch switch_ip #################
  ip="${switches_lo1_ip[$switch_name]}"
  SWITCH_IP=$ip


  if [[ "$METHOD" == "ssh" ]]; then
    switch_cmd="sshpass -p $PASSWORD ssh -q -o StrictHostKeyChecking=no $USER@$ip \"$cmd\""
    if [[ "$DEBUG" == "true" ]];then
	    printf "%s \n" "------------------------- Executing Command----------------------------------"  
	    printf "%s \n" "${switch_cmd}"
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
        if [[ "$switch_name" == *"spine"* ]]; then
          match=$( [ "$input_state_count" == "8" ] && echo "true" || echo "false" )
        else
          match=$( [ "$input_state_count" == "2" ] && echo "true" || echo "false" )
       	fi	    
        ;;

      "ospf")
        if [[ $switch_name == *"spine"* ]]; then
          match=$( [ "$input_state_count" == "6" ] && echo "true" || echo "false" )
        else
          match=$( [ "$input_state_count" == "2" ] && echo "true" || echo "false" )
        fi	   
        ;;
    esac

    if [[ "$match" == "false" ]];then
            print_error "INCORRECT_STATE_COUNT!!! state count $input_state_count mismatched for $switch_name"
    fi

}

######################  Source file containing functions for processing module json data ######
if [[ "$METHOD" == "restapi" ]];then
   source process_module_data.sh
fi
######################  Source file containing functions for processing module ssh data ######
if [[ "$METHOD" == "ssh" ]];then
   source process_module_ssh_data.sh
fi



declare -A switch_ports


if [[ ! ( -d $ZONE ) ]];then
  mkdir -p $ZONE
fi

if [[ ! ( -d $ZONE/$MODULE ) ]];then
  mkdir -p $ZONE/$MODULE
else
  # Remove already existing files	
  rm -r $ZONE/$MODULE/*
fi


###################################################################################################################################################
index=0 #SPINE1 INDEX
for switch in ${switch_names[@]}; do

if [[ "${CONSOLE_OUTPUT}" ==  "true" ]]; then
	OUTPUT_FILE="/dev/stdout"
else
        OUTPUT_FILE="${ZONE}/${MODULE}/${MODULE}_${switch}.txt"
fi

# Check if the SWITCH_NAME variable string has the switch	
if [[ !( "$SWITCH_NAME" =~ "$switch" || "$SWITCH_NAME" == "all" ) ]];then
   continue
fi	

switch_ip="${switches_lo1_ip["$switch"]}"

# Read the entire content of the file into a variable
if [[ "$METHOD" == "restapi" ]];then
	exec_cmd=${restapi_cmds["$MODULE"]}
else
	exec_cmd=${ssh_cmds["$MODULE"]}
fi

############### EXCUTE COMMAND USING FUNCTION CALL ################################
if [[ "$METHOD" == "restapi" && "$MODULE" == "evpn_es" && "$switch" == "leaf"* ]];then
       /bin/bash evpn_es.sh --ip "${switch_ip}" --username "${USER}" --password "${PASSWORD}" --output_file "${OUTPUT_FILE}" -d "${DEBUG}"
else
  output=$(switch_cmd "$switch" "${exec_cmd}")
  echo $output > input.json
  ###################### Filter Json from Output #####################################
  json_output=$(echo "$output" | awk '/{/,/}/')
fi

printf "%-24s %s\n" "switch_name : $switch" "switch_lo1_ip : ${switches_lo1_ip[$switch]}"
printf "%-24s %s\n" "-----------------------" "-----------------------"

# Echo Module Output Data #
if [[ "$METHOD" == "ssh" ]];then
	if [[ "$DEBUG_TRUE" == "true" ]];then
		output=$(echo "$output" |  grep -v -e "Connection via ssh from VRF global (method: local)" -e "Running CLI command" )
	else
		output=$(echo "$output" |  grep -v -e "Connection via ssh from VRF global (method: local)" -e "Running CLI command" -e "show")

	fi
	
	  
	 process_${MODULE}_data "$output" >> "${OUTPUT_FILE}"
else
  process_${MODULE}_data "$json_output"
  echo "${json_output}" >> "${OUTPUT_FILE}"
fi

if [[ "$CONSOLE_OUTPUT" == "false" ]];then
	echo "output saved at : ${OUTPUT_FILE}"
fi

printf "%-24s %s\n" "-----------------------" "-----------------------"

index=$(( index+1 ))

done

if [[ "${CONSOLE_OUTPUT}" ==  "false" ]]; then
	source compare_module_data.sh
        ### Call function to compare leaf pair data for input module ###
	compare_${MODULE}_data
fi
 
