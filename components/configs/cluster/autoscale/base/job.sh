#!/usr/bin/env bash
# shellcheck disable=SC1091

. /scripts/ocp.sh

ocp_create_machineset_autoscale "${MACHINE_MIN}" "${MACHINE_MAX}"
