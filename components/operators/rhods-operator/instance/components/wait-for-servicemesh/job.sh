#!/usr/bin/bash
set -e

TIMEOUT_SECONDS=60

wait_for_service_mesh(){
  echo "Checking status of all service_mesh pre-reqs"

SERVICEMESH_RESOURCES=(
    crd/knativeservings.operator.knative.dev:condition=established \
    crd/servicemeshcontrolplanes.maistra.io:condition=established \
  )

  for crd in "${SERVICEMESH_RESOURCES[@]}"
  do
    RESOURCE=$(echo "$crd" | cut -d ":" -f 1)
    CONDITION=$(echo "$crd" | cut -d ":" -f 2)

    echo "Waiting for ${RESOURCE} state to be ${CONDITION}..."
    oc wait --for="${CONDITION}" "${RESOURCE}" --timeout="${TIMEOUT_SECONDS}s"

  done
}

approve_install(){
    oc -n redhat-ods-operator \
    patch subscription rhods-operator \
    --type=merge --patch '{"spec":{"installPlanApproval":{"Automatic"}}}'
}

wait_for_service_mesh
approve_install