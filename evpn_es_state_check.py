import sys
import os
import argparse
import paramiko
import re
import colorama
from colorama import Fore, Style

colorama.init()

def extract_hostname(version_output):
    # Split the output into lines
    lines = version_output.split('\n')

    # Search for the line containing "Host" and extract the hostname
    for line in lines:
       if "Host" in line:
        # Extract the text after "Host"
        hostname = line.split(":", 1)[1].strip()
        return hostname

    # Return "N/A" if no hostname is found
    return "N/A"

def get_router_info(router_ip, username, password):
  try:
    # Establish SSH connection
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(router_ip, username=username, password=password)

    # Execute show version command to get the hostname
    stdin, stdout, stderr = ssh.exec_command("show version")
    version_output = stdout.read().decode("utf-8")

    # Execute show l2vpn evpn es command
    stdin, stdout, stderr = ssh.exec_command("show l2vpn evpn es")
    es_output = stdout.read().decode("utf-8")
    es_output_lines = es_output.split('\n')[3:]

    """
    index = es_output.find("--------------------------------------------------------------------------------------")
    """
    # Remove the prefix
    es_output = '\n'.join(es_output_lines)

    # Close the SSH connection
    ssh.close()

    return version_output, es_output

  except paramiko.AuthenticationException:
    print("Authentication failed for router {router_ip}. Check username and password.")
  except paramiko.SSHException as e:
    print("Unable to establish SSH connection to router {router_ip}. Error: {str(e)}")
  except Exception as e:
    print("An error occurred for router {router_ip}. Error: {str(e)}")

  return None, None

def parse_router_info(router_ip, version_output, es_output):
    hostname = extract_hostname(version_output)

    # Regular expression to extract L2VPN EVPN ES information
    pattern = re.compile(r'(\S+)\s+(\S+)\s+(\S+)\s+(\S+)')

    # Split the output into lines
    lines = es_output.split('\n')
    # Find the start index by looking for the line starting with "ESI Type ES-IF VTEPs"
    start_index = next((i for i, line in enumerate(lines) if line.startswith("ESI")), len(lines))

    # Find the end index of the relevant lines
    try:
        end_index = next(i for i, line in enumerate(lines[start_index:]) if not line.strip())
    except StopIteration:
        # If no relevant lines are found, set end_index to the end of the lines
        end_index = len(lines)

    # Extract the relevant lines
    relevant_lines = lines[start_index:start_index + end_index]
    # Reverse the order of lines
    # relevant_lines.reverse()

    # Filter out lines that contain "ESI Type ES-IF VTEPs"
    relevant_lines = [line for line in relevant_lines if "ESI" not in line and "Type" not in line and "ES-IF" not in line and "VTEPs" not in line]


   # Find all matches in the relevant lines
    matches = pattern.findall('\n'.join(relevant_lines))

    # Create a list of dictionaries for each L2VPN EVPN ES
    l2vpn_evpn_es_info = []
    #i=0
    #for match in matches:
    for line in relevant_lines:
        match=line.split()
        esi = match[0] if len(match) > 0 else "N/A"
        es_type = match[1] if len(match) > 1 else "N/A"
        es_if = match[2] if len(match) > 2 else "N/A"
        vteps = match[3] if len(match) > 3 else "N/A"
    
        if esi != "N/A" or es_type != "N/A" or es_if != "N/A" or vteps != "N/A":
           l2vpn_evpn_es_info.append({
            'Router_IP': router_ip,
            'Hostname': hostname,
            'ESI': esi,
             'Type': es_type,
             'ES_IF': es_if,
             'VTEPs': vteps
             })
           #print("\n", l2vpn_evpn_es_info[i])
           #i=i+1
    return l2vpn_evpn_es_info

def create_l2vpn_evpn_es_table(l2vpn_evpn_es_info):
    table = "Hostname\tRouter_IP\tESI\tType\tES-IF\tVTEPs\n"

    for es_info in l2vpn_evpn_es_info:
       # Check if VTEP field is empty
       vtep = es_info['VTEPs'] if es_info['VTEPs'] != "N/A" else ""
       table += "{}\t{}\t{}\t{}\t{}\t{}\n".format(es_info['Hostname'],
                           es_info['Router_IP'],
                           es_info['ESI'],
                           es_info['Type'],
                           es_info['ES_IF'],
                           vtep)

    return table

def main():

    # Parse command line arguments
    parser = argparse.ArgumentParser(description='EVPN ES Info Verification Script')
    parser.add_argument('-v', '--verbose', action='store_true', help='Enable verbose output')
    parser.add_argument('--ip', type=str, help='IP address of the device')
    parser.add_argument('--username', type=str, help='Username for authentication')
    parser.add_argument('--password', type=str, help='Password for authentication')
    parser.add_argument('--output_file', type=str, help='Output file path')
    parser.add_argument('-d', '--debug', type=str, help='Debug Flag , true/false')

    args = parser.parse_args()

    # Access parsed arguments
    ip = args.ip
    username = args.username
    password = args.password
    output_file = args.output_file
    debug = args.debug


    if args.debug.lower() == "true":
       print("Debug : ", debug) 
       print("IP address:", ip)
       print("Username:", username)
       print("Password:", password)
       print("Output file:", output_file)

    # List of routers with their IP, username, and password
    routers = [
    {'ip': '192.168.111.181', 'username': 'operator', 'password': 'Operator@123'},
    {'ip': '192.168.111.186', 'username': 'operator', 'password': 'Operator@123'},
    {'ip': '192.168.111.183', 'username': 'operator', 'password': 'Operator@123'},
    {'ip': '192.168.111.187', 'username': 'operator', 'password': 'Operator@123'},
    # Add more routers as needed
    ]
 
    all_results = []
     
    if output_file == "/dev/stdout":
       # Use sys.stdout as the output stream
       output_stream = sys.stdout
    else:
       if os.path.exists(output_file):
          os.remove(output_file)
          # Create the output file
          output_stream = open(output_file, 'w')

    try:
       with open(output_file, 'a') as output_stream:
            # Write the header only once if the file is empty
            # Define the values to format
            version_output, es_output = get_router_info(ip, username, password)
             
            if version_output and es_output:
               l2vpn_evpn_es_info = parse_router_info(ip, version_output, es_output)
               all_results.extend(l2vpn_evpn_es_info)

            output_stream.write(es_output)
            output_stream.write('\n')

            if output_stream is not sys.stdout:
                 output_stream.close()


    except Exception as e:
        print("Error:", e)
    

    # Compare ESI IDs and create a table for matching ones
    matching_table, non_matching_table = create_matching_table(all_results,verbose=args.verbose)
    '''
    try:
       with open(output_file, 'a') as output_stream:
         output_stream.write("Matching Entries:\n")
         output_stream.write(matching_table)
         output_stream.write("Non-Matching Entries:\n")
         output_stream.write(non_matching_table)
         if output_stream is not sys.stdout:
            output_stream.close()
    except:
        print("Error:", e)
    '''


    # Close the output stream if it's a file
    #if output_stream is not sys.stdout:
    #   output_stream.close()


def create_matching_table(all_results, verbose=False):
    esi_table = {}

    for es_info in all_results:
       esi = es_info['ESI']
       host_id = es_info['Hostname']
       es_type = es_info['Type']

       if esi not in esi_table:
          esi_table[esi] = []

       esi_table[esi].append((host_id, es_type))

    matching_table = "ESI {:<30} Matching_Host_IDs\tMatching_Types\tStatus\tFailure_Reason\n".format("")
    non_matching_table = "ESI {:<30} Host_ID\tType\n".format("")

    for esi, matches in esi_table.items():
      if len(matches) > 1:
          host_ids, types = zip(*matches)
          lrn_present = any("LRN" in t for t in types)
          lr_present = any("LR" in t for t in types)
          passed = lrn_present and lr_present and all("R" in t for t in types if "LRN" not in t)    
          #lrn_count = sum(1 for t in types if "LRN" in t)
          #passed = lrn_count == 1 and all("R" in t for t in types if "LRN" not in t)
          failure_reason = None

          if passed:
             lrn_host_id = [host_id for host_id, es_type in zip(host_ids, types) if "LRN" in es_type][0]
             lr_host_id = [host_id for host_id, es_type in zip(host_ids, types) if "LR" in es_type][0]
             lrn_last_digit = int(lrn_host_id[-1])
             lr_last_digit = int(lr_host_id[-1])

             if not (lrn_last_digit % 2 == 0 and lr_last_digit == lrn_last_digit - 1) and \
                 not (lrn_last_digit % 2 != 0 and lr_last_digit == lrn_last_digit + 1):
                 failure_reason = "Inconsistent State LRN and LR not in pair Leafs"
          else:
             # Check for error in LRN leaf when only "LRN" is present
             if lrn_present and not lr_present:
                failure_reason = "Inconsistent State"
             # Check for inconsistent state of leaf when the type is "L"
             elif any("L" in t for t in types):
                failure_reason = "Inconsistent State"
             else:
                failure_reason = "Inconsistent State on LEAF"


          print("Failure Reason: {failure_reason}")

          matching_table += "{}\t{}\t{}\t{}\t{}\n".format(
            esi,
            ','.join(host_ids),
            ','.join(types),
            Fore.GREEN + "Passed" + Fore.RESET if passed else Fore.RED + "Failed" + Fore.RESET,
            failure_reason
            )

      else:
         host_id, es_type = matches[0]
         non_matching_table += "{}\t{}\t{}\n".format(esi, host_id, es_type)

    return matching_table, non_matching_table


if __name__ == "__main__":
    main()

