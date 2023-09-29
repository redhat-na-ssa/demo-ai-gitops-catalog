#!/bin/bash

setup_operator_devspaces(){
  # setup devspaces operator
  oc apply -k components/operators/devspaces/operator/overlays/stable
  k8s_wait_for_crd checlusters.org.eclipse.che
  oc apply -k components/operators/devspaces/instance/overlays/timeout-12m
}

setup_operator_nfd(){
  # setup nfd operator
  oc apply -k components/operators/nfd/operator/overlays/stable
  k8s_wait_for_crd nodefeaturediscoveries.nfd.openshift.io
  oc apply -k components/operators/nfd/instance/overlays/only-nvidia
}

setup_operator_nvidia(){
  # setup nvidia gpu operator
  oc apply -k components/operators/gpu-operator-certified/operator/overlays/stable
  k8s_wait_for_crd clusterpolicies.nvidia.com
  oc apply -k components/operators/gpu-operator-certified/instance/overlays/time-slicing-4
}

setup_operator_pipelines(){
  # setup tekton operator
  oc apply -k components/operators/openshift-pipelines-operator-rh/operator/overlays/latest
  k8s_wait_for_crd pipelines.tekton.dev
}

setup_namespaces(){
  # setup namespaces
  oc apply -k components/configs/namespaces/overlays/default
}

check_cluster_version(){
  OCP_VERSION=$(oc version | sed -n '/Server Version: / s/Server Version: //p')
  AVOID_VERSIONS=()
  TESTED_VERSIONS=("4.12.33")

  echo "Current OCP version: ${OCP_VERSION}"
  echo "Tested OCP version(s): ${TESTED_VERSIONS[*]}"
  echo ""

  # shellcheck disable=SC2076
  if [[ " ${AVOID_VERSIONS[*]} " =~ " ${OCP_VERSION} " ]]; then
    echo "OCP version ${OCP_VERSION} is known to have issues with this demo"
    echo ""
    echo 'Recommend: "oc adm upgrade --to-latest=true"'
    echo ""
  fi
}
