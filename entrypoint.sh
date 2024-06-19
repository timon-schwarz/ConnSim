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

# Flush existing rules
ip rule flush

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
    
    # Check if the gateway is reachable via the interface
    ping -c 1 -I "$INTERFACE" "$GATEWAY_IP" &> /dev/null
    if [ $? -ne 0 ]; then
      echo "Error: Gateway $GATEWAY_IP is not reachable via interface $INTERFACE"
      continue
    fi
    
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
