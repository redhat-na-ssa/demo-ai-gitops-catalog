# Reverse Tunnel

Having trouble exposing a (private) lab environment to the internet? Maybe this will help.

TODO: make documentation

## Requirements

- Linux OS
  - Lab side (Private IP) - ssh (client)
  - Public Internet (Public IP) - sshd (server)

## Environment Vars

- `OCP_API_IP`    - Lab (private) IP for OpenShift api.<cluster name >
- `OCP_APP_IP`    - Lab (private) IP for OpenShift *.apps.<cluster name >
- `OCP_DNS_NAME`  - OpenShift cluster name (public DNS records)
- `PUBLIC_IP`     - Public IP used for public DNS
- `EGRESS_IP`     - IP / CIDR for ssh client origin
