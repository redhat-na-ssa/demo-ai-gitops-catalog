#!/bin/bash
# set -x

init-htpasswd(){
  NS=${NS:-openshift-config}
  OBJECT=${1:-secret/htpasswd-local}
  FILE=${2:-htpasswd-secret.yaml}

  # check for secret
  if oc -n "${NS}" get "${OBJECT}" >/dev/null 2>&1; then
    echo "exists: ${OBJECT} in ${NS}"
  else
    echo "create: ${OBJECT} in namespace ${NS}"
    oc apply -f /scripts/"${FILE}"
  fi
}

init-htpasswd secret/htpasswd-local htpasswd-local.yaml
init-htpasswd secret/htpasswd-workshop htpasswd-workshop.yaml
