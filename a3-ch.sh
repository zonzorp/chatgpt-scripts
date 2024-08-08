#!/bin/bash

# Trap signals to ignore
trap '' TERM HUP INT

# Function to print usage
usage() {
    echo "Usage: $0 [-verbose] [-name desiredName] [-ip desiredIPAddress] [-hostentry desiredName desiredIPAddress]"
    exit 1
}

# Variables
VERBOSE=0
HOSTNAME=""
IP=""
HOSTENTRY_NAME=""
HOSTENTRY_IP=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -verbose) VERBOSE=1 ;;
        -name) HOSTNAME="$2"; shift ;;
        -ip) IP="$2"; shift ;;
        -hostentry) HOSTENTRY_NAME="$2"; HOSTENTRY_IP="$3"; shift 2 ;;
        *) usage ;;
    esac
    shift
done

# Function to log messages if verbose mode is enabled
log_verbose() {
    if [[ $VERBOSE -eq 1 ]]; then
        echo "$1"
    fi
}

# Function to apply hostname
apply_hostname() {
    current_hostname=$(hostname)
    if [[ "$HOSTNAME" != "" && "$HOSTNAME" != "$current_hostname" ]]; then
        log_verbose "Changing hostname from $current_hostname to $HOSTNAME"
        echo "$HOSTNAME" > /etc/hostname
        hostnamectl set-hostname "$HOSTNAME"
        sed -i "s/127.0.1.1.*$/127.0.1.1 $HOSTNAME/" /etc/hosts
        logger "Hostname changed from $current_hostname to $HOSTNAME"
    else
        log_verbose "Hostname is already set to $HOSTNAME"
    fi
}

# Function to apply IP address
apply_ip() {
    if [[ "$IP" != "" ]]; then
        current_ip=$(hostname -I | awk '{print $1}')
        if [[ "$IP" != "$current_ip" ]]; then
            log_verbose "Changing IP address from $current_ip to $IP"
            sed -i "s/$current_ip/$IP/" /etc/hosts
            sed -i "s/addresses: \[.*\]/addresses: [$IP\/24]/" /etc/netplan/01-netcfg.yaml
            netplan apply
            logger "IP address changed from $current_ip to $IP"
        else
            log_verbose "IP address is already set to $IP"
        fi
    fi
}

# Function to apply host entry
apply_hostentry() {
    if [[ "$HOSTENTRY_NAME" != "" && "$HOSTENTRY_IP" != "" ]]; then
        if grep -q "$HOSTENTRY_NAME" /etc/hosts; then
            current_hostentry_ip=$(grep "$HOSTENTRY_NAME" /etc/hosts | awk '{print $1}')
            if [[ "$current_hostentry_ip" != "$HOSTENTRY_IP" ]]; then
                log_verbose "Updating /etc/hosts entry for $HOSTENTRY_NAME to $HOSTENTRY_IP"
                sed -i "s/^.*$HOSTENTRY_NAME.*$/$HOSTENTRY_IP $HOSTENTRY_NAME/" /etc/hosts
                logger "/etc/hosts entry updated for $HOSTENTRY_NAME to $HOSTENTRY_IP"
            else
                log_verbose "/etc/hosts entry for $HOSTENTRY_NAME is already set to $HOSTENTRY_IP"
            fi
        else
            log_verbose "Adding /etc/hosts entry for $HOSTENTRY_NAME to $HOSTENTRY_IP"
            echo "$HOSTENTRY_IP $HOSTENTRY_NAME" >> /etc/hosts
            logger "/etc/hosts entry added for $HOSTENTRY_NAME to $HOSTENTRY_IP"
        fi
    fi
}

# Apply settings
apply_hostname
apply_ip
apply_hostentry
