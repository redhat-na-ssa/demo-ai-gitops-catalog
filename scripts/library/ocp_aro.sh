#!/bin/bash

ocp_aro_cluster(){
  TARGET_NS=kube-system
  OBJ=secret/azure-credentials
  echo "Checking if ${OBJ} exists in ${TARGET_NS} namespace"
  oc -n "${TARGET_NS}" get "${OBJ}" -o name > /dev/null 2>&1 || return 1
  echo "ARO cluster detected"
}

ocp_aro_get_key(){
  # get az creds
  ocp_aro_cluster || return
  AZ_TENANT_ID=redhat0.onmicrosoft.com

  AZ_CLIENT_ID=$(oc -n kube-system extract secret/azure-credentials --keys=azure_client_id --to=-)
  AZ_CLIENT_SECRET=$(oc -n kube-system extract secret/azure-credentials --keys=azure_client_secret --to=-)
  AZ_DEFAULT_REGION=$(oc -n kube-system extract secret/azure-credentials --keys=azure_region --to=-)
  AZ_DEFAULT_RG=$(oc -n kube-system extract secret/azure-credentials --keys=azure_resourcegroup --to=-)
  AZ_SUB_ID=$(oc -n kube-system extract secret/azure-credentials --keys=azure_subscription_id --to=-)
  AZ_TENANT_ID=$(oc -n kube-system extract secret/azure-credentials --keys=azure_tenant_id --to=-)

  export AZ_CLIENT_ID
  export AZ_CLIENT_SECRET
  export AZ_DEFAULT_REGION
  export AZ_DEFAULT_RG
  export AZ_SUB_ID
  export AZ_TENANT_ID

  echo "AZ_DEFAULT_REGION: ${AZ_DEFAULT_REGION}"

  which az || return 0

  az login --service-principal \
    -u "${AZ_CLIENT_ID}" \
    -p "${AZ_CLIENT_SECRET}" \
    --tenant "${AZ_TENANT_ID}"
}

ocp_aro_machineset_clone_worker(){
  [ -z "${1}" ] && \
  echo "
    usage: ocp_aro_machineset_clone_worker < instance type, default Standard_D4s_v3 > < machine set name >
  "

  INSTANCE_TYPE=${1:-Standard_D4s_v3}
  SHORT_NAME=${2:-${INSTANCE_TYPE//_/-}}

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

ocp_aro_machineset_create_gpu(){
  # https://learn.microsoft.com/en-us/azure/virtual-machines/sizes/gpu-accelerated/nv-family

  INSTANCE_TYPE=${1:-Standard_NC64as_T4_v3}
  INSTANCE_TYPE=${1:-Standard_NC64as_T4_v3}

  ocp_aro_machineset_clone_worker "${INSTANCE_TYPE}"

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
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}}}}'

  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"metadata":{"labels":{"cluster-api/accelerator":"nvidia-gpu"}}}'

  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"providerSpec":{"value":{"instanceType":"'"${INSTANCE_TYPE}"'"}}}}}}'
}
