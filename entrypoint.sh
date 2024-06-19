#!/bin/bash

# Check if GATEWAY_IP is set
if [ -z "$GATEWAY_IP" ]; then
  echo "Error: GATEWAY_IP environment variable is not set."
  exit 1
fi

# Flush existing rules
ip rule flush

# Iterate over environment variables to set one vrf per interface
# This ensured that traffic always exits on the port is has entered
# This is imporant because the connections are only applied on the outgoing interface
# Without this all traffic would be sent out of one random interface and the metrics of said interface
for var in $(env); do
  if [[ $var == INTERFACE_* ]]; then
    # Extract interface and custom name
    INTERFACE=$(echo "$var" | cut -d'=' -f1 | sed 's/INTERFACE_//')
    CUSTOM_NAME=$(echo "$var" | cut -d'=' -f2)
    
    # Add rule for the interface
    ip rule add iif "$INTERFACE" table "$INTERFACE"
    
    # Add route for the interface
    ip route add default via "$GATEWAY_IP" dev "$INTERFACE" table "$INTERFACE"
  fi
done

# Start the main application
exec gunicorn --workers 4 --bind 0.0.0.0:8080 app:app
