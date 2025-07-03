#!/bin/bash
# set -x

ADHOC_DIR=${ADHOC_DIR:-/scripts/custom}
ADHOC_SCRIPT=${ADHOC_SCRIPT:-/scripts/custom.sh}
TIMEOUT=60

self_destruct(){
  [ -z "${NAMESPACE}" ] && return
  
  echo "
    engaging self cleaning...
    removing project: ${NAMESPACE} in ${TIMEOUT}s
  "
  
  sleep "${TIMEOUT}"
  oc delete project "${NAMESPACE}"
}

run_adhoc(){
  if [ -e "${ADHOC_SCRIPT}" ]; then
    echo "running: ${ADHOC_SCRIPT}..."
    "${ADHOC_SCRIPT}"

  elif [ -d "${ADHOC_DIR}" ]; then
    echo "running: *.sh in ${ADHOC_DIR}/..."
    
    for sh in "${ADHOC_DIR}/"*.sh
    do
      [ -e "${sh}" ] || return 0
        echo "running: ${sh}..."
        "${sh}"
    done

  else

    echo "You are likely using this wrong...

      But you are brave, because you are trying new things!
    "

    echo "usage:

      set \${ADHOC_SCRIPT} for an individual script
      set \${ADHOC_DIR} for a collection of *.sh scripts

      Missing script: ${ADHOC_SCRIPT}
      Missing script(s) in: ${ADHOC_DIR}/
    "

    sleep "${TIMEOUT}"
    return 1
  fi
}

run_adhoc && self_destruct
