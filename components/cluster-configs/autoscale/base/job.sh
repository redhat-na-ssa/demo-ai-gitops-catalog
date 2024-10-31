#!/bin/bash
# shellcheck disable=SC1091

. /scripts/ocp.sh

ocp_machineset_create_autoscale "${MACHINE_MIN}" "${MACHINE_MAX}"
