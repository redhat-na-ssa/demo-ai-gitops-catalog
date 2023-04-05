#!/bin/bash
set -e

# shellcheck source=/dev/null
source "$(dirname "$0")/functions.sh"

LANG=C
SLEEP_SECONDS=45
ARGO_NS="openshift-gitops"

install_gitops(){
  echo ""
  echo "Installing GitOps Operator."

  # kustomize build components/operators/openshift-gitops-operator/operator/overlays/latest | oc apply -f -
  oc apply -k components/operators/openshift-gitops-operator/operator/overlays/latest

  echo "Pause ${SLEEP_SECONDS} seconds for the creation of the gitops-operator..."
  sleep ${SLEEP_SECONDS}

  echo "Waiting for operator to start"
  until oc get deployment gitops-operator-controller-manager -n openshift-operators
  do
    sleep 5
  done

  echo "Waiting for openshift-gitops namespace to be created"
  until oc get ns ${ARGO_NS}
  do
    sleep 5
  done

  echo "Waiting for deployments to start"
  until oc get deployment cluster -n ${ARGO_NS}
  do
    sleep 5
  done

  echo "Waiting for all pods to be created"
  deployments=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)
  for i in "${deployments[@]}"
  do
    echo "Waiting for deployment $i"
    oc rollout status deployment "$i" -n ${ARGO_NS}
  done

  echo ""
  echo "OpenShift GitOps successfully installed."

}

bootstrap_cluster(){

  PS3="Please select a bootstrap folder: "
  
  select bootstrap_dir in bootstrap/overlays/*/; 
  do
      test -n "$bootstrap_dir" && break;
      echo ">>> Invalid Selection";
  done

  echo "Selected: ${bootstrap_dir}"
  echo "Apply overlay to override default instance"
  # kustomize build "${bootstrap_dir}" | oc apply -f -
  oc apply -k "${bootstrap_dir}"

  sleep 10
  echo "Waiting for all pods to redeploy"
  deployments=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)
  for i in "${deployments[@]}"
  do
    echo "Waiting for deployment $i"
    oc rollout status deployment "$i" -n ${ARGO_NS}
  done

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
check_sealed_secret
install_gitops
bootstrap_cluster

# kludges
