# Bare Metal Hosts (BMH)

## Associating `BMH` with `MachineSets`

### Using `matchLabels`

The [HostSelector specifies matching criteria for labels on BareMetalHosts.](https://pkg.go.dev/github.com/openshift/cluster-api-provider-baremetal/pkg/apis/baremetal/v1alpha1#HostSelectorRequirement)

Below is an example of using `hostSelector` in combination with `matchLabels` to allow a specific `BMH` to be targeted for use in provisioning a `MachineSet`.

Label the `BMH` with a `label` of `machine.openshift.io/zone: us-east-1a`

!!! NOTE
    The `label` can be any `key: value` pair

```yaml hl_lines="7"
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: vm-00
  namespace: openshift-machine-api
  labels:
    machine.openshift.io/zone: us-east-1a
spec:
```

```yaml hl_lines="18-20"
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  name: worker-0
  namespace: openshift-machine-api
spec:
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-machineset: worker-0
  template:
    metadata:
      labels:
        machine.openshift.io/region: us-east-1
        machine.openshift.io/zone: us-east-1a
    spec:
      providerSpec:
        value:
          hostSelector:
            matchLabels:
              machine.openshift.io/zone: us-east-1a
```

## Using `HostSelectorRequirement`

More detailed selection should be possible using common [operators](https://pkg.go.dev/k8s.io/apimachinery/pkg/selection#Operator). It's not clear how this can be used (update required).

See [HostSelectorRequirement](https://pkg.go.dev/github.com/openshift/cluster-api-provider-baremetal/pkg/apis/baremetal/v1alpha1#HostSelectorRequirement)

```yaml hl_lines="7"
apiVersion: metal3.io/v1alpha1
kind: BareMetalHost
metadata:
  name: vm-00
  namespace: openshift-machine-api
  labels:
    machine.openshift.io/zone: us-east-1a
spec:
```

```yaml hl_lines="18-20"
apiVersion: machine.openshift.io/v1beta1
kind: MachineSet
metadata:
  name: worker-0
  namespace: openshift-machine-api
spec:
  selector:
    matchLabels:
      machine.openshift.io/cluster-api-machineset: worker-0
  template:
    metadata:
      labels:
        machine.openshift.io/region: us-east-1
        machine.openshift.io/zone: us-east-1a
    spec:
      providerSpec:
        value:
          hostSelector:
            matchExpressions:
              - key: "machine.openshift.io/zone"
                operator: Equals
                values:
                  - us-east-1a
```
