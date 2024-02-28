import sys

# ANSI escape code for red color
RED = "\033[91m"
# ANSI escape code for green color
GREEN="\033[32m"
# ANSI escape code for reset color
RESET = "\033[0m"

# Define a function to compare two lines
def compare_evpn_es_lines(line1, line2):
    match=True
    # Split each line into fields based on whitespace
    fields1 = line1.strip().split()
    fields2 = line2.strip().split()
 
    if fields1[0] != fields2[0]:
        print(f"{fields1[0]} doesn't match {fields2[0]}")
        match=False

    if fields1[2] != fields2[2]:
        print(f"{fields1[2]} doesn't match {fields2[2]}")
        match=False

    if fields1[1] == "LRN" and fields2[1] != "LR":
        print(f"{fields1[1]} doesn't match {fields2[1]} for es {fields1[0]}")
        match=False 
    elif fields1[1] == "LR" and fields2[1] != "LRN":
        print(f"{fields1[1]} doesn't match {fields2[1]} for es {fields1[0]}")
        match=False
    elif fields1[1] == "R" and fields2[1] != "R":
        print(f"{fields1[1]} doesn't match {fields2[1]} for es {fields1[0]}")
        match=False
    elif fields1[1] == "LN" and fields2[1] != "LN":
        print(f"{fields1[1]} doesn't match {fields2[1]} for es {fields1[0]}")
        match=False
    elif fields1[1] == "L" and fields2[1] != "L":
        print(f"{fields1[1]} doesn't match {fields2[1]} for es {fields1[0]}")
        match=False
 
    return match

# Define the function to compare tables
def compare_tables(table1_file, table2_file):
    match=True
    # Open and read the contents of the tables
    with open(table1_file, 'r') as file1, open(table2_file, 'r') as file2:
        # Skip header lines
        for _ in range(3):
            next(file1)
            next(file2)

        # Compare tables line by line
        for line1, line2 in zip(file1, file2):
            # Check if either line is empty or if we have reached the end of file
            fields1 = line1.strip().split()
            fields2 = line2.strip().split()

            if not fields1 or not fields2:
              break

            # Remove leading/trailing whitespace and compare
            if compare_evpn_es_lines(line1,line2) is False:
                match=False
    
    if match:
       print(f"{GREEN}---------------------------------------")
       print("Tables match :) ")
       print(f"---------------------------------------{RESET}")
 
    else:
       print(f"{RED}---------------------------------------")
       print("Tables do not match :( ")
       print(f"-----------------------------------------{RESET}")
   
 
    return match

# Paths to the tables
table1_file = sys.argv[1]
table2_file = sys.argv[2]

# Call the function to compare tables
compare_tables(table1_file, table2_file)

