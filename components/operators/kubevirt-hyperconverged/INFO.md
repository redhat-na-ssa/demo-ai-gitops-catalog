# kubevirt-hyperconverged

# Requirements
Your cluster must be installed on bare metal infrastructure with Red Hat Enterprise Linux CoreOS workers.

# Details
**OpenShift Virtualization** extends Red Hat OpenShift Container Platform, allowing you to host and manage virtualized workloads on the same platform as container-based workloads. From the OpenShift Container Platform web console, you can import a VMware virtual machine from vSphere, create new or clone existing VMs, perform live migrations between nodes, and more. You can use OpenShift Virtualization to manage both Linux and Windows VMs.

The technology behind OpenShift Virtualization is developed in the [KubeVirt](https://kubevirt.io) open source community. The KubeVirt project extends [Kubernetes](https://kubernetes.io) by adding additional virtualization resource types through [Custom Resource Definitions](https://kubernetes.io/docs/tasks/access-kubernetes-api/extend-api-custom-resource-definitions/) (CRDs). Administrators can use Custom Resource Definitions to manage `VirtualMachine` resources alongside all other resources that Kubernetes provides.