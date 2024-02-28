#!/bin/bash

OPTIONS=$(getopt -o i:u:p:o:d:v: --long ip:,username:,password:,output_file:,debug:,verbose: -n '$0' -- "$@")

eval set -- "$OPTIONS"

while true; do
  case "$1" in
    -i|--ip)
      switch_ip="$2"
      shift 2
      ;;

    -u|--username)
      USER="$2"
      shift 2
      ;;
   -p|--password)
      PASSWORD="$2"
      shift 2
      ;;

    -o|--output_file)
      OUTPUT_FILE="$2"
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

python3 evpn_es_state_check.py --ip "${switch_ip}" --username "${USER}" --password "${PASSWORD}" --output_file "${OUTPUT_FILE}" -d $DEBUG
result=$?
if [ $result -ne 0 ]; then
	echo "Error: Python script returned non-zero exit code $result"
fi
