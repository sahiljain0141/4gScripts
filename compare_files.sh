#!/bin/bash

# Function to extract fields from a line
extract_fields() {
    local line="$1"
    echo "$line" | awk '{print $1,$3,$5,$7,$9,$11,$13,$15,$17}'
}

# Compare two lines
compare_lines() {
    local line1="$1"
    local line2="$2"
    local fields1=$(extract_fields "$line1")
    local fields2=$(extract_fields "$line2")
    if [ "$fields1" != "$fields2" ]; then
        echo "Mismatch:"
        echo "File 1: $line1"
        echo "File 2: $line2"
    fi
}

# Main function
main() {
    file1="$1"
    file2="$2"

    while IFS= read -r line1 && IFS= read -r line2 <&3; do
        compare_lines "$line1" "$line2"
    done < "$file1" 3< "$file2"
}

# Check if correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 file1 file2"
    exit 1
fi

main "$1" "$2"

