#!/bin/bash

# shellcheck disable=SC1091
. /scripts/ocp.sh

INSTANCE_TYPE=${INSTANCE_TYPE:-g4dn.4xlarge}

ocp_aws_cluster || exit 0
ocp_aws_machineset_create_gpu "${INSTANCE_TYPE}"
ocp_machineset_create_autoscale
ocp_aws_machineset_fix_storage
# ocp_machineset_taint_gpu
