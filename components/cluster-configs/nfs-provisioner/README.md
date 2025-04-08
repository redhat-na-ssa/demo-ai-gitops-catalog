# NFS External Provisioner

- https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner

Quick Start

Modify the following values to match your environment

- `nfs-server.lan`  - NFS server name / IP Address
- `nfs-data`        - NFS export name

```sh
oc apply -k overlays/default
```
