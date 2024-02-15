#!/bin/bash

# LANG=C
SLEEP_SECONDS="${SLEEP_SECONDS:-8}"

ARGO_NS="openshift-gitops"
ARGO_CHANNEL="latest"
ARGO_KUSTOMIZE_OPERATOR="${GIT_ROOT}/components/operators/openshift-gitops-operator/operator/overlays/${ARGO_CHANNEL}"
ARGO_KUSTOMIZE_INSTANCE="${GIT_ROOT}/components/operators/openshift-gitops-operator/instance/overlays/default"

argo_print_info(){
  route=$(oc get route openshift-gitops-server -o jsonpath='{.spec.host}' -n ${ARGO_NS} 2>/dev/null)

  [ -z ${route+x} ] || return 1
  echo
  echo "Access ArgoCD here:"
  echo "https://${route}"
  echo
}

argo_wait_for_operator(){
  ARGO_DEPLOY_STABLE=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)

  echo "Waiting for OpenShift GitOps operator to start"
  until oc get deployment gitops-operator-controller-manager -n openshift-operators >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for openshift-gitops namespace to be created"
  until oc get ns ${ARGO_NS} >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for OpenShift GitOps deployments to start"
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
  echo "Installing OpenShift GitOps Operator..."

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

argo_uninstall(){
  ARGO_DEPLOY_STABLE=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)

  for i in "${ARGO_DEPLOY_STABLE[@]}"
  do
    echo "Scaling OpenShift GitOps deployment $i to 0"
    oc scale --replicas=0 deployment "$i" -n "${ARGO_NS}"
  done

  # shellcheck disable=SC2034 
  NAMESPACE="${ARGO_NS}"

  k8s_null_finalizers_for_all_resource_instances applicationsets.argoproj.io
  oc delete applicationsets.argoproj.io -n "${ARGO_NS}" --all

  k8s_null_finalizers_for_all_resource_instances application.argoproj.io
  oc delete application.argoproj.io -n "${ARGO_NS}" --all

  k8s_null_finalizers_for_all_resource_instances argocds.argoproj.io
  oc delete argocds.argoproj.io -n "${ARGO_NS}" --all

  oc delete -k "${ARGO_KUSTOMIZE_OPERATOR}"
  oc delete -k "${ARGO_KUSTOMIZE_INSTANCE}"
  
  oc delete project "${ARGO_NS}"-operator
  oc delete project "${ARGO_NS}"
}
