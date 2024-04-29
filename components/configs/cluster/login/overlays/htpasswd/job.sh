#!/usr/bin/env bash
# set -x

init-htpasswd(){
  OBJECT=${OBJECT:-secret/htpasswd-local}

  # check for secret
  if oc -n "${NS}" get "${OBJECT}" >/dev/null 2>&1; then
    echo "exists: ${OBJECT} in ${NS}"
  else
    echo "create: ${OBJECT} in namespace ${NS}"
    oc apply -f /scripts/htpasswd-secret.yaml
  fi
}

init-htpasswd
