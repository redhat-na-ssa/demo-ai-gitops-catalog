# Reverse Tunnel

Having trouble exposing a lab environment to the internet? Maybe this will help.

TODO: make documentation

## Requirements

- Linux OS
  - Lab side (Private IP) - ssh (client)
  - Public Internet (Public IP) - sshd (server)

## Environment Vars

- `PUBLIC_IP` - Public IP used for public DNS
- `EGRESS_IP` - IP / CIDR for ssh client origin
- `OCP_API_IP` - Lab IP for OpenShift api.<cluster name >
- `OCP_APP_IP` - Lab IP for OpenShift *.apps.<cluster name >
- `OCP_DNS_NAME` - OpenShift cluster name (Public DNS records)
