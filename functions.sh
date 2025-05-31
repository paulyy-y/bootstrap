#! /bin/bash

scan_local_network() {
    # Get the local subnet (CIDR notation, e.g., 192.168.1.0/24)
    local subnet
    subnet=$(
        ip -o -f inet addr show |
        awk '/scope global/ {
            split($4, a, "/")
            print a[1]"/"a[2]
            exit
        }'
    )
    echo "Local subnet: $subnet"

    # Get all IP's from the local subnet using nmap
    local ips
    ips=$(nmap -sn "$subnet" | awk '/Nmap scan report for / {print $5}')

    # Get all IP's and hostnames from the local network.
    local ip
    for ip in $ips; do
        echo -n "$ip: "
        timeout 1 avahi-resolve-address "$ip"
    done
}