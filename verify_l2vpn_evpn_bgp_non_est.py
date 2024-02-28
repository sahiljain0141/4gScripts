import paramiko
import re

def get_user_input():
    num_routers = int(input("Enter the number of routers/Switch:"))
    #common_user= input("Enter the common username: ")
    #common_password = input("Enter the common password: ")

    routers = []
    for i in range(1, num_routers + 1):
        router_ip = input("Enter the IP address for router {}:".format(i))
        routers.append({'ip': router_ip, 'username': 'operator', 'password': 'Operator@123'})

    return routers

def read_entries_from_file(file_name):
    entries = []
    with open(file_name, 'r') as file:
        # Skip header line
        next(file)
        for line in file:
            columns = line.strip().split('\t')
            entry = {
                'Router_IP': columns[0],
                'Remote_AS': columns[1],
                'Remote_IP': columns[2],
                'Remote_port': columns[3],
                'Local_port': columns[4],
                'State': columns[5],
                'Uptime': columns[6]
            }
            entries.append(entry)
    return entries

def write_non_established_to_file(file_name, non_established_entries):
    with open(file_name, 'w') as file:
        file.write("Router_IP\tRemote_AS\tRemote_IP\tRemote_port\tLocal_port\tState\tUptime\n")
        for entry in non_established_entries:
            file.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(entry['Router_IP'],
                                                               entry['Remote_AS'],
                                                               entry['Remote_IP'],
                                                               entry['Remote_port'],
                                                               entry['Local_port'],
                                                               entry['State'],
                                                               entry['Uptime']))


def get_bgp_l2vpn_evpn_neighbors(router_ip, username, password):
    # Establish SSH connection
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(router_ip, username=username, password=password)

    # Execute show ip bgp l2vpn evpn neighbors command
    stdin, stdout, stderr = ssh.exec_command("show ip bgp l2vpn evpn neighbors")

    # Read the output
    bgp_output = stdout.read().decode("utf-8")

    # Close the SSH connection
    ssh.close()

    return bgp_output

def parse_bgp_l2vpn_evpn_output(router_ip, bgp_output):
    # Extract Router ID from the output
    router_id_pattern = re.compile(r'Router\s+ID\s+(\d+\.\d+\.\d+\.\d+)')
    router_id_match = router_id_pattern.search(bgp_output)
    router_id = router_id_match.group(1) if router_id_match else "N/A"

    # Regular expression to extract BGP L2VPN EVPN neighbor information
    pattern = re.compile(r'(\d+)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+)\s+(\d+)\s+(\w+)\s+(\S+)')

    # Find all matches in the output
    matches = pattern.findall(bgp_output)

    # Create a list of dictionaries for each BGP L2VPN EVPN neighbor
    bgp_l2vpn_evpn_neighbors = [{'Router_IP': router_ip,
                                  'Remote_AS': match[0],
                                  'Remote_IP': match[1],
                                  'Remote_port': match[2],
                                  'Local_port': match[3],
                                  'State': match[4],
                                  'Uptime': match[5]} for match in matches]

    return bgp_l2vpn_evpn_neighbors

def create_table(bgp_l2vpn_evpn_neighbors):
    # Create a table with headers
    table = "Router_IP\tRemote_AS\tRemote_IP\tRemote_port\tLocal_port\tState\tUptime\n"

    # Populate the table with data
    for neighbor in bgp_l2vpn_evpn_neighbors:
        table += "{}\t{}\t\t\t{}\t{}\t{}\t{}\t{}\n".format(neighbor['Router_IP'],
                                                        neighbor['Remote_AS'],
                                                        neighbor['Remote_IP'],
                                                        neighbor['Remote_port'],
                                                        neighbor['Local_port'],
                                                        neighbor['State'],
                                                        neighbor['Uptime'])

    return table

def main():
    # Option 1: Dynamically get input from the user
    routers = get_user_input()

    # Option 2: Alternatively, read routers from a file
    # input_file = "routers_input.txt"
    # routers = read_routers_from_file(input_file)
    # List of routers with their IP, username, and password
    
    #option 3
   # routers = [
    #    {'ip': '192.168.111.187', 'username': 'operator', 'password': 'Operator@123'},
    #    {'ip': '192.168.111.183', 'username': 'operator', 'password': 'Operator@123'},
        #{'ip': '192.168.111.184', 'username': 'operator', 'password': 'Operator@123'},
        # Add more routers as needed
    #]

    # Output file
    output_file = "bgp_l2vpn_evpn.txt"

    # Output file for non-established sessions
    non_established_file = "bgp_non_established_sessions.txt"

    # Accumulate results for all routers
    all_results = []

    for router in routers:
        bgp_output = get_bgp_l2vpn_evpn_neighbors(router['ip'], router['username'], router['password'])
        bgp_l2vpn_evpn_neighbors = parse_bgp_l2vpn_evpn_output(router['ip'], bgp_output)
        all_results.extend(bgp_l2vpn_evpn_neighbors)

    # Write the combined results to the file
    with open(output_file, 'w') as file:
        file.write("Router_IP\tRemote_AS\tRemote_IP\tRemote_port\tLocal_port\tState\tUptime\n")
        for neighbor in all_results:
            file.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(neighbor['Router_IP'],
                                                               neighbor['Remote_AS'],
                                                               neighbor['Remote_IP'],
                                                               neighbor['Remote_port'],
                                                               neighbor['Local_port'],
                                                               neighbor['State'],
                                                               neighbor['Uptime']))
            #file.write("-" * 80 + "\n")
    
    # Output file for non-established sessions
    non_established_file = "non_established_sessions_from_file.txt"

    # Read entries from the input file
    entries = read_entries_from_file(output_file)

    # Filter out non-established sessions
    non_established_entries = [entry for entry in entries if entry['State'] != 'Established']

    # Write non-established sessions to a separate file
    write_non_established_to_file(non_established_file, non_established_entries)


if __name__ == "__main__":
    main()

