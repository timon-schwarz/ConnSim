# NETSIM


## Usage
Disclaimer: This container interacts with the network stack of the host and can therefore only be run on Linux systems.
The container has only been tested on Ubuntu Server LTS 24.


1. Install docker if not already present on your system
1. Use ``mkdir`` to create a directory with a name of choice
1. ``cd`` into that directory
1. Create your docker-compose.yml. An example is provided below.
1. Execute ``docker-compose up -d``


## Example docker-compose.yml
````
version: '3'
services:
  web:
    image: ghcr.io/timon-schwarz/NetSim:latest
    restart: always
    network_mode: host
    environment:
      PYTHONUNBUFFERED: 1
      INTERFACE_ens193: from FN_cEDGE01
      INTERFACE_ens224: from HQ_cEDGE01
      INTERFACE_ens225: from RO_cEDGE01
      INTERFACE_ens257: from HQ_cEDGE02
    cap_add:
      - NET_ADMIN
      - SYS_MODULE

````
