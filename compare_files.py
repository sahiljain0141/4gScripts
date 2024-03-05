import sys
import os
# ANSI escape code for red color
RED = "\033[91m"
# ANSI escape code for reset color
RESET = "\033[0m"

# Define a function to parse the file
def parse_file(file_name):
    # Create empty dictionaries to store data for each leaf
    leaf_data={}
    # Open the file and read line by line
    with open(file_name, 'r') as file:
        # Skip header lines
        for _ in range(3):
            next(file)
        
        # Read remaining lines
        for line in file:
            # Skip lines starting with "~"
            if line.startswith("~"):
                continue
            
            # Split the line by whitespace
            fields = line.split('|')
            
            # Extract relevant fields
            ip = fields[0]
            leaf_names = fields[7]
            vni = fields[2]
            mac = fields[3]
            es_id = fields[4]
            es_local_ips = fields[5]
            ping_loss = fields[8]
            time_info = fields[9] 
            #' '.join(fields[-2:])

            leaf_data[ip] = {
			"VNI": vni,
			"MAC": mac,
			"ES_ID": es_id,
			"ES_Local_IPs": es_local_ips,
			"Ping_Loss": ping_loss,
			"Time_Info": time_info
		    }

    
    return leaf_data

# Define a function to compare data for each leaf pair
def compare_data(leaf1_data, leaf1_name, leaf2_data, leaf2_name):
    ### Compare IP Fields of leaf1 with leaf2 ###
    for ip, data1 in leaf1_data.items():
        if ip in leaf2_data :
             data2= leaf2_data[ip]
             for key in data1:
                    key1=data1[key]
                    key2=data2[key]
                    #print(f"keys : {key1}, {key2}")
                    if data1[key] != data2[key]:
                        key1 = data1[key].replace(" ", "").replace("\n", "")
                        key2 = data2[key].replace(" ", "").replace("\n", "")
                        print(f"----------Comparing Data For IP : {ip}-------------")
                        print(f'{RED} Mismatch in {key}: {key1} ({leaf1_name}) vs {key2} ({leaf2_name}) {RESET}')

        else:
            ip = ip.replace(" ", "").replace("\n", "")
            print(f"----------Comparing Data For IP : {ip}-------------")
            print(f"{RED} IP {ip} not learned in {leaf2_name}  {RESET}")


    ### Compare IP Fields of leaf2 with leaf1 ###
    for ip, data2 in leaf2_data.items():
        if ip in leaf1_data :
            pass
        else:
            ip = ip.replace(" ", "").replace("\n", "")
            print(f"----------Comparing Data For IP : {ip}-------------")
            print(f"{RED} IP {ip} not learned in {leaf1_name} {RESET}")



def read_field_names(file):
    # Read the second line of the file and split it by '|'
    with open(file, 'r') as f:
        field_line = f.readlines()[1]
    return [field.strip() for field in field_line.split('|')]


def compare_files(file1, file2):
    # Read field names from both files
    field_names1 = read_field_names(file1)
    field_names2 = read_field_names(file2)

    # Read table data from both files
    with open(file1, 'r') as f1, open(file2, 'r') as f2:
        next(f1)  # Skip the first two lines (header and field names)
        next(f2)
        for line1, line2 in zip(f1, f2):
            fields1 = [field.strip() for field in line1.split('|')]
            fields2 = [field.strip() for field in line2.split('|')]

            # Compare corresponding fields
            for i, (field1, field2) in enumerate(zip(fields1, fields2)):
                if field1 != field2:
                    print(f"----------------------------------------------------------------")
                    print(f"{RED}Error: Mismatch in '{field_names1[i]}' {RESET}")
                    print(f"{file1} : {field1}")
                    print(f"{file2} : {field2}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 compare_files.py file1 file2")
        sys.exit(1)

    file1 = sys.argv[1]
    leaf1_name = os.path.basename(file1).split('_')[0]
    leaf1_data = parse_file(file1)
 
    file2 = sys.argv[2]
    leaf2_name = os.path.basename(file2).split('_')[0]
    leaf2_data = parse_file(file2)
    
    compare_data(leaf1_data, leaf1_name, leaf2_data, leaf2_name)

    #compare_files(file1, file2)
