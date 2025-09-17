#!/bin/bash
  
ocp_nvidia_console_plugin_activate(){
  if oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}" >/dev/null; then
    oc patch consoles.operator.openshift.io cluster --patch '{ "spec": { "plugins": ["console-plugin-nvidia-gpu"] } }' --type=merge
  else
    oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}" | grep -q console-plugin-nvidia-gpu || \
      oc patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json
  fi

  oc patch clusterpolicies.nvidia.com gpu-cluster-policy --patch '{ "spec": { "dcgmExporter": { "config": { "name": "console-plugin-nvidia-gpu" } } } }' --type=merge
  oc -n nvidia-gpu-operator get deploy -l app.kubernetes.io/name=console-plugin-nvidia-gpu
}

ocp_nvidia_console_plugin_dump_helm_install(){
  # alternative: if no helm
  OUTPUT_PATH=components/operators/gpu-operator-certified/operator/components/console-plugin
  DUMP_PATH="${GIT_ROOT}/scratch/console-plugin-nvidia-gpu/console-plugin-nvidia-gpu/templates"

  [ -d "${OUTPUT_PATH}" ] || mkdir -p "${OUTPUT_PATH}"
  rm -rf "${GIT_ROOT}/scratch/console-plugin-nvidia-gpu"

  which helm || return 1
  helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu || true
  helm repo update > /dev/null 2>&1

  # rm -rf "${OUTPUT_PATH}/console-plugin-nvidia-gpu"
  helm template \
    console-plugin-nvidia-gpu \
    --repo https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu \
    -n nvidia-gpu-operator \
    --output-dir "${GIT_ROOT}/scratch" \
    --release-name console-plugin-nvidia-gpu

  mv "${DUMP_PATH}/"* "${OUTPUT_PATH}"
  rm -rf "${OUTPUT_PATH}/tests"

  sed -i '
    /^  name: console-plugin-nvidia-gpu/a \  namespace: nvidia-gpu-operator
    ' "${OUTPUT_PATH}/"*
  
}

ocp_nvidia_console_plugin_install(){
  GIT_URL=https://github.com/redhat-na-ssa/demo-ai-gitops-catalog

  if which helm; then
    helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu || true
    helm repo update > /dev/null 2>&1
    helm upgrade --install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu || true
  else
    oc apply -k "${GIT_URL}/components/operators/gpu-operator-certified/operator/components/console-plugin"
  fi
}

ocp_nvidia_dashboard_monitor_setup(){
  curl -sLfO https://github.com/NVIDIA/dcgm-exporter/raw/main/grafana/dcgm-exporter-dashboard.json
  oc -n openshift-config-managed create configmap nvidia-dcgm-exporter-dashboard --from-file=dcgm-exporter-dashboard.json || true
  oc -n openshift-config-managed label configmap nvidia-dcgm-exporter-dashboard "console.openshift.io/dashboard=true" --overwrite
  oc -n openshift-config-managed label configmap nvidia-dcgm-exporter-dashboard "console.openshift.io/odc-dashboard=true" --overwrite
  oc -n openshift-config-managed get cm nvidia-dcgm-exporter-dashboard --show-labels
  rm dcgm-exporter-dashboard.json
}

ocp_nvidia_label_node_device_plugin_config(){
  DEVICE_CONFIG=${1:-time-sliced-2}

  echo "DEVICE_CONFIG: ${DEVICE_CONFIG}"

  oc label node -l nvidia.com/gpu.machine \
    nvidia.com/device-plugin.config="${DEVICE_CONFIG}"
}

ocp_nvidia_label_node_gpu(){
  oc label node -l nvidia.com/gpu.machine node-role.kubernetes.io/gpu=''
}

ocp_nvidia_mig_config_setup(){
  MIG_MODE=${1:-single}
  MIG_CONFIG=${2:-all-1g.5gb}
  INSTANCE_TYPE=p4d.24xlarge

  ocp_aws_machineset_create_gpu "${INSTANCE_TYPE}" 

  oc apply -k "${GIT_ROOT}"/components/operators/gpu-operator-certified/instance/overlays/mig-"${MIG_MODE}"

  MACHINE_SET_TYPE=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "${INSTANCE_TYPE%.*}" | head -n1)

  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"nvidia.com/mig.config":"'"${MIG_CONFIG}"'"}}}}}}'

}

ocp_nvidia_setup_console_plugin(){
  ocp_nvidia_console_plugin_install || return
  ocp_nvidia_console_plugin_activate || return
}

ocp_nvidia_taint_gpu_nodes(){
  oc adm taint node -l node-role.kubernetes.io/gpu nvidia.com/gpu=:NoSchedule --overwrite
  oc adm drain -l node-role.kubernetes.io/gpu --ignore-daemonsets --delete-emptydir-data
  oc adm uncordon -l node-role.kubernetes.io/gpu
}

ocp_nvidia_untaint_gpu_nodes(){
  oc adm taint node -l node-role.kubernetes.io/gpu nvidia.com/gpu=:NoSchedule-
}

