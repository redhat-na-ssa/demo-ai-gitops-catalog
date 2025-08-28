#!/bin/bash

ocp_annotate_ns_tolerations_master(){
  NAMESPACE=${1}
  [ -z ${NAMESPACE+x} ] && return
  # oc annotate ns openshift-terminal openshift.io/node-selector="node-role.kubernetes.io/master"
  # oc annotate ns openshift-terminal scheduler.alpha.kubernetes.io/node-selector='node-role.kubernetes.io/master='  # poorly documented: format has to be of "selector-label=label-val"
  oc annotate ns "${NAMESPACE}" scheduler.alpha.kubernetes.io/defaultTolerations='[{"effect":"NoSchedule","key":"node-role.kubernetes.io/master","operator":"Exists"},{"effect":"NoExecute","key":"node-role.kubernetes.io/master","operator":"Exists"}]'
}

ocp_annotate_ns_tolerations_master_remove(){
  NAMESPACE=${1}
  [ -z ${NAMESPACE+x} ] && return
  oc annotate ns "${NAMESPACE}" scheduler.alpha.kubernetes.io/defaultTolerations-
}

ocp_infra_label_control_as_infra(){
  echo "see https://docs.redhat.com/en/documentation/openshift_container_platform/4.8/html/machine_management/creating-infrastructure-machinesets#moving-resources-to-infrastructure-machinesets"

  oc label node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/infra=""

  # oc patch \
  #   scheduler cluster \
  #   --type=merge --patch '{"spec":{"defaultNodeSelector":"node-role.kubernetes.io/infra=\"\""}}'
}

ocp_infra_label_control_as_infra_remove(){
  oc label node -l node-role.kubernetes.io/control-plane node-role.kubernetes.io/infra-
}

ocp_infra_move_registry_to_control(){

cat <<YAML > /tmp/patch.yaml
spec:
  nodeSelector:
    node-role.kubernetes.io/infra: ""
  tolerations:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
    operator: Exists
  - effect: NoExecute
    key: node-role.kubernetes.io/master
    operator: Exists
YAML

 oc patch \
    configs.imageregistry.operator.openshift.io/cluster \
    --type=merge --patch-file /tmp/patch.yaml
}

ocp_infra_move_registry_from_control(){

cat <<YAML > /tmp/patch.yaml
spec:
  nodeSelector: {}
  tolerations: []
YAML

 oc patch \
    configs.imageregistry.operator.openshift.io/cluster \
    --type=merge --patch-file /tmp/patch.yaml
}

ocp_infra_move_router_to_control(){

cat <<YAML > /tmp/patch.yaml
spec:
  nodePlacement:
    nodeSelector:
      matchLabels:
        node-role.kubernetes.io/infra: ""
    tolerations:
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
      operator: Exists
    - effect: NoExecute
      key: node-role.kubernetes.io/master
      operator: Exists
YAML

  oc -n openshift-ingress-operator \
    patch \
    ingresscontroller default \
    --type=merge --patch-file /tmp/patch.yaml
}

ocp_infra_move_router_from_control(){

cat <<YAML > /tmp/patch.yaml
spec:
  nodePlacement:
    nodeSelector: {}
    tolerations: []
YAML

  oc -n openshift-ingress-operator \
    patch \
    ingresscontroller default \
    --type=merge --patch-file /tmp/patch.yaml
}

ocp_infra_move_monitoring_to_control(){

cat <<YAML > /tmp/patch.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-monitoring-config
  namespace: openshift-monitoring
data:
  config.yaml: |+
    alertmanagerMain:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusK8s:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    prometheusOperator:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    # grafana:
    #   nodeSelector:
    #     node-role.kubernetes.io/infra: ""
    k8sPrometheusAdapter:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    kubeStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    telemeterClient:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
    openshiftStateMetrics:
      nodeSelector:
        node-role.kubernetes.io/infra: ""
YAML

oc apply -f /tmp/patch.yaml

# cat <<YAML > /tmp/patch.yaml
# spec:
#   logStore:
#     elasticsearch:
#       nodeCount: 3
#       nodeSelector:
#         node-role.kubernetes.io/infra: ""
#       tolerations:
#       - effect: NoSchedule
#         key: node-role.kubernetes.io/master
#         operator: Exists
#       - effect: NoExecute
#         key: node-role.kubernetes.io/master
#         operator: Exists
#   visualization:
#     kibana:
#       nodeSelector:
#         node-role.kubernetes.io/infra: ""
#       tolerations:
#       - effect: NoSchedule
#         key: node-role.kubernetes.io/master
#         operator: Exists
#       - effect: NoExecute
#         key: node-role.kubernetes.io/master
#         operator: Exists
# YAML

#   oc -n openshift-logging \
#     patch \
#     clusterlogging instance \
#     --type=merge --patch-file /tmp/patch.yaml
}

ocp_infra_move_monitoring_from_control(){
  oc -n openshift-monitoring delete cm cluster-monitoring-config
}

ocp_infra_move_to_control(){
  ocp_infra_label_control_as_infra

  ocp_annotate_ns_tolerations_master openshift-terminal
  ocp_annotate_ns_tolerations_master openshift-operators
  ocp_annotate_ns_tolerations_master openshift-operator-lifecycle-manager
  ocp_annotate_ns_tolerations_master openshift-ingress-canary
  ocp_annotate_ns_tolerations_master openshift-monitoring

  ocp_infra_move_monitoring_to_control
  ocp_infra_move_registry_to_control
  ocp_infra_move_router_to_control
  ocp_infra_move_registry_to_control
}

ocp_infra_move_from_control(){
  ocp_infra_label_control_as_infra_remove

  ocp_annotate_ns_tolerations_master_remove openshift-terminal
  ocp_annotate_ns_tolerations_master_remove openshift-operators
  ocp_annotate_ns_tolerations_master_remove openshift-operator-lifecycle-manager
  ocp_annotate_ns_tolerations_master_remove openshift-ingress-canary
  ocp_annotate_ns_tolerations_master_remove openshift-monitoring
}
