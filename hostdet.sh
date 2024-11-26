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

print_ip_addresses() {
    ip_addresses=$(hostname -I)
    
    if [ -z "$ip_addresses" ]; then
        echo "No IP addresses found."
        return
    fi
    
    ipv4=()
    ipv6=()
    
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

get_home_directories() {
    local home_dirs=()
    
    # Iterate through /etc/passwd to extract home directories
    while IFS=: read -r username _ _ _ _ home_dir _; do
        # Only include directories that exist and start with /home
        if [[ -d "$home_dir" && "$home_dir" == /home/* ]]; then
            home_dirs+=("$home_dir")
        fi
    done < /etc/passwd

    # Return the array
    echo "${home_dirs[@]}"
}

echo "== Home Directories =="
home_dirs=($(get_home_directories))
if [ ${#home_dirs[@]} -ne 0 ]; then
    for dir in "${home_dirs[@]}"; do
        echo "- $dir"
    done
else
    echo "No user home directories found."
fi
echo

check_ssh_config() {
    local ssh_config="/etc/ssh/sshd_config"
    local ssh_port
    local permit_root_login
    local password_authentication
    local pubkey_authentication

    # Check if SSH configuration file exists
    if [[ -f $ssh_config ]]; then
        # Get the SSH port, defaulting to 22 if not specified
        ssh_port=$(grep -E "^Port " "$ssh_config" | awk '{print $2}')
        ssh_port=${ssh_port:-22}  # Default to 22 if variable is empty

        # Get PermitRootLogin setting, defaulting to prohibit-password if not specified
        permit_root_login=$(grep -E "^PermitRootLogin " "$ssh_config" | awk '{print $2}')
        permit_root_login=${permit_root_login:-prohibit-password}

        # Get PasswordAuthentication setting, defaulting to yes if not specified
        password_authentication=$(grep -E "^PasswordAuthentication " "$ssh_config" | awk '{print $2}')
        password_authentication=${password_authentication:-yes}

        # Get PubkeyAuthentication setting, defaulting to not found if not specified
        pubkey_authentication=$(grep -E "^PubkeyAuthentication " "$ssh_config" | awk '{print $2}')
        pubkey_authentication=${pubkey_authentication:-not found}

        # Display the results
        echo "== SSH Configuration =="
        echo "SSH Port: $ssh_port"
        echo "PermitRootLogin: $permit_root_login"
        echo "PasswordAuthentication: $password_authentication"
        echo "PubkeyAuthentication: $pubkey_authentication"
        echo
    else
        echo "SSH configuration file not found at $ssh_config."
        missing_commands+=("SSH configuration check")
    fi
}

# Function to obfuscate and display public keys with type and comment
print_obfuscate_authorized_key_file() {
    local key_file="$1"

    # Check if the file exists and is readable
    if [[ -f "$key_file" && -r "$key_file" ]]; then
        while read -r key_line; do
            # Skip empty lines and comments
            [[ -z "$key_line" || "$key_line" =~ ^# ]] && continue
            
            # Extract key type, key, and comment
            local key_type=$(echo "$key_line" | awk '{print $1}')
            local key=$(echo "$key_line" | awk '{print $2}')
            local comment=$(echo "$key_line" | awk '{print $3}')

            # Obfuscate the key: first 4 and last 4 characters with ellipsis
            if [[ -n "$key" ]]; then
                local obfuscated_key="${key:0:4}...${key: -4}"
                echo "- $key_type $obfuscated_key $comment"
            fi
        done < "$key_file"
    else
        echo "Key file $key_file not found or not readable."
    fi
}

# Uses the home directories array to check for authorized_keys files, outputting any found
check_authorized_keys() {
    echo "== SSH Authorized Keys =="

    # Iterate over each home directory
    for dir in "${home_dirs[@]}"; do
        # Print the username based on the directory name
        username=$(basename "$dir")
        echo "User: $username"

        # Check if the .ssh directory exists
        if [ -d "$dir/.ssh" ]; then
            # Check if the authorized_keys file exists
            if [ -f "$dir/.ssh/authorized_keys" ]; then
                # Check if the file is empty
                if [ -s "$dir/.ssh/authorized_keys" ]; then
                    print_obfuscate_authorized_key_file "$dir/.ssh/authorized_keys"
                else
                    echo "The authorized_keys file is empty."
                fi
            else
                echo "No authorized_keys file found in: $dir/.ssh"
            fi
        else
            echo "No .ssh directory found in: $dir"
        fi
        echo
    done
    echo
}

# Run the SSH configuration checks, but only if we're running as root
if [ $(id -u) -eq 0 ]; then
    check_ssh_config
    check_authorized_keys
else
    echo "Skipping SSH configuration checks (requires root privileges)."
    echo
fi

# Print missing or failed commands at the end
if [ ${#missing_commands[@]} -ne 0 ]; then
    echo "The following commands were not found or failed:"
    for cmd in "${missing_commands[@]}"; do
        echo "- $cmd"
    done
fi

echo
