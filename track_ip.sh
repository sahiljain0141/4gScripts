#!/bin/bash

#set -x

# Replace with your actual credentials and IP address
OUTPUT_FILE=track.txt
DEFAULT_VNI="20000"

############################### Declare Functions ######################################
########################## Below function prints the message in Red ####################
print_error(){
  text=$1
  RED='\033[0;31m'
  NC='\033[0m' # No Color

  echo -e "${RED}${text}${NC}"
}


Ip2Regex()
{
  ip=$1
  # Remove any trailing dots from the input ip
  user_input=$(echo "$ip" | sed 's/\.$//')
  # Convert the input into a regular expression pattern
  regex_pattern=$(echo "$user_input" | awk -F '.' '{
  # Initialize the regex pattern
  pattern = "^"

    # Loop through each octet
    for (i = 1; i <= NF; i++) {
	    # If the octet is "*", append a regex pattern to match any number
	    if ($i == "*" && i == NF) {
		    pattern = pattern "[0-9]+"
	    }
    # Otherwise, append the exact octet value
else {
	pattern = pattern $i
}

	# Append a dot if this is not the last octet
	if (i < NF) {
		pattern = pattern "\\."
	}
}

    # Append the end-of-line anchor
    pattern = pattern "$"

    # Print the constructed regex pattern
    print pattern
}')

  echo "$regex_pattern" 
}



########################## Below function prints the script help message  ####################

show_help() {
  echo "Usage   : ./track_ip.sh <ip/subnet> <Options> "
  echo "Example : ./track_ip.sh 10.145.30 -z chandigarh -s leaf1 {will track only for leaf1}"
  echo "Example : ./track_ip.sh 10.145.32.100,10.145.32.25 -z haryana {will track for all leaf switches}"
  echo "Example : ./track_ip.sh 10.62.2.100 -z trichy -s leaf1,leaf2 {will track only for leaf1,leaf2}"
  echo "Options:"
  echo "  -z, --zone <zone_name>       Specify the zone name : chandigarh, haryana, tirchy .."
  echo "  -d, --debug <debug_flag>     Enable debugging (true/false)"
  echo "  -v, --verbose <verbose_flag> Enable verbose mode (true/false)"
  echo "  -s, --switch <name>          Specify one of switch_names : ${switch_names[@]}"
  echo "  -h, --help                   Display this help message"
}

# Check the number of arguments
if [ "$#" -lt 1 ]; then
  show_help
  exit 1
elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
  exit 1
fi

OPTIONS=$(getopt -o z:m:d:s: --long zone:,debug:,verbose:,switch: -n 'track_ip.sh' -- "$@")

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    -z|--zone)
      ZONE="$2"
      shift 2
      ;;
    -d|--debug)
      DEBUG="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE="$2"
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

TRACK_IP="$1"

########## Arguments Sanity Check ####################

if [[ -z $ZONE ]];then
	echo "Please enter the zone name."
	exit 1
fi

######################Source Switch Configuration ######################
source switch_config.sh $ZONE
num_switches=${#switch_names[@]}
num_leafs=$(( num_switches - 2))
debug=$DEBUG


echo "Tracking IP/Subnet : $TRACK_IP"
echo "for zone: $ZONE"
if [[ -z $SWITCH_NAME ]]; then
	echo "for switch : ${switch_names[@]}"
	SWITCH_NAME="all"
else
	echo "for switch: $SWITCH_NAME"
fi

keys=("tracked_ip" "local_or_remote" "vlan" "vni" "mac_address" "esid" "es_local_ips" "leaf_names" "bundle_id" "switch_ip" "ping_loss")

# Function to check if a value exists in an array
function contains_element() {
	local e
	for e in "${@:2}"; do
		[[ "$e" == "$1" ]] && return 0
	done
	return 1
}

######################Source Switch Configuration ######################
source switch_config.sh $ZONE

num_switches=${#switch_names[@]}
num_leafs=$(( num_switches - 2))
debug=$DEBUG

##### Create Output directory for each zone ##########################
if [[ ! (-d $ZONE) ]]; then
	mkdir $ZONE
fi

################## Loop through each leaf switch #######################
for ((leaf_idx=1; leaf_idx <= ${num_leafs}; leaf_idx++)); do

 if [[ ! ("$SWITCH_NAME" =~ "leaf${leaf_idx}" || "$SWITCH_NAME" == "all") ]];then
	 continue
 fi

 echo "------------ Tracking for leaf${leaf_idx}----------------"
# Reset variable values
 vlan=""
 vni=()
 declare -a esid
 remote_ip_addresses=()
 ips=("" "")
 elements=("" "")
 local_or_remote=()
 mac_address=()
 loss_percentage=()
 es_or_bundle=()
 track_ips=()
 l2vpn_cmd=()
 mac_cmd=()
 unique_vnis=()
 vlan_output=()
 ip_output=()
 next_hop_cmd=()
 grep_cmd=()
 ping_cmd=()
 time=()
 # Define an associative array for each leaf
 declare -A leaf_data
 leaf=()

  ############## Check if TRACK_IP contains multiple IPs separated by commas ####################
  if [[ $TRACK_IP == *,* ]]; then
	  # Split the string by commas into an array
	  IFS=', ' read -r -a ip_array <<< "$TRACK_IP"
	  tracking_ip_count=${#ip_array[@]}
	  # Print each IP in the array
	  for ip in "${ip_array[@]}"; do
		  #grep_cmd+=("grep -w $ip")
		  grep_cmd+=("grep -e $ip")
	  done
  else
	  grep_cmd+=("grep -e $TRACK_IP")
	  #grep_cmd+=("grep -w $TRACK_IP")
  fi

 ############# Fetch SWITCH_IP and LEAF_NAME ##############################
 SWITCH_IP=${switches_lo2_ip["leaf${leaf_idx}"]}
 leaf_name=${switch_names_by_ip[${SWITCH_IP}]}

 if [[ $debug == "true" ]]; then
  echo "SWITCH_IP : $SWITCH_IP"
 fi 
 ###############Delete Already existing Output File#######################
 # Define file paths
 SSH_CMD_OUTPUT_FILE="$ZONE/leaf${leaf_idx}_ssh_command_output.txt"
 TRACK_OUTPUT_FILE="$ZONE/leaf${leaf_idx}_track_output.txt"
 DEBUG_OUTPUT_FILE="$ZONE/leaf${leaf_idx}_debug_output.txt"

 # Remove files if they exist
 [[ -f $TRACK_OUTPUT_FILE ]] && rm "$TRACK_OUTPUT_FILE"
 [[ -f $SSH_CMD_OUTPUT_FILE ]] && rm "$SSH_CMD_OUTPUT_FILE"
 [[ -f $DEBUG_OUTPUT_FILE ]] && rm "$DEBUG_OUTPUT_FILE"

 # Create empty files using tee
 touch "$TRACK_OUTPUT_FILE" "$SSH_CMD_OUTPUT_FILE" "$DEBUG_OUTPUT_FILE"
 
 next_hop_cmd+=("show ip next-hops global")
  
 if [[ $debug  == "true" ]];then
	 {
		 echo "Executing command : ${next_hop_cmd[@]}"
		 echo "Grep String       : ${grep_cmd[@]}"
	 } >> "${DEBUG_OUTPUT_FILE}" 
 fi

   
 ########### Execute show ip next-hops global over SSH ####################################################
 {
     output=$(sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no "$USER@${SWITCH_IP}" "${next_hop_cmd[@]}")
     for cmd in "${grep_cmd[@]}"; do
	     grep_output=$(echo "$output" | eval "$cmd")
	     # Process the grep output as needed
	     echo "$grep_output"
     done
  } >> "${SSH_CMD_OUTPUT_FILE}"

  # Read each line from the file and append it to the variable
  while IFS= read -r line; do
	  vlan=("$(echo "$line" | awk '/bvi/ {print $5}' | cut -d'.' -f2)")
      	  ip=$(echo "$line" | awk '/bvi/ {print $4}')

 	  if [[ -n $ip ]]; then  # Check if ip is not empty
		  ip_output+=("$ip")
	  fi
	
	  if [[ -n $vlan ]]; then  # Check if VLAN is not empty
		  vlan_output+=("$vlan")  # Append VLAN to the array
		  vni=$(( DEFAULT_VNI + vlan ))
		  if ! contains_element "$vni" "${unique_vnis[@]}"; then
			  unique_vnis+=("$vni")
			  l2vpn_cmd+=("show l2vpn evpn arp-cache vni ${vni};")
			  mac_cmd+=("show layer2 mac-address | include ${vni};")
		  fi

	  fi
  done < "${SSH_CMD_OUTPUT_FILE}"

  if [[ ${#vlan_output[@]}  -ne ${#ip_output[@]}  ]]; then
	  echo "IP and VLAN Count Mismatch"
	  echo "vlan_output        : "
	  echo "${vlan_output[@]}"
	  echo "ip_output          : " 
	  echo "${ip_output[@]}"
	  exit 1
  fi
	
  ###### Copy all the scanned IPs in ip_array ################
  ip_array=("${ip_output[@]}")
	
  i=0 #### Initilise variable i to zero ##################
  for ip in "${ip_array[@]}"; do
	    ping_cmd+=("ping count 1 $ip source $SWITCH_IP;")
	    track_ips+=("$ip")
	    i=$(( i+1 ))
  done

  if [[ $debug == "true" ]]; then
    {
     echo "-----------------------------------tracking ips--------------------------------"
     echo "${ip_array[@]}"
     echo "----------------------------------- unique_vnis--------------------------------- " 
     echo "${unique_vnis[@]}"
   } >> "${DEBUG_OUTPUT_FILE}"
  fi


  cmd="${l2vpn_cmd[@]} ${mac_cmd[@]} show l2vpn evpn es;" 
  ping_string="${ping_cmd[@]}"

  if [[ $debug == "true" ]]; then
	  {
		  echo "Executing Command: $cmd" 
	  } >> "${DEBUG_OUTPUT_FILE}"
  fi        

  ########## Execute Command over SSH #################################
  {
   output=$(sshpass -p "$PASSWORD" ssh -q -o StrictHostKeyChecking=no "$USER@${SWITCH_IP}" "$cmd")
   echo "$output"
  } >> "${SSH_CMD_OUTPUT_FILE}"

  ######### Execute Ping Command Over SSH Uusing Python Utility paramiko ##########
  python3 ssh_command.py ${SWITCH_IP} "${ping_string}" "${SSH_CMD_OUTPUT_FILE}"
  
  ##############################################################################################################################

 {
  printf "%-20s %s\n" "LeafName: $leaf_name" "LeafIP: ${SWITCH_IP}"
  printf "%-15s | %-12s | %-6s | %-24s | %-34s | %-30s | %-20s | %-10s | %-10s | %-20s\n" \
	    "Tracked IP" "Local/Remote" "VNI" "MAC Address" "ES ID" "ES Local IPs" "Leaf Names" "Bundle ID" "Ping Loss" "Time"
  printf "%s\n" "-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
} >> "${TRACK_OUTPUT_FILE}"

  i=-1
  for ip in ${ip_array[@]}; do	  

	#############Increment the value of i ########################
	i=$((i + 1))
	##############################################################

 	  ip_lines=$(echo "$output" | grep -w "$ip" | grep -v -e "ping count 1" -e "stop on error" -e "PING" -e "ping" -e "icmp_seq")
	  ########## Extract local_or_remote_value for the current IP #################
	  local_or_remote_value=$(echo "$ip_lines" | awk '/active/ {print $2}')
          # Append the local_or_remote value to the array
	  local_or_remote+=("$local_or_remote_value")

	  # Extract MAC address using awk
	  if [[ $local_or_remote_value == "local" ]]; then
		mac_address+=("$(echo "$ip_lines" | awk '/active/ {print $5}')")
	  else
		mac_address+=("$(echo "$ip_lines" | awk '/active/ {print $4}')")
	  fi

         
	  mac_line=$(echo "$output" | grep -w ${mac_address[$i]} )
	  # Extract VNI and ES ID using awk'
	  vni_string=$(echo "$mac_line" | awk '/VNI/ {print $7}')

          # String to be separated
	  input_string="${vni_string}"
	  # Set IFS to "/"
	  IFS='/'
	  # Split the string into an array
	  read -ra elements <<< "$input_string"
	  # Access the elements
	  #vni+=("${elements[0]}")
	  vni+=("$(( DEFAULT_VNI + vlan_output[$i] ))")
	  time_line=$(echo "$mac_line" | grep -w "VNI ${vni[-1]}" )

    	  time_info=$(echo "$time_line" | awk '{
	    found_hours=0; found_minutes=0; found_seconds=0;
	    for (i=1; i<=NF; i++) { 
		if ($i == "hour(s)" || $i == "hours") {
		    print $(i-1), $i, $(i+1), $(i+2);
		    found_hours=1;
		}
		else if ($i == "min(s)" || $i == "mins") {
		    if (found_hours == 0) {
			print $(i-1), $i, $(i+1), $(i+2);
			found_minutes=1;
		    }
		}
		else if ($i == "sec(s)") {
		    if (found_hours == 0 && found_minutes == 0) {
			print $(i-1), $i;
			found_seconds=1;
		    }
		}
		if (found_hours == 1 && found_minutes == 1 && found_seconds == 1) {
		    break;
		}
	    }
	}')


	  time+=("${time_info}") 
	  es_or_bundle+=("${elements[1]}")

	  # Extract ping output line from the file for the current IP address
	  file_name="$SSH_CMD_OUTPUT_FILE"
	  ping_output_line=$(grep -E -A4 "\bPING ${ip} \(" "$file_name" | sed -n '/---/,/---/p')

          if [[ "$DEBUG" == "true" ]]; then
		  echo "ping_line : $ping_output_line"
	  fi
 	  #ping_output_line=$(echo "$output" | grep -E -A4 "\bPING ${ip} \(" | sed -n '/---/,/---/p')
	  loss_percentage+=("$(echo "${ping_output_line}" | awk '/loss/ {print $6}' | sed 's/%/ /g')")
 

	  if [[ ${es_or_bundle[$i]} == "ES" ]]; then
		  if [[ "$local_or_remote_value" == "local" ]]; then
			echo "Error : ES and local found for $ip"
			esid+=("")
		  else
		        ES_ID=$(echo "$ip_lines" | awk '/remote/ {print $5}')
			esid+=("${ES_ID}")
		  fi

		  es_line=$(echo "$output" | grep -w "${ES_ID}" )
		  remote_ip_addresses+=("$(echo "${es_line}" | awk '/R/ {print $4}')")
		  bundle_id+=("")
		  #remove leading white spaces from variable remote_ip_addresses
		  input_string="${remote_ip_addresses#"${remote_ip_addresses%%[![:space:]]*}"}"
		  IFS=','
		  # Split the string into an array
		  read -ra ips <<< "$input_string"
		  # Check if the ips array is not empty
		  if [[ ${#ips[@]} -gt 0 ]]; then
			  remote_leaf_1="${switch_names_by_ip["${ips[0]}"]}"
			  ip0=${ips[0]}

			    # Check if the array has more than one element
			    if [[ ${#ips[@]} -gt 1 ]]; then
				    remote_leaf_2="${switch_names_by_ip["${ips[1]}"]}"
				    ip1=${ips[1]}
			    else
				    remote_leaf_2=""
				    ip1=""
			    fi
         	  else
			  remote_leaf_1=""
			  remote_leaf_2=""
			  ip0=""
			  ip1=""
			 
		  fi

	  else
		  esid+=("")
		  bundle_id+=("${elements[1]}")
		  remote_ip_addresses+=("")
		  remote_leaf_1=""
		  remote_leaf_2=""
		  ip0=""
		  ip1=""
	  fi
    

        # Append values to the leaf array
        leaf+=("tracked_ip-$ip local_or_remote-$local_or_remote_value vni-${vni[$i]} mac_address-${mac_address[$i]} esid-${es_id[$i]} es_local_ips-$ip0,$ip1 leaf_names-$remote_leaf_1,$remote_leaf_2 bundle_id-${bundle_id[$i]} switch_ip-$SWITCH_IP ping_loss-${loss_percentage[$i]}")
	
      {	
        # Print values in tabular format
	printf "%-15s | %-12s | %-6s | %-24s | %-34s | %-30s | %-20s | %-10s | %-10s | %-20s\n" \
		    "$ip" "$local_or_remote_value" "${vni[-1]}" "${mac_address[-1]}" "${esid[-1]}" "$ip0,$ip1" "$remote_leaf_1,$remote_leaf_2" "${bundle_id[-1]}" "${loss_percentage[-1]}" "${time[-1]}"
      } >> "${TRACK_OUTPUT_FILE}"


	  if [[ $debug == "true" ]]; then
	       {
	          printf "%s \n" "IP LINE : ${ip_lines}"
		  printf "%s \n" "IP: $ip, local_or_remote_value: $local_or_remote_value, vni: ${vni[$i]}, esid: ${es_id[$i]}"
                  printf "%s \n" "es_or_bundle: ${es_or_bundle[$i]}"
		  printf "%s \n" "bundle_id : ${bundle_id[$i]}"
		  printf "%s \n" "MAC LINE : $mac_line"
                  printf "%s \n" "ping_output_line : ${ping_output_line}"
	          printf "%s \n" "time : ${time[$i]}"
		  printf "%s \n" "loss : ${loss_percentage[$i]}"

	  } >> "${DEBUG_OUTPUT_FILE}"
	  fi


  done ####################################################End of for loop#########################################################

  if [[ $debug == "true" ]]; then
      
      {
	  echo "---------------------------local_or_remote_array--------------------------"
	  echo "${local_or_remote[@]}"
	  echo "---------------------------mac_address_array------------------------------"
	  echo "${mac_address[@]}"
	  echo "---------------------------esid_array------------------------------------"
	  echo "${esid[@]}"
	  echo "---------------------------vni_array--------------------------------------"
	  echo "${vni[@]}"
	  echo "---------------------------loss_percentage_array--------------------------"
	  echo "${loss_percentage[@]}"
      } >> "${DEBUG_OUTPUT_FILE}"
  fi

####################################################################################################################################################

echo "------------ Output for leaf${leaf_idx} saved at ${TRACK_OUTPUT_FILE}----------------"


done ###### End of for ((leaf_idx=1; leaf_idx <= ${num_leafs}; leaf_idx++)); ########

# Loop through each leaf
for ((i = 1; i <= num_leafs; i+=2)); do

   if [[ ! ("$SWITCH_NAME" =~ "leaf$i" || "$SWITCH_NAME" == "all") ]];then
 	 continue
   fi

    track_file1="$ZONE/leaf${i}_track_output.txt"
    track_file2="$ZONE/leaf$((i+1))_track_output.txt"

    if [[ -f "${track_file1}" && -f "${track_file2}" ]]; then
	echo "Comparing track_output_data for leaf$i and leaf$((i+1))"
        # Perform comparison using your preferred method, for example:
	python3 compare_files.py "$track_file1" "$track_file2"
    else
        echo "Track output file not found for leaf."
    fi
done


