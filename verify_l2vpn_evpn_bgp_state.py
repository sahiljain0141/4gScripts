import paramiko
import re

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
    # List of routers with their IP, username, and password
    routers = [
        {'ip': '192.168.111.187', 'username': 'operator', 'password': 'Operator@123'},
        {'ip': '192.168.111.183', 'username': 'operator', 'password': 'Operator@123'},
        #{'ip': '192.168.111.184', 'username': 'operator', 'password': 'Operator@123'},
        # Add more routers as needed
    ]

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
        file.write("Router_IP\t\t\t\tRemote_AS\tRemote_IP\tRemote_port\tLocal_port\tState\tUptime\n")
        for neighbor in all_results:
            file.write("{}\t{}\t\t{}\t{}\t\t\t\t{}\t{}\t{}\n".format(neighbor['Router_IP'],
                                                               neighbor['Remote_AS'],
                                                               neighbor['Remote_IP'],
                                                               neighbor['Remote_port'],
                                                               neighbor['Local_port'],
                                                               neighbor['State'],
                                                               neighbor['Uptime']))
            #file.write("-" * 80 + "\n")
    
    # Write non-established sessions to a separate file
    with open(non_established_file, 'w') as non_established_file:
        non_established_file.write("Router_IP\tRemote_AS\tRemote_IP\tRemote_port\tLocal_port\tState\tUptime\n")
        for neighbor in all_results:
            non_established_file.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(neighbor['Router_IP'],
                                                                              neighbor['Remote_AS'],
                                                                              neighbor['Remote_IP'],
                                                                              neighbor['Remote_port'],
                                                                              neighbor['Local_port'],
                                                                              neighbor['State'],
                                                                              neighbor['Uptime']))
            #non_established_file.write("-" * 80 + "\n")

if __name__ == "__main__":
    main()

