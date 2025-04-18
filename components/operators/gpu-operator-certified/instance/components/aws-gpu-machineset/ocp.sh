#!/bin/bash
# shellcheck disable=SC2120

# See https://github.com/redhat-na-ssa/demo-ai-gitops-catalog
# FUNCTIONS='
# ocp_aws_cluster
# ocp_aws_machineset_create_gpu
# ocp_aws_machineset_clone_worker
# ocp_aws_machineset_fix_storage
# ocp_machineset_create_autoscale
# ocp_machineset_taint_gpu
# '

# for function in ${FUNCTIONS}
# do
#   extract_function $function scripts/library/ocp*.sh >> tmp
#   echo >> tmp
# done

ocp_aws_cluster(){
  TARGET_NS=kube-system
  OBJ=secret/aws-creds
  echo "Checking if ${OBJ} exists in ${TARGET_NS} namespace"
  oc -n "${TARGET_NS}" get "${OBJ}" -o name > /dev/null 2>&1 || return 1
  echo "AWS cluster detected"
}

ocp_aws_machineset_create_gpu(){
  # https://aws.amazon.com/ec2/instance-types/g4
  # single gpu: g4dn.{2,4,8,16}xlarge
  # multi gpu:  g4dn.12xlarge
  # practical:  g4ad.4xlarge
  # a100 (MIG): p4d.24xlarge
  # h100 (MIG): p5.48xlarge

  # https://aws.amazon.com/ec2/instance-types/dl1
  # 8 x gaudi:  dl1.24xlarge

  INSTANCE_TYPE=${1:-g4dn.4xlarge}

  ocp_aws_machineset_clone_worker "${INSTANCE_TYPE}"

  MACHINE_SET_TYPE=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "${INSTANCE_TYPE%.*}" | head -n1)

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
  # oc -n openshift-machine-api \
  #   patch "${MACHINE_SET_TYPE}" \
  #   --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}}}}'

  # oc -n openshift-machine-api \
  #   patch "${MACHINE_SET_TYPE}" \
  #   --type=merge --patch '{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}'

  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"providerSpec":{"value":{"instanceType":"'"${INSTANCE_TYPE}"'"}}}}}}'

#  # fix storage

# cat << YAML > /tmp/patch.yaml
# spec:
#   template:
#     spec:
#       providerSpec:
#         value:
#           blockDevices:
#             - ebs:
#                 volumeSize: 120
#                 volumeType: gp3
# YAML

#   oc -n openshift-machine-api \
#     patch "${MACHINE_SET_TYPE}" \
#     --type=merge --patch "$(cat /tmp/patch.yaml)"
}

ocp_aws_machineset_clone_worker(){
  [ -z "${1}" ] && \
  echo "
    usage: ocp_aws_machineset_clone_worker < instance type, default g4dn.4xlarge > < machine set name >
  "

  INSTANCE_TYPE=${1:-g4dn.4xlarge}
  SHORT_NAME=${2:-${INSTANCE_TYPE/./-}}

  MACHINE_SET_NAME=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "${SHORT_NAME}" | head -n1)
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
          s/instanceType.*/instanceType: '"${INSTANCE_TYPE}"'/
          /cluster-api-autoscaler/d
          /uid:/d
          /generation:/d
          /resourceVersion:/d
          /creationTimestamp:/d
          s/replicas.*/replicas: 0/' | \
      oc apply -f -
  fi

  # fix aws storage
  ocp_aws_machineset_fix_storage "${MACHINE_SET_NAME}"

  # cosmetic pretty
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_NAME}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/'"${SHORT_NAME}"'":""}}}}}}'
}

ocp_aws_machineset_fix_storage(){
  MACHINE_SETS=${1:-$(oc -n openshift-machine-api get machineset -o name)}
  HD_SIZE=${2:-200}

  for machine_set in ${MACHINE_SETS}
  do
    echo "Patching aws storage for machineset: ${machine_set}"
    oc -n openshift-machine-api \
      get "${machine_set}" -o yaml | \
        sed 's/volumeSize: 100/volumeSize: '"${HD_SIZE}"'/
          s/volumeType: gp2/volumeType: gp3/' | \
      oc apply -f -
  done
}

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
