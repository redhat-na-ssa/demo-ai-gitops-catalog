#!/usr/bin/bash
# shellcheck disable=SC2119,SC2120
set -e

TIMEOUT_SECONDS=120

self_destruct(){

  echo "
    engaging self cleaning in ${TIMEOUT_SECONDS}s...
  "
  sleep "${TIMEOUT_SECONDS}"
  oc -n redhat-ods-operator delete jobs --all
}

approve_installplan(){
  echo -n 'Waiting for RHOAI install plan...'
  until oc -n redhat-ods-operator get installplan -l operators.coreos.com/rhods-operator.redhat-ods-operator -o name >/dev/null 2>&1
  do
    echo -n .
    sleep 5
  done; echo

  INSTALL_PLAN=$(oc -n redhat-ods-operator get installplan -l operators.coreos.com/rhods-operator.redhat-ods-operator -o name)
  oc -n redhat-ods-operator \
    patch "${INSTALL_PLAN}" \
    --type=merge --patch '{"spec":{"approved":true}}'
}

patch_approval(){
  APPROVAL=${1:-Automatic}

  echo -n 'Waiting for RHOAI subscription...'
  until oc get -n redhat-ods-operator subscriptions.operators.coreos.com/rhods-operator -o name >/dev/null 2>&1
  do
    echo -n .
    sleep 5
  done; echo

  oc -n redhat-ods-operator \
    patch subscriptions.operators.coreos.com/rhods-operator \
    --type=merge --patch '{"spec":{"installPlanApproval":"'"${APPROVAL}"'"}}'
}

wait_for_service_mesh(){
  echo "Checking status of all service_mesh pre-reqs"

  SERVICEMESH_RESOURCES=(
    crd/knativeservings.operator.knative.dev:condition=established
    crd/servicemeshcontrolplanes.maistra.io:condition=established
    crd/servicemeshmembers.maistra.io:condition=established
  )

  for crd in "${SERVICEMESH_RESOURCES[@]}"
  do
    RESOURCE=$(echo "$crd" | cut -d ":" -f 1)
    CONDITION=$(echo "$crd" | cut -d ":" -f 2)

    echo "Waiting for ${RESOURCE} state to be ${CONDITION}..."
    oc wait --for="${CONDITION}" "${RESOURCE}" --timeout="${TIMEOUT_SECONDS}s" >/dev/null 2>&1
  done
}

wait_for_service_mesh
patch_approval
approve_installplan
self_destruct
