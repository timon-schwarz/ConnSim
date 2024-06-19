#!/bin/bash

# Check if GATEWAY_IP is set
if [ -z "$GATEWAY_IP" ]; then
  echo "Error: GATEWAY_IP environment variable is not set."
  exit 1
fi

# Function to get the IP address of an interface
get_interface_ip() {
  ip -o -4 addr show "$1" | awk '{print $4}' | cut -d'/' -f1
}

# Function to check if an interface is up
is_interface_up() {
  ip link show "$1" | grep -q "state UP"
}

# Initialize table ID counter
TABLE_ID=100

# Iterate over environment variables to set one VRF per interface
# This ensures that traffic always exits on the port it has entered
for var in $(env); do
  if [[ $var == INTERFACE_* ]]; then
    # Extract interface and custom name
    INTERFACE=$(echo "$var" | cut -d'=' -f1 | sed 's/INTERFACE_//')
    CUSTOM_NAME=$(echo "$var" | cut -d'=' -f2)
    
    # Get the IP address of the interface
    INTERFACE_IP=$(get_interface_ip "$INTERFACE")
    if [ -z "$INTERFACE_IP" ]; then
      echo "Error: Unable to retrieve IP address for interface $INTERFACE"
      continue
    fi
    
    # Check if the interface is up
    if ! is_interface_up "$INTERFACE"; then
      echo "Error: Interface $INTERFACE is not up"
      continue
    fi
    
    echo "Configuring VRF $TABLE_ID for interface $INTERFACE ($CUSTOM_NAME: $INTERFACE_IP)"
    
    # Add table to /etc/iproute2/rt_tables
    echo "$TABLE_ID $INTERFACE" >> /etc/iproute2/rt_tables

    # Add rule for the interface with a unique table ID
    ip rule add iif "$INTERFACE" table "$TABLE_ID"
    
    # Add route for the interface with a unique table ID
    ip route add default via "$GATEWAY_IP" dev "$INTERFACE" table "$TABLE_ID"
    
    # Increment table ID for the next interface
    TABLE_ID=$((TABLE_ID + 1))
  fi
done

# Start the main application
exec gunicorn --workers 4 --bind 0.0.0.0:8080 app:app
