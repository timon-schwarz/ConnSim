# ConnSim


## Usage
Disclaimer: This container interacts with the network stack of the host and can therefore only be run on Linux systems. VRFs already present on your host might be deleted if the ID matches the one used by the container. All rules for the interfaces specified in your docker-compose.yml will be deleted.
The container has only been tested on Ubuntu Server LTS 22.


1. Install docker if not already present on your system
1. Install the iproute2 and iputils-ping packages or the equivalent packages of your distribution
1. Use ``mkdir`` to create a directory with a name of choice
1. ``cd`` into that directory
1. Create your docker-compose.yml. An example is provided below.
1. Execute ``docker-compose up -d``


## Example docker-compose.yml
````
version: '3'
services:
  web:
    image: ghcr.io/timon-schwarz/connsim:latest
    restart: unless-stopeed
    network_mode: host
    environment:
      GATEWAY_IP: 172.30.218.30
      INTERFACE_ens193: from_FN_cEDGE01
      INTERFACE_ens224: from_HQ_cEDGE01
      INTERFACE_ens225: from_RO_cEDGE01
      INTERFACE_ens257: from_HQ_cEDGE02
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    volumes:
      - /etc/iproute2/rt_tables:/etc/iproute2/rt_tables
````
