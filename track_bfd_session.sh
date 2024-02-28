#!/bin/bash
# Replace with your actual credentials and IP address
SSH_PASSWORD="Operator@123"
SSH_USERNAME="operator"
if [[ -z $1 ]];then
  echo "Usage :  ./track_bfd_session.sh [tracking_ip] > /dev/null 2>&1"
  echo "Example: ./track_bfd_session.sh <ip address of switch > /dev/null 2>&1"
  echo "Output will be written in track.txt"
  exit 1
fi
TRACK_IP="$1"
num_leafs=1
# Loop through each leaf
for ((i=1; i<=$num_leafs; i++)); do
  SWITCH_IP=$TRACK_IP
  echo "SWITCH_IP: $SWITCH_IP"

#SHOW BFD SESSION
	output=$(sshpass -p "$SSH_PASSWORD" ssh "$SSH_USERNAME@${SWITCH_IP}" "show bfd session")

# Extract information and create a table
	table_output=$(echo "$output" | awk '/LocalDiscr:/{local_discr=$2} /BFD session:/{bfd_session=$3} /BFD session:/{bfd_session_ip=$4} /CurrentState:/{current_state=$2} /^===/{print local_discr "|" bfd_session "|" bfd_session_ip "|" current_state}')

# Store the table in a file on the router
	table_filename="bfd_table_on_router.txt"
	echo "$table_output" > "$table_filename"
	echo "Table saved to $table_filename"

# Check for sessions with CurrentState: down
	down_sessions=$(echo "$table_output" | awk -F"|" '/down/{print $2, $3}')

# Check for sessions with CurrentState: up
	up_sessions=$(echo "$table_output" | awk -F"|" '/up/{print $2, $3}')
# Print sessions with CurrentState: down
	if [ -n "$down_sessions" ]; then
			down_filename="${TRACK_IP}_bfd_down_sessions.txt"
			echo "CurrentState is down for the following bfd sessions at ${TRACK_IP}" > "$down_filename"
			echo "$down_sessions" >> "$down_filename"
			echo "Down sessions saved to $down_filename"
	else
			echo "No BFD sessions with CurrentState: down found."
	fi
# Print sessions with CurrentState: up
	if [ -n "$up_sessions" ]; then
			up_filename="${TRACK_IP}_bfd_up_sessions.txt"
			echo "CurrentState is up for the following bfd sessions at ${TRACK_IP}" > "$up_filename"
			echo "$up_sessions" >> "$up_filename"
			echo "Up sessions saved to $up_filename"
	else
			echo "No BFD sessions with CurrentState: up found."
	fi
#remove file 
rm -f "$table_filename"
done
