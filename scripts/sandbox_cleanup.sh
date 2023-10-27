#!/bin/sh

# shellcheck source=/dev/null
. "$(dirname "$0")"/library/k8s.sh

sandbox_cleanup(){
  echo "Deleting most resources in sandbox..."
  echo "CTRL + C to cancel"
  sleep 8
    
  k8s_ns_delete_most_resources_force sandbox
}

sandbox_cleanup
