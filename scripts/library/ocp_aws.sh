#!/bin/bash

ocp_aws_ack_system_setup(){
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

ocp_aws_cluster(){
  TARGET_NS=kube-system
  OBJ=secret/aws-creds
  echo "Checking if ${OBJ} exists in ${TARGET_NS} namespace"
  oc -n "${TARGET_NS}" get "${OBJ}" -o name > /dev/null 2>&1 || return 1
  echo "AWS cluster detected"
}

ocp_aws_cluster_autoscaling(){
  oc apply -k https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/components/cluster-configs/autoscale/overlays/gpus

  ocp_aws_machineset_create_gpu g4dn.4xlarge
  ocp_machineset_create_autoscale 0 3

  # scale workers to 1
  WORKER_MS="$(oc -n openshift-machine-api get machineset -o name | grep worker | head -n1)"
  ocp_machineset_scale 1 "${WORKER_MS}"

  ocp_control_nodes_schedulable
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

ocp_aws_machineset_clone_worker(){
  INSTANCE_TYPE=${1:-g4dn.4xlarge}

  [ -z "${1}" ] && \
  echo "
    usage: ocp_aws_machineset_clone_worker < instance type, default ${INSTANCE_TYPE} > < machine set name >
  "

  ocp_aws_cluster || return

  MACHINE_SET_NAME=${2:-${INSTANCE_TYPE//./-}}
  MACHINE_SET_WORKER=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)

  # check for an existing instance machine set
  if oc -n openshift-machine-api get "${MACHINE_SET_NAME}" > /dev/null ; then
    echo "Exists: machineset - ${MACHINE_SET_NAME}"
  else
    echo "Creating: machineset - ${MACHINE_SET_NAME}"
    oc -n openshift-machine-api \
      get "${MACHINE_SET_WORKER}" -o yaml | \
        sed '/machine/ s/'"${MACHINE_SET_WORKER##*/}"'/'"${MACHINE_SET_NAME}"'/g
          /^  name:/ s/'"${MACHINE_SET_WORKER##*/}"'/'"${MACHINE_SET_NAME}"'/g
          /name/ s/'"${MACHINE_SET_WORKER##*/}"'/'"${MACHINE_SET_NAME}"'/g
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
  # oc -n openshift-machine-api \
  #   patch "${MACHINE_SET_NAME}" \
  #   --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/'"${SHORT_NAME}"'":""}}}}}}'
}

ocp_aws_machineset_create_gpu(){
  INSTANCE_TYPE=${1:-g4dn.4xlarge}

  # https://aws.amazon.com/ec2/instance-types/g4
  # single gpu: g4dn.{2,4,8,16}xlarge
  # multi gpu:  g4dn.12xlarge
  # practical:  g4ad.4xlarge
  # a100 (MIG): p4d.24xlarge
  # h100 (MIG): p5.48xlarge

  # https://aws.amazon.com/ec2/instance-types/dl1
  # 8 x gaudi:  dl1.24xlarge

  [ -z "${1}" ] && \
  echo "
    usage: ocp_aws_machineset_create_gpu < instance type, default ${INSTANCE_TYPE} >
  "

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

ocp_aws_machineset_create_metal(){
  # https://aws.amazon.com/ec2/instance-types/m5zn
  # m5.metal
  # m5n.metal

  INSTANCE_TYPE=${1:-m5n.metal}

  ocp_aws_machineset_clone_worker "${INSTANCE_TYPE}"

  MACHINE_SET_TYPE=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "${INSTANCE_TYPE%.*}" | head -n1)

  echo "Patching: ${MACHINE_SET_TYPE}"

  # cosmetic
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/metal":""}}}}}}'

  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"providerSpec":{"value":{"instanceType":"'"${INSTANCE_TYPE}"'"}}}}}}'
}

ocp_aws_machineset_create_odf(){
  INSTANCE_TYPE=${1:-m6a.2xlarge}
  SHORT_NAME=${2:-odf-infra}

  ocp_aws_machineset_clone_worker "${INSTANCE_TYPE}" "${SHORT_NAME}"

  MACHINE_SET_NAME=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "${SHORT_NAME}" | head -n1)

  echo "Patching: ${MACHINE_SET_NAME}"

cat << YAML > /tmp/patch.yaml
spec:
  replicas: 3
  template:
    spec:
      taints:
        - key: node.ocs.openshift.io/storage
          value: 'true'
          effect: NoSchedule
      metadata:
        labels:
          cluster.ocs.openshift.io/openshift-storage: ''
          node-role.kubernetes.io/infra: ''
      providerSpec:
        value:
          blockDevices:
            - ebs:
                encrypted: true
                iops: 0
                kmsKey:
                  arn: ''
                volumeSize: 100
                volumeType: gp3
            # - deviceName: /dev/xvdb
            #   ebs:
            #     encrypted: true
            #     iops: 0
            #     kmsKey:
            #       arn: ''
            #     volumeSize: 1000
            #     volumeType: gp3
YAML

  # patch storage
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_NAME}" \
    --type=merge --patch "$(cat /tmp/patch.yaml)"

}

ocp_aws_machineset_fix_storage(){
  MACHINE_SETS=${1:-$(oc -n openshift-machine-api get machineset -o name)}
  HD_SIZE=${2:-200}

  for machine_set in ${MACHINE_SETS}
  do
    echo "Patching aws storage for machineset: ${machine_set}"
    oc -n openshift-machine-api \
      get "${machine_set}" -o yaml | \
        sed 's/volumeSize: .*/volumeSize: '"${HD_SIZE}"'/
          s/volumeType: gp2/volumeType: gp3/' | \
      oc apply -f -
  done
}

