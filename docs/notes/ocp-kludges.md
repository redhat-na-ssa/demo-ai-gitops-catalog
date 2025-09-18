# OpenShift - Kludges

!!! Danger "Danger"
    The following solutions are **NOT intended for production**

## Nvidia GPU operator stuck in `notReady`

!!! INFO "OpenShift 4.18.22+"

!!! WARNING "Error"
    Nvidia GPU `ClusterPolicy` stuck in `notReady`

This is a workaround for the following issue:

<https://github.com/NVIDIA/gpu-operator/issues/1598>

!!! bug
    OCP 4.18.22: nvidia-operator-validator pod in Init:CreateContainerError - error executing hook /usr/local/nvidia/toolkit/nvidia-container-runtime-hook (exit code: 1)

[YAML Source](https://raw.githubusercontent.com/redhat-na-ssa/demo-ai-gitops-catalog/b042ba4c827a90b638625a4d017fe067745f64d2/dump/gpu-kludge-mcfg.yaml)

Command Example

```sh
oc apply -f https://raw.githubusercontent.com/redhat-na-ssa/demo-ai-gitops-catalog/b042ba4c827a90b638625a4d017fe067745f64d2/dump/gpu-kludge-mcfg.yaml
```
