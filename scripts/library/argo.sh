#!/bin/bash

# LANG=C
SLEEP_SECONDS="${SLEEP_SECONDS:-8}"

ARGO_NS="openshift-gitops"
ARGO_CHANNEL="stable"
ARGO_KUSTOMIZE_OPERATOR="components/operators/openshift-gitops-operator/operator/overlays/${ARGO_CHANNEL}"
ARGO_KUSTOMIZE_INSTANCE="components/operators/openshift-gitops-operator/instance/overlays/default"

argo_print_info(){
  route=$(oc get route openshift-gitops-server -o jsonpath='{.spec.host}' -n ${ARGO_NS} 2>/dev/null)

  [ -z ${route+x} ] || return
  echo
  echo "Access ArgoCD here:"
  echo "https://${route}"
  echo
}

argo_wait_for_operator(){
  ARGO_DEPLOY_STABLE=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)

  echo "Waiting for operator to start"
  until oc get deployment gitops-operator-controller-manager -n openshift-operators >/dev/null 2>&1
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
    oc rollout status deployment "$i" -n "${ARGO_NS}" >/dev/null 2>&1
  done

  echo
}

argo_install(){
  echo
  echo "Installing GitOps Operator..."

  oc apply -k "${ARGO_KUSTOMIZE_OPERATOR}"

  echo "Pause ${SLEEP_SECONDS} seconds for the creation of the gitops-operator..."
  sleep "${SLEEP_SECONDS}"

  argo_wait_for_operator

  # apply the cr you know and love
  oc apply -k "${ARGO_KUSTOMIZE_INSTANCE}"

  echo
  echo "OpenShift GitOps successfully installed."

  argo_print_info

}
