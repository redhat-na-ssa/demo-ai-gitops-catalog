#!/bin/bash

# shellcheck disable=SC1091
. /scripts/ocp.sh

INSTANCE_TYPE=${INSTANCE_TYPE:-g4dn.4xlarge}

ocp_aws_cluster || exit 0
ocp_aws_create_gpu_machineset "${INSTANCE_TYPE}"
ocp_create_machineset_autoscale
# ocp_aws_taint_gpu_machineset
