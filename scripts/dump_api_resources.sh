#!/bin/bash
# shellcheck disable=SC2034,SC1091

. "$(dirname "$0")/library/k8s.sh"

k8s_api_dump_resources
