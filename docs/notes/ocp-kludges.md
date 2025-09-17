# OpenShift Kludges

## Nvidia GPU operator stuck in `notReady`

!!! INFO "OpenShift 4.18.22+"

!!! WARNING "Error"
    Nvidia GPU `ClusterPolicy` stuck in `notReady`

This is a workaround for the following issue:

https://github.com/NVIDIA/gpu-operator/issues/1598

[YAML Source](https://raw.githubusercontent.com/redhat-na-ssa/demo-ai-gitops-catalog/b042ba4c827a90b638625a4d017fe067745f64d2/dump/gpu-kludge-mcfg.yaml)

Command Example

```sh
oc apply -k https://raw.githubusercontent.com/redhat-na-ssa/demo-ai-gitops-catalog/b042ba4c827a90b638625a4d017fe067745f64d2/dump/gpu-kludge-mcfg.yaml
```
