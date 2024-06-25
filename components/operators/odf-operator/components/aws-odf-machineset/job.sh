#!/bin/bash
# shellcheck disable=SC1091

. /scripts/ocp.sh

INSTANCE_TYPE=${INSTANCE_TYPE:-m6a.2xlarge}

ocp_aws_cluster || exit 0
ocp_aws_create_odf_machineset "${INSTANCE_TYPE}"
