#!/bin/bash
# set -x

ADHOC_SCRIPT=${ADHOC_SCRIPT:-/scripts/custom/job.sh}

run_adhoc(){
  if [ -e "${ADHOC_SCRIPT}" ]; then
    echo "running: ${ADHOC_SCRIPT}..."
    "${ADHOC_SCRIPT}"
  else
    echo "missing: ${ADHOC_SCRIPT}"
    echo "You are using this wrong. But you are brave, because you are trying new things!"
    return 0
  fi
}

run_adhoc
