#!/bin/bash
# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

# Function to print usage
usage() {
    echo "Usage: $0 [-verbose]"
    exit 1
}

# Check if -verbose is passed as an argument
VERBOSE=""
if [[ "$1" == "-verbose" ]]; then
    VERBOSE="-verbose"
elif [[ "$#" -ne 0 ]]; then
    usage
fi

# Function to run the configure-host.sh script on a remote server
run_remote() {
    local server=$1
    local name=$2
    local ip=$3
    local hostentry=$4

    scp configure-host.sh remoteadmin@$server:/root
    ssh remoteadmin@$server -- "/root/configure-host.sh -name $name -ip $ip -hostentry $hostentry $VERBOSE"
}

# Run the script on the remote servers
run_remote "server1-mgmt" "loghost" "192.168.16.3" "webhost 192.168.16.4"
run_remote "server2-mgmt" "webhost" "192.168.16.4" "loghost 192.168.16.3"

# Run the script locally
./configure-host.sh -hostentry loghost 192.168.16.3 $VERBOSE
./configure-host.sh -hostentry webhost 192.168.16.4 $VERBOSE
