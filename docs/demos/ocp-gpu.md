# Nvidia GPU Demos

## AWS GPU Notes

!!! NOTE
    AWS type `p4d.24xlarge` is currently only in availability zone `us-east-2b` and has 96 vCPU.

    If your cluster does not have a machine set in `us-east-2b` you
    will probably not be able to request this GPU type.

## Nvidia Multi Instance GPU (MIG) configuration on OpenShift

Red Hat Demo Platform Catalog (RHDP) option:

- `TBD`

!!! WARNING
    MIG demo is currently a WIP for RHDP and will likely NOT work

Error message

```sh
error launching instance: You have requested more vCPU capacity than your
current vCPU limit of 64 allows for the instance bucket that the specified
instance type belongs to. 
```

## Prerequisites

- Nvidia GPU hardware
  - A100
  - H100
  - A30

### Quickstart

Setup MIG single mode.

- Type: `p4d.24xlarge` = 8 x GPUs
- Profile: 1 GPU and 5GB of memory
- Resource: `nvidia.com/gpu: 1`

```sh
. scripts/functions.sh

ocp_nvidia_mig_config_setup single all-1g.5gb
```

## Nvidia MIG profiles

Setup MIG profile

```sh
. scripts/functions.sh

# setup MIG single
# ex: nvidia.com/gpu: 1
ocp_nvidia_mig_config_setup single all-1g.5gb
ocp_nvidia_mig_config_setup single all-2g.10gb

# setup MIG mixed
# ex: nvidia.com/mig-2g.10gb: 1
ocp_nvidia_mig_config_setup mixed all-balanced
```

Manually Pick MIG profile

```sh
# mode = single / mixed
MIG_CONFIG=all-1g.5gb
MIG_CONFIG=all-2g.10gb

# mode = mixed 
MIG_CONFIG=all-balanced
```

Manually apply MIG partitioning profile(s) - in mixed mode

```sh hl_lines="3"
# add profile label to `gpu` labeled node
oc label node --overwrite \
  -l "node-role.kubernetes.io/gpu" \
  "nvidia.com/mig.config=${MIG_CONFIG}"

# remove profile label
oc label node --overwrite \
  -l "node-role.kubernetes.io/gpu" \
  "nvidia.com/mig.config-"
```
