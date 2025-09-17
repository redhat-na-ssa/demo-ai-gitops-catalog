# OpenShift Kludges

## OpenShift Nvidia GPU Issues

Affected Versions:
    - `4.18.22`
    - `4.18.23`

## Errors

!!! NOTE
    Nvidia GPU Cluster Policy stuck in `notReady`

This is a workaround for the following issue.

See https://github.com/NVIDIA/gpu-operator/issues/1598

```sh
oc apply -k https://raw.githubusercontent.com/redhat-na-ssa/demo-ai-gitops-catalog/refs/heads/main/dump/gpu-kludge-mcfg.yaml
```
