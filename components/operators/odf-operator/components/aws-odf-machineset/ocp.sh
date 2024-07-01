#!/bin/bash
# shellcheck disable=SC2120

ocp_aws_cluster(){
  TARGET_NS=kube-system
  OBJ=secret/aws-creds
  echo "Checking if ${OBJ} exists in ${TARGET_NS} namespace"
  oc -n "${TARGET_NS}" get "${OBJ}" -o name > /dev/null 2>&1 || return 1
  echo "AWS cluster detected"
}

ocp_aws_clone_worker_machineset(){
  [ -z "${1}" ] && \
  echo "
    usage: ocp_aws_clone_worker_machineset < instance type, default g4dn.4xlarge > < machine set name >
  "

  INSTANCE_TYPE=${1:-g4dn.4xlarge}
  SHORT_NAME=${2:-${INSTANCE_TYPE%.*}}

  MACHINE_SET_NAME=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "${SHORT_NAME}" | head -n1)
  MACHINE_SET_WORKER=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)

  # check for an existing instance machine set
  if [ -n "${MACHINE_SET_NAME}" ]; then
    echo "Exists: machineset - ${MACHINE_SET_NAME}"
  else
    echo "Creating: machineset - ${SHORT_NAME}"
    oc -n openshift-machine-api \
      get "${MACHINE_SET_WORKER}" -o yaml | \
        sed '/machine/ s/-worker/-'"${INSTANCE_TYPE}"'/g
          /^  name:/ s/cluster-.*/'"${SHORT_NAME}"'/g
          /name/ s/-worker/-'"${SHORT_NAME}"'/g
          s/instanceType.*/instanceType: '"${INSTANCE_TYPE}"'/
          /cluster-api-autoscaler/d
          s/replicas.*/replicas: 0/' | \
      oc apply -f -
  fi

  # cosmetic pretty
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_NAME}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/'"${SHORT_NAME}"'":""}}}}}}'
}

ocp_aws_create_odf_machineset(){
  INSTANCE_TYPE=${1:-m6a.2xlarge}
  SHORT_NAME=${2:-odf-infra}

  ocp_aws_clone_worker_machineset "${INSTANCE_TYPE}" "${SHORT_NAME}"

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
