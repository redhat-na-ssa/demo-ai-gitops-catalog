#!/usr/bin/bash
set -e

TIMEOUT_SECONDS=60

fix_dashboard_bugs(){
  echo ""

SERVERLESS_RESOURCES=(
    crd/serverlessservices.networking.internal.knative.dev:condition=established \
  )

  for crd in "${SERVERLESS_RESOURCES[@]}"
  do
    RESOURCE=$(echo "$crd" | cut -d ":" -f 1)
    CONDITION=$(echo "$crd" | cut -d ":" -f 2)

    echo "Waiting for ${RESOURCE} state to be ${CONDITION}..."
    oc wait --for="${CONDITION}" "${RESOURCE}" --timeout="${TIMEOUT_SECONDS}s"
  done
}

restart_pods(){
    oc -n redhat-ods-operator \
    delete pods \
    -l deployment=rhods-dashboard
}

fix_dashboard_bugs
restart_pods