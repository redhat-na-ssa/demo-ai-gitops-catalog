# nvidia-network-operator

## NVIDIA Network Operator
The NVIDIA Network Operator simplifies the provisioning and management of NVIDIA networking resources  in a Kubernetes cluster. The operator automatically installs the required host networking software - bringing together all the needed components to provide high-speed network connectivity. These components include the NVIDIA networking driver, Kubernetes device plugin, CNI plugins, IP address management (IPAM) plugin and others.
The NVIDIA Network Operator works in conjunction with the NVIDIA GPU Operator to deliver high-throughput, low-latency networking for scale-out, GPU computing clusters.

The Network Operator uses Node Feature Discovery (NFD) labels in order to properly schedule resources.
Nodes can be labelled manually or using the NFD Operator. An example of `NodeFeatureDiscovery`
configuration is available in the documentation.
The following NFD labels are used:
`feature.node.kubernetes.io/pci-15b3.present` for nodes containing NVIDIA Networking hardware.
`feature.node.kubernetes.io/pci-10de.present` for nodes containing NVIDIA GPU hardware.

The Network Operator is open-source. For more information on contributions and release artifacts, see the [GitHub repo](https://github.com/Mellanox/network-operator/)
