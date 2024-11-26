# Host Detective

Basic script to output host information. Requires no dependencies.

## What the script outputs
The script attempts to gather and display various information about the host:

- Hostname
- IP addresses (IPv4 and IPv6)
- System hardware details
- Operating system details
- SSH configuration
- Obfuscated authorized SSH public keys (from `~/.ssh/authorized_keys`) for each user

## Safety and privacy
- This script outputs various sensitive information about the host and its users
- Always run the script in a secure environment
- Be cautious when sharing the output with others
- The script outputs obfuscated SSH public keys (first 4 and last 4 characters) along with their type (e.g., `ssh-rsa`) and comment. Comments in the `authorized_keys` file may include usernames, email addresses and other identifying or sensitive information.

## Download and run

Using curl:
```bash
curl -sSL https://raw.githubusercontent.com/ledurnan/hostdet/main/hostdet.sh -o hostdet.sh
chmod +x hostdet.sh
./hostdet.sh
```

One-liner:
```bash
curl -sSL https://raw.githubusercontent.com/ledurnan/hostdet/main/hostdet.sh -o hostdet.sh && chmod +x hostdet.sh && ./hostdet.sh
```

Using wget:
```bash
wget https://raw.githubusercontent.com/ledurnan/hostdet/main/hostdet.sh -O hostdet.sh
chmod +x hostdet.sh
./hostdet.sh
```

One-liner:
```bash
wget https://raw.githubusercontent.com/ledurnan/hostdet/main/hostdet.sh -O hostdet.sh && chmod +x hostdet.sh && ./hostdet.sh
```