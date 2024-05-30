#!/bin/bash
# set -x

fix_sealed_secret(){
# annotate secret
if oc -n "${NS}" get "${OBJECT}" >/dev/null 2>&1; then
  oc -n "${NS}" \
    annotate secret \
    --overwrite=true \
    "${OBJECT}" sealedsecrets.bitnami.com/managed="true"

  # check for sealed secret
  if oc -n "${NS}" get sealedsecret "${OBJECT##*/}" >/dev/null 2>&1; then
    # check sync on sealed secret
    SYNCED=$(oc -n "${NS}" \
      get sealedsecret "${OBJECT##*/}" \
      --no-headers \
      -o custom-columns="NAME:.status.conditions[0].status") || true
    # delete sealed secret if in error
    echo "${SYNCED}" | grep -qi "False" && \
      oc -n "${NS}" \
        delete sealedsecret "${OBJECT##*/}" || echo SYNCED: True
  fi
else
  echo "secret ${OBJECT##*/} not in ${NS}"
fi
}

fix_sealed_secret