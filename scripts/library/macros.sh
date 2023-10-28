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
  oc apply -k components/operators/gpu-operator-certified/instance/overlays/time-slicing-2
}

setup_operator_pipelines(){
  # setup tekton operator
  oc apply -k components/operators/openshift-pipelines-operator-rh/operator/overlays/latest
  k8s_wait_for_crd pipelines.tekton.dev
}

setup_namespaces(){
  # setup namespaces
  oc apply -k components/configs/cluster/namespaces/overlays/default
}
