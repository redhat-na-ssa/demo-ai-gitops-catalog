#!/usr/bin/bash
set -e

TIMEOUT_SECONDS=60

patch_approval(){
  APPROVAL=${1:-Automatic}

  echo -n 'Waiting for RHOAI subscription.'
  until oc get -n redhat-ods-operator subscription rhods-operator -o name 2>/dev/null
  do
    echo -n .
    sleep 5
  done; echo

  oc -n redhat-ods-operator \
    patch subscription rhods-operator \
    --type=merge --patch '{"spec":{"installPlanApproval":"'"${APPROVAL}"'"}}'

  echo -n 'Waiting for RHOAI install plan.'
  until oc -n redhat-ods-operator get installplan -l operators.coreos.com/rhods-operator.redhat-ods-operator 2>/dev/null
  do
    echo -n .
    sleep 5
  done; echo

  INSTALL_PLAN=$(oc -n redhat-ods-operator get installplan -l operators.coreos.com/rhods-operator.redhat-ods-operator -o name)
  oc -n redhat-ods-operator \
    patch "${INSTALL_PLAN}" \
    --type=merge --patch '{"spec":{"approved":true}}'
}

wait_for_service_mesh(){
  echo "Checking status of all service_mesh pre-reqs"

SERVICEMESH_RESOURCES=(
    crd/knativeservings.operator.knative.dev:condition=established
    crd/servicemeshcontrolplanes.maistra.io:condition=established
  )

  for crd in "${SERVICEMESH_RESOURCES[@]}"
  do
    RESOURCE=$(echo "$crd" | cut -d ":" -f 1)
    CONDITION=$(echo "$crd" | cut -d ":" -f 2)

    echo "Waiting for ${RESOURCE} state to be ${CONDITION}..."

    oc wait --for="${CONDITION}" "${RESOURCE}" --timeout="1s" 2>/dev/null && continue
    patch_approval Manual

    oc wait --for="${CONDITION}" "${RESOURCE}" --timeout="${TIMEOUT_SECONDS}s"
  done
}

wait_for_service_mesh
patch_approval
