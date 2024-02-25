#!/bin/bash

# ANSI escape codes for colors
RED='\033[0;31m'  # Red color
RESET='\033[0m'   # Reset color to default

read_field_names() {
    # Read the second line of the file and split it by '|'
    field_line=$(sed '2q;d' "$1")
    IFS='|' read -r -a fields <<< "$field_line"
    echo "${fields[@]}"
}

compare_files() {
    # Read field names from both files
    read -r -a field_names1 <<< "$(read_field_names "$1")"
    read -r -a field_names2 <<< "$(read_field_names "$2")"

    # Read table data from both files
    while IFS= read -r line1 && IFS= read -r line2 <&3; do
        IFS='|' read -r -a fields1 <<< "$line1"
        IFS='|' read -r -a fields2 <<< "$line2"

        # Compare corresponding fields
        for ((i = 0; i < ${#fields1[@]}; i++)); do
            if [[ ${fields1[i]} != ${fields2[i]} ]]; then
                printf "%bError: Mismatch in '${field_names1[i]}': ${fields1[i]} (file1) != ${fields2[i]} (file2)%b\n" "$RED" "$RESET"
            fi
        done
    done < "$1" 3< "$2"
}

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 file1 file2"
    exit 1
fi

file1="$1"
file2="$2"
compare_files "$file1" "$file2"

