#!/bin/bash

ocp_check_login(){
  oc whoami || return 1
  oc cluster-info | head -n1
  echo
}

ocp_check_info(){
  echo "OCP INFO:"
  ocp_check_login || return 1

  echo "NAMESPACE: $(oc project -q)"
  sleep "${SLEEP_SECONDS:-8}"
}

ocp_aws_cluster(){
  oc -n kube-system get secret/aws-creds -o name > /dev/null 2>&1 || return 1
}

ocp_aws_get_key(){
  # get aws creds
  ocp_aws_cluster || return 1
  
  AWS_ACCESS_KEY_ID=$(oc -n kube-system extract secret/aws-creds --keys=aws_access_key_id --to=-)
  AWS_SECRET_ACCESS_KEY=$(oc -n kube-system extract secret/aws-creds --keys=aws_secret_access_key --to=-)
  AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-2}

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION

  echo "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"
}

aws_setup_ack_system(){
  NAMESPACE=ack-system

  ocp_aws_get_key

  setup_namespace ${NAMESPACE}

  oc apply -k "${GIT_ROOT}"/components/operators/${NAMESPACE}/aggregate/popular

  for type in ec2 ecr iam lambda route53 s3 sagemaker
  do
    
    oc apply -k "${GIT_ROOT}"/components/operators/ack-${type}-controller/operator/overlays/alpha

    if oc -n "${NAMESPACE}" get secret "${type}-user-secrets" -o name; then
      echo "Found: ${type}-user-secrets - not replacing"
      continue
    fi

    < "${GIT_ROOT}"/components/operators/ack-${type}-controller/operator/overlays/alpha/user-secrets-secret.yaml \
      sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
      oc -n ${NAMESPACE} apply -f -
  done
}

ocp_aws_cluster_autoscaling(){
  oc apply -k "${GIT_ROOT}"/components/configs/autoscale/overlays/gpus

  ocp_aws_create_gpu_machineset g4dn.4xlarge
  ocp_create_machineset_autoscale 0 3

  ocp_control_nodes_schedulable

  # scale workers to 1
  WORKER_MS="$(oc -n openshift-machine-api get machineset -o name | grep worker)"
  ocp_scale_machineset 1 "${WORKER_MS}"
}

ocp_aws_create_metal_machineset(){
  # https://aws.amazon.com/ec2/instance-types/m5zn
  # m5.metal
  # m5n.metal
  INSTANCE_TYPE=${1:-m5zn.metal}
  MACHINE_SET=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)

  # check for an existing metal machine set
  if oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep metal; then
    echo "Exists: METAL machineset"
  else
    echo "Creating: METAL machineset"
    oc -n openshift-machine-api get "${MACHINE_SET}" -o yaml | \
      sed '/machine/ s/-worker/-metal/g
        /name/ s/-worker/-metal/g
        s/instanceType.*/instanceType: '"${INSTANCE_TYPE}"'/
        s/replicas.*/replicas: 0/' | \
      oc apply -f -
  fi

  MACHINE_SET_METAL=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep metal | head -n1)

  echo "Patching: Metal machineset"

  # cosmetic
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_METAL}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/metal":""}}}}}}'

  oc -n openshift-machine-api \
    patch "${MACHINE_SET_METAL}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"providerSpec":{"value":{"instanceType":"'"${INSTANCE_TYPE}"'"}}}}}}'
}

ocp_aws_create_gpu_machineset(){
  # https://aws.amazon.com/ec2/instance-types/g4
  # single gpu: g4dn.{2,4,8,16}xlarge
  # multi gpu: g4dn.12xlarge
  # cheapest: g4ad.4xlarge
  # a100 (MIG): p4d.24xlarge
  # h100 (MIG): p5.48xlarge
  INSTANCE_TYPE=${1:-g4dn.4xlarge}
  MACHINE_SET=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)

  # check for an existing gpu machine set
  if oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep gpu; then
    echo "Exists: GPU machineset"
  else
    echo "Creating: GPU machineset"
    oc -n openshift-machine-api get "${MACHINE_SET}" -o yaml | \
      sed '/machine/ s/-worker/-gpu/g
        /name/ s/-worker/-gpu/g
        s/instanceType.*/instanceType: '"${INSTANCE_TYPE}"'/
        s/replicas.*/replicas: 0/' | \
      oc apply -f -
  fi

  MACHINE_SET_GPU=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep gpu | head -n1)

  echo "Patching: GPU machineset"

  # cosmetic
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/gpu":""}}}}}}'

  # taint nodes for gpu-only workloads
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"taints":[{"key":nvidia-gpu-only","value":"","effect":"NoSchedule"}]}}}}'
  
  # should use the default profile
  # oc -n openshift-machine-api \
  #   patch "${MACHINE_SET_GPU}" \
  #   --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"nvidia.com/device-plugin.config":"no-time-sliced"}}}}}}'

  # should help auto provisioner
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}}}}'
  
    oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
    --type=merge --patch '{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}'
  
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"providerSpec":{"value":{"instanceType":"'"${INSTANCE_TYPE}"'"}}}}}}'
}

ocp_create_machineset_autoscale(){
  MACHINE_MIN=${1:-0}
  MACHINE_MAX=${2:-4}
  MACHINE_SETS=${3:-$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | sed 's@.*/@@' )}

  for set in ${MACHINE_SETS}
  do
cat << YAML | oc apply -f -
apiVersion: "autoscaling.openshift.io/v1beta1"
kind: "MachineAutoscaler"
metadata:
  name: "${set}"
  namespace: "openshift-machine-api"
spec:
  minReplicas: ${MACHINE_MIN}
  maxReplicas: ${MACHINE_MAX}
  scaleTargetRef:
    apiVersion: machine.openshift.io/v1beta1
    kind: MachineSet
    name: "${set}"
YAML
  done
}

ocp_scale_machineset(){
  REPLICAS=${1:-1}
  MACHINE_SETS=${2:-$(oc -n openshift-machine-api get machineset -o name)}

  # scale workers
  echo "${MACHINE_SETS}" | \
    xargs \
      oc -n openshift-machine-api \
      scale --replicas="${REPLICAS}"
}

ocp_control_nodes_not_schedulable(){
  oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": false}}'
}

ocp_control_nodes_schedulable(){
  oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": true}}'
}

ocp_set_scheduler_profile(){
  SCHED_PROFILE=${1:-LowNodeUtilization}

  # LowNodeUtilization, HighNodeUtilization, NoScoring
  echo "see https://docs.openshift.com/container-platform/4.11/nodes/scheduling/nodes-scheduler-profiles.html"
  echo "OPTIONS: LowNodeUtilization, HighNodeUtilization, NoScoring"
  echo "SCHED_PROFILE: ${SCHED_PROFILE}"

  oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"profile": "'"${SCHED_PROFILE}"'"}}' 
}

# save money in aws
ocp_save_money(){

  # run work on masters
  ocp_control_nodes_schedulable

  # scale to zero
  ocp_scale_machineset 0

  # place as many pods on as few nodes as possible
  ocp_set_scheduler_profile HighNodeUtilization
}

ocp_expose_image_registry(){
  oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"defaultRoute":true}}'

  # remove 'default-route-openshift-image-' from route
  HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
  SHORTER_HOST=$(echo "${HOST}" | sed '/host/ s/default-route-openshift-image-//')
  oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"host": "'"${SHORTER_HOST}"'"}}'

  echo "OCP image registry is available at: ${SHORTER_HOST}"
}

ocp_remove_kubeadmin(){
  FORCE=${1:-No}

  if [ "${FORCE}" = "YES" ]; then
    [ ! -e scratch/kubeadmin.yaml ] && \
      oc get secret kubeadmin -n kube-system -o yaml > scratch/kubeadmin.yaml || return 1
    oc delete secret kubeadmin -n kube-system
  else
    echo "WARNING: you must run ocp_remove_kubeadmin YES"
    return 1
  fi
}

ocp_release_info(){
  VERSION=${1:-stable-4.12}
  echo "VERSION: ${VERSION}"
  curl -sL "https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/${VERSION}/release.txt"
}

ocp_upgrade_cluster(){
  OCP_VERSION="${1:-latest}"

  if [ "${OCP_VERSION}" = "latest" ]; then
    oc adm upgrade --to-latest=true
  else
    oc adm upgrade --to="${OCP_VERSION}"
  fi
}

ocp_gpu_taint_nodes(){
  oc adm taint node -l node-role.kubernetes.io/gpu nvidia-gpu-only=:NoSchedule --overwrite
  oc adm drain -l node-role.kubernetes.io/gpu --ignore-daemonsets --delete-emptydir-data
  oc adm uncordon -l node-role.kubernetes.io/gpu
}

ocp_gpu_untaint_nodes(){
  oc adm taint node -l node-role.kubernetes.io/gpu nvidia-gpu-only=:NoSchedule-
}

ocp_gpu_label_nodes_from_nfd(){
  oc label node -l nvidia.com/gpu.machine node-role.kubernetes.io/gpu=''
}
