# kubevirt-wol

A Kubernetes Operator that enables Wake-on-LAN functionality for KubeVirt VirtualMachines.

**Installation**: This operator must be installed in the `kubevirt-wol-system` namespace.

**Prerequisites**: 
- **Required**: KubeVirt must be installed in your cluster.
- **Optional**: Prometheus Operator (for ServiceMonitor-based metrics collection). The operator works without it, but metrics will not be automatically scraped.

**Features**:
- Automatically starts VirtualMachines when WOL magic packets are received
- Supports multiple WOL ports (default: UDP 9)
- Three discovery modes: All VMs, Label Selector, or Explicit MAC mappings
- Dynamic agent deployment per WolConfig
- Automatic cleanup via OwnerReference
- Prometheus metrics integration (ServiceMonitor optional)

**Post-Installation (OpenShift)**: To enable metrics collection in OpenShift cluster monitoring, run:
```
oc label namespace <operator-namespace> openshift.io/cluster-monitoring=true
```
Replace `<operator-namespace>` with the namespace where the operator is installed (e.g., `kubevirt-wol-system`).

After labeling the namespace, the operator metrics will appear in OpenShift Console → Observe → Targets.

**Note on Metrics**: If Prometheus Operator is not installed, the ServiceMonitor resource will not be reconciled, but the operator will continue to function normally. Metrics are still available at the `/metrics` endpoint.

**Usage**: After installation, create a WolConfig resource to configure Wake-on-LAN for your KubeVirt VirtualMachines.

**Documentation**: https://github.com/gpillon/kubevirt-wol
