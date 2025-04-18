#!/bin/bash

# shellcheck disable=SC1091
. /scripts/ocp.sh

INSTANCE_TYPE=${INSTANCE_TYPE:-g4dn.4xlarge}

ocp_aws_cluster || exit 0
ocp_aws_machineset_clone_worker g6.xlarge gpu-l4-machineset
ocp_aws_machineset_clone_worker g5.xlarge gpu-a10-machineset
ocp_aws_machineset_fix_storage gpu-l4-machineset 400
ocp_aws_machineset_fix_storage gpu-a10-machineset 400
