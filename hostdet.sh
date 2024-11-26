#!/bin/bash

# ASCII Art Header
cat << "EOF"
  _    _           _     _____       _            _   _           
 | |  | |         | |   |  __ \     | |          | | (_)          
 | |__| | ___  ___| |_  | |  | | ___| |_ ___  ___| |_ ___   _____ 
 |  __  |/ _ \/ __| __| | |  | |/ _ \ __/ _ \/ __| __| \ \ / / _ \
 | |  | | (_) \__ \ |_  | |__| |  __/ ||  __/ (__| |_| |\ V /  __/
 |_|  |_|\___/|___/\__| |_____/ \___|\__\___|\___|\__|_| \_/ \___|
                                                                  
                                                                  
EOF

# Array to track missing or failed commands
missing_commands=()

# Function to run a command and store failures
run_command() {
    local description="$1"
    local command="$2"

    # Execute the command using bash -c to handle pipes and redirections
    # Suppress stderr by redirecting it to /dev/null
    output=$(bash -c "$command" 2>/dev/null)

    # Check if the command succeeded and produced non-empty output
    if [ $? -ne 0 ] || [ -z "$output" ]; then
        missing_commands+=("$description")
    else
        echo "== $description =="
        echo "$output"
        echo
    fi
}

echo "Hostname: $(hostname)"
echo

run_command "Model from /proc/device-tree/model" "cat /proc/device-tree/model 2>/dev/null"
run_command "CPU info from /proc/cpuinfo" "cat /proc/cpuinfo | grep -E 'Model|Hardware|Revision' 2>/dev/null"
run_command "Model from /sys/firmware/devicetree/base/model" "cat /sys/firmware/devicetree/base/model 2>/dev/null"
run_command "System summary using hostnamectl" "hostnamectl 2>/dev/null"
run_command "Operating system information using lsb_release" "lsb_release -a 2>/dev/null"
run_command "Version details using vcgencmd" "vcgencmd version 2>/dev/null"

# Function to print IP addresses in a nicely formatted way
print_ip_addresses() {
    # Retrieve IP addresses using hostname -I and store them in a variable
    ip_addresses=$(hostname -I)
    
    # Check if any IP addresses were found
    if [ -z "$ip_addresses" ]; then
        echo "No IP addresses found."
        return
    fi
    
    # Initialize arrays to hold IPv4 and IPv6 addresses
    ipv4=()
    ipv6=()
    
    # Iterate over each IP address
    for ip in $ip_addresses; do
        if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # If the IP matches IPv4 pattern, add to ipv4 array
            ipv4+=("$ip")
        elif [[ $ip =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
            # If the IP matches IPv6 pattern, add to ipv6 array
            ipv6+=("$ip")
        else
            # If the IP doesn't match IPv4 or IPv6, categorize as Unknown
            unknown+=("$ip")
        fi
    done
    
    # Function to print a list with a header
    print_list() {
        local header="$1"
        shift
        local list=("$@")
        
        if [ ${#list[@]} -ne 0 ]; then
            echo "$header:"
            for item in "${list[@]}"; do
                echo "  - $item"
            done
            echo
        fi
    }
    
    # Print IPv4 Addresses
    print_list "IPv4 Addresses" "${ipv4[@]}"
    
    # Print IPv6 Addresses
    print_list "IPv6 Addresses" "${ipv6[@]}"
    
    # Print Unknown Addresses, if any
    if [ ${#unknown[@]} -ne 0 ]; then
        echo "Unknown IP Addresses:"
        for ip in "${unknown[@]}"; do
            echo "  - $ip"
        done
        echo
    fi
}

echo "== IP Addresses =="
print_ip_addresses

# Print missing or failed commands at the end
if [ ${#missing_commands[@]} -ne 0 ]; then
    echo "The following commands were not found or failed:"
    for cmd in "${missing_commands[@]}"; do
        echo "- $cmd"
    done
fi

echo
