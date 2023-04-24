#!/bin/bash
set -e

# shellcheck source=/dev/null
source "$(dirname "$0")/functions.sh"

LANG=C
SLEEP_SECONDS=10
ARGO_NS="openshift-gitops"
ARGO_CHANNEL="stable"
ARGO_DEPLOY_STABLE=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)

wait_for_gitops(){
  echo "Waiting for operator to start"
  until oc get deployment gitops-operator-controller-manager -n openshift-operators
  do
    sleep 1
  done

  echo "Waiting for openshift-gitops namespace to be created"
  until oc get ns ${ARGO_NS} >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for deployments to start"
  until oc get deployment cluster -n ${ARGO_NS} >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for all pods to be created"
  for i in "${ARGO_DEPLOY_STABLE[@]}"
  do
    echo "Waiting for deployment $i"
    oc rollout status deployment "$i" -n ${ARGO_NS} >/dev/null 2>&1
  done

  echo ""
  echo "OpenShift GitOps successfully installed."
}

install_gitops(){
  echo ""
  echo "Installing GitOps Operator."

  # kustomize build components/operators/openshift-gitops-operator/operator/overlays/stable | oc apply -f -
  oc apply -k "components/operators/openshift-gitops-operator/operator/overlays/${ARGO_CHANNEL}"

  echo "Pause ${SLEEP_SECONDS} seconds for the creation of the gitops-operator..."
  sleep ${SLEEP_SECONDS}

  wait_for_gitops

}

bootstrap_cluster(){

  PS3="Please select a bootstrap folder: "
  
  select bootstrap_dir in bootstrap/overlays/*/; 
  do
      test -n "$bootstrap_dir" && break;
      echo ">>> Invalid Selection";
  done

  echo "Selected: ${bootstrap_dir}"
  # kustomize build "${bootstrap_dir}" | oc apply -f -
  oc apply -k "${bootstrap_dir}"

  wait_for_gitops
  
  echo
  echo "GitOps has successfully deployed!  Check the status of the sync here:"

  route=$(oc get route openshift-gitops-server -o jsonpath='{.spec.host}' -n ${ARGO_NS})

  echo "https://${route}"
}

kludges(){
  [ -e "scripts/kludges.sh" ] && scripts/kludges.sh
}

# functions
setup_bin
check_bin oc
# check_bin kustomize
# check_bin kubeseal
check_oc_login

# bootstrap
sealed_secret_check
install_gitops
bootstrap_cluster

# kludges
