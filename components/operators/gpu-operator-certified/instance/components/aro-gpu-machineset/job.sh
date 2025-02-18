#!/bin/bash

# shellcheck disable=SC1091
. /scripts/ocp.sh

INSTANCE_TYPE=${INSTANCE_TYPE:-Standard_NC64as_T4_v3}

ocp_aro_cluster || exit 0
ocp_aro_machineset_create_gpu "${INSTANCE_TYPE}"
ocp_machineset_create_autoscale
# ocp_machineset_taint_gpu
