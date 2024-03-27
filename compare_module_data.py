import sys
import os

# ANSI escape code for red color
RED = "\033[91m"
# ANSI escape code for green color
GREEN="\033[32m"
# ANSI escape code for reset color
RESET = "\033[0m"

# Define a function to parse the file
def parse_evpn_es_file(file_name):
    # Create empty dictionaries to store data for each leaf
    leaf_data={}
    # Open the file and read line by line
    with open(file_name, 'r') as file:
        # Skip header lines
        for _ in range(1):
            next(file)

        #Read remaining lines
        for line in file:
            # Skip lines starting with "~"
            if line.startswith("~"):
                continue
            if not line.strip():
                continue

            # Split the line by whitespace
            fields = line.split()
            #print(f"field elements : {len(fields)}")

            # Extract relevant fields
            try :
                esi = fields[0]
                esi_type = fields[1] if len(fields) >= 2 else "-"
                es_if = fields[2] if len(fields) >= 3 else None
                vteps = fields[3] if len(fields) == 4 else None
            except Exception as e :
                print("An error occurred {} in line : {} ".format(e,line))

            leaf_data[esi] = {
                        "ESI_TYPE": esi_type,
                        "ES_IF": es_if,
                        "VTEPS": vteps
                    }

    size = len(leaf_data)
    print(f"Leaf Name : {file_name}, Size of leaf_data:  {size} ")
    return leaf_data


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


# Define a function to compare data for each leaf pair
def compare_evpn_es_data(leaf1_data, leaf1_name, leaf2_data, leaf2_name):
    result=True
    ### Compare Fields of leaf1 with leaf2 ###
    for esi, data1 in leaf1_data.items():
        match=True
        if esi in leaf2_data :
             data2= leaf2_data[esi]

             # Compare the fields for the current esi
             if data1["ESI_TYPE"] == "LRN" and data2["ESI_TYPE"] != "LR":
                match = False
             elif data1["ESI_TYPE"] == "LR" and data2["ESI_TYPE"] != "LRN":
                match = False
             elif data1["ESI_TYPE"] == "R" and data2["ESI_TYPE"] != "R":
                match = False
             elif data1["ESI_TYPE"] == "LN" and data2["ESI_TYPE"] != "LN":
                match = False
             elif data1["ESI_TYPE"] == "L" and data2["ESI_TYPE"] != "L":
                match = False

             if not match: 
                 print(f"----------Comparing Data For ESI : {esi}-------------")
                 print(f"{RED} Mismatch in ESI_TYPE: {data1['ESI_TYPE']} ({leaf1_name}) vs {data2['ESI_TYPE']} ({leaf2_name}) {RESET}")
                 result=False
             
             if data1['ES_IF'] != data2['ES_IF']:
                 print(f"----------Comparing Data For ESI : {esi}-------------")
                 print(f"{RED} Mismatch in ES_IF: {data1['ES_IF']} ({leaf1_name}) vs {data2['ES_IF']} ({leaf2_name}) {RESET}")
                 result=False
 

        else: ###if esi in leaf2_data :###
            print(f"----------Comparing Data For ESI : {esi}-------------")
            print(f"{RED} ESI {esi} not found in {leaf2_name}  {RESET}")
            result=False


    ### Compare ESI Fields of leaf2 with leaf1 ###
    for esi, data2 in leaf2_data.items():
        if esi in leaf1_data :
            pass
        else:
            print(f"----------Comparing Data For ESI : {esi}-------------")
            print(f"{RED} ESI {esi} not found in {leaf1_name} {RESET}")
            result=False


    return result

# Define the function to compare tables
def compare_tables(table1_file, table2_file):

    leaf1_data = parse_evpn_es_file(table1_file)
    leaf2_data = parse_evpn_es_file(table2_file)

    # Extract the file1 name
    file_name = os.path.basename(table1_file)
    # Remove the file extension (if present)
    leaf1_name, _ = os.path.splitext(file_name)

    # Extract the file2 name
    file_name = os.path.basename(table2_file)
    # Remove the file extension (if present)
    leaf2_name, _ = os.path.splitext(file_name)

    match=compare_evpn_es_data(leaf1_data, leaf1_name, leaf2_data, leaf2_name)
    
    if match:
       print(f"{GREEN}---------------------------------------")
       print("Tables match :) ")
       print(f"---------------------------------------{RESET}")
 
    else:
       print(f"{RED}---------------------------------------")
       print("Tables do not match :( ")
       print(f"-----------------------------------------{RESET}")
   

    return 


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

