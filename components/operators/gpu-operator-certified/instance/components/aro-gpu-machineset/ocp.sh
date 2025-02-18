#!/bin/bash
# shellcheck disable=SC2120

# See https://github.com/redhat-na-ssa/demo-ai-gitops-catalog
# FUNCTIONS='
# ocp_aro_cluster
# ocp_aro_machineset_create_gpu
# ocp_aro_machineset_clone_worker
# ocp_aro_machineset_fix_storage
# ocp_machineset_create_autoscale
# ocp_machineset_taint_gpu
# '

# for function in ${FUNCTIONS}
# do
#   extract_function $function scripts/library/ocp*.sh >> tmp
#   echo >> tmp
# done

ocp_machineset_create_autoscale(){
  MACHINE_MIN=${1:-0}
  MACHINE_MAX=${2:-4}
  MACHINE_SETS=${3:-$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | sed 's@.*/@@' )}

  for machine_set in ${MACHINE_SETS}
  do
cat << YAML | oc apply -f -
apiVersion: "autoscaling.openshift.io/v1beta1"
kind: "MachineAutoscaler"
metadata:
  name: "${machine_set}"
  namespace: "openshift-machine-api"
spec:
  minReplicas: ${MACHINE_MIN}
  maxReplicas: ${MACHINE_MAX}
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: "${machine_set}"
YAML
  done
}

ocp_machineset_taint_gpu(){
  SHORT_NAME=${1:-g4dn}
  MACHINE_SET=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "${SHORT_NAME}" | head -n1)

  echo "Patching: ${MACHINE_SET}"

  # taint nodes for gpu-only workloads
  oc -n openshift-machine-api \
    patch "${MACHINE_SET}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"taints":[{"key":"nvidia.com/gpu","value":"","effect":"NoSchedule"}]}}}}'
}

ocp_aro_cluster(){
  TARGET_NS=kube-system
  OBJ=secret/azure-credentials
  echo "Checking if ${OBJ} exists in ${TARGET_NS} namespace"
  oc -n "${TARGET_NS}" get "${OBJ}" -o name > /dev/null 2>&1 || return 1
  echo "ARO cluster detected"
}

ocp_aro_machineset_create_gpu(){
  # https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/nv-family

  INSTANCE_TYPE=${1:-Standard_NC64as_T4_v3}
  SHORT_NAME=${2:-${INSTANCE_TYPE//_/-}}
  SHORT_NAME=${SHORT_NAME,,}

  ocp_aro_machineset_clone_worker "${INSTANCE_TYPE}"
  
  MACHINE_SET_TYPE=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "/${SHORT_NAME}" | head -n1)

  echo "Patching: ${MACHINE_SET_TYPE}"

  # cosmetic
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/gpu":""}}}}}}'

  # should use the default profile
  # oc -n openshift-machine-api \
  #   patch "${MACHINE_SET_TYPE}" \
  #   --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"nvidia.com/device-plugin.config":"no-time-sliced"}}}}}}'

  # should help auto provisioner
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}}}}'

  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}'

  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"providerSpec":{"value":{"vmSize":"'"${INSTANCE_TYPE}"'"}}}}}}'
}

ocp_aro_machineset_clone_worker(){
  [ -z "${1}" ] && \
  echo "
    usage: ocp_aro_machineset_clone_worker < instance type, default Standard_D4s_v3 > < machine set name >
  "

  INSTANCE_TYPE=${1:-Standard_D4s_v3}
  SHORT_NAME=${2:-${INSTANCE_TYPE//_/-}}
  SHORT_NAME=${SHORT_NAME,,}

  MACHINE_SET_NAME=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "/${SHORT_NAME}" | head -n1)
  MACHINE_SET_WORKER=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)

  # check for an existing instance machine set
  if [ -n "${MACHINE_SET_NAME}" ]; then
    echo "Exists: machineset - ${MACHINE_SET_NAME}"
  else
    echo "Creating: machineset - ${SHORT_NAME}"

    oc -n openshift-machine-api \
      get "${MACHINE_SET_WORKER}" -o yaml | \
        sed '/machine/ s/'"${MACHINE_SET_WORKER##*/}"'/'"${SHORT_NAME}"'/g
          /^  name:/ s/'"${MACHINE_SET_WORKER##*/}"'/'"${SHORT_NAME}"'/g
          /name/ s/'"${MACHINE_SET_WORKER##*/}"'/'"${SHORT_NAME}"'/g
          s/vmSize.*/vmSize: '"${INSTANCE_TYPE}"'/
          /cluster-api-autoscaler/d
          /uid:/d
          /generation:/d
          /resourceVersion:/d
          /creationTimestamp:/d
          s/replicas.*/replicas: 0/' | \
      oc apply -f -
    
    MACHINE_SET_NAME="machinesets.machine.openshift.io/${SHORT_NAME}"
  fi

  # cosmetic pretty
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_NAME}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/'"${SHORT_NAME}"'":""}}}}}}'
}




