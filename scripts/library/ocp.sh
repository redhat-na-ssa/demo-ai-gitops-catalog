#!/bin/bash

# https://mirror.openshift.com/pub/openshift-v4

ocp_check_login(){
  oc whoami || return 1
  oc cluster-info | head -n1
  echo
}

ocp_check_info(){
  echo "== OCP INFO =="
  ocp_check_login || return 1

  echo "NAMESPACE: $(oc project -q)"
  sleep "${SLEEP_SECONDS:-8}"
}

ocp_kubeadmin_create(){
  PASS=${1:-$(genpass 5 )-$(genpass 5 )-$(genpass 5 )-$(genpass 5 )}

  which htpasswd >/dev/null || return 1

  HTPASSWD=$(htpasswd -nbB -C10 null "${PASS}")
  HASH=${HTPASSWD##*:}

  echo "
  PASSWORD: ${PASS}
  HASH:     ${HASH}

  oc apply -f scratch/kubeadmin.yaml
  "

cat << YAML > scratch/kubeadmin.yaml
kind: Secret
apiVersion: v1
metadata:
  name: kubeadmin
  namespace: kube-system
stringData:
  kubeadmin: ${HASH}
  password: ${PASS}
type: Opaque
YAML
}

ocp_kubeadmin_remove(){
  FORCE=${1:-No}

  if [ "${FORCE}" = "YES" ]; then
    [ ! -e scratch/kubeadmin.yaml ] && \
      oc get secret kubeadmin -n kube-system -o yaml > scratch/kubeadmin.yaml || return 1
    oc delete secret kubeadmin -n kube-system
  else
    echo "${RED}WARNING: you must run - ocp_remove_kubeadmin YES${NC}"
    return
  fi
}

ocp_get_apps_domain(){
  oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}'
}

ocp_aws_cluster(){
  TARGET_NS=kube-system
  OBJ=secret/aws-creds
  echo "Checking if ${OBJ} exists in ${TARGET_NS} namespace"
  oc -n "${TARGET_NS}" get "${OBJ}" -o name > /dev/null 2>&1 || return 1
  echo "AWS cluster detected"
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

ocp_aws_setup_ack_system(){
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

ocp_aws_clone_worker_machineset(){
  [ -z "${1}" ] && \
  echo "
    usage: ocp_aws_clone_worker_machineset < instance type, default g4dn.4xlarge > < machine set name >
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

ocp_aws_create_metal_machineset(){
  # https://aws.amazon.com/ec2/instance-types/m5zn
  # m5.metal
  # m5n.metal

  INSTANCE_TYPE=${1:-m5n.metal}

  ocp_aws_clone_worker_machineset "${INSTANCE_TYPE}"

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

ocp_aws_create_gpu_machineset(){
  # https://aws.amazon.com/ec2/instance-types/g4
  # single gpu: g4dn.{2,4,8,16}xlarge
  # multi gpu:  g4dn.12xlarge
  # practical:  g4ad.4xlarge
  # a100 (MIG): p4d.24xlarge
  # h100 (MIG): p5.48xlarge

  # https://aws.amazon.com/ec2/instance-types/dl1
  # 8 x gaudi:  dl1.24xlarge

  INSTANCE_TYPE=${1:-g4dn.4xlarge}

  ocp_aws_clone_worker_machineset "${INSTANCE_TYPE}"

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

ocp_aws_taint_gpu_machineset(){
  INSTANCE_TYPE=${1:-g4dn.4xlarge}
  MACHINE_SET_TYPE=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep "${INSTANCE_TYPE%.*}" | head -n1)

  echo "Patching: ${MACHINE_SET_TYPE}"

  # taint nodes for gpu-only workloads
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_TYPE}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"taints":[{"key":"nvidia.com/gpu","value":"","effect":"NoSchedule"}]}}}}'
}

ocp_create_machineset_autoscale(){
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

ocp_aws_cluster_autoscaling(){
  oc apply -k https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/components/cluster-configs/autoscale/overlays/gpus

  ocp_aws_create_gpu_machineset g4dn.4xlarge
  ocp_create_machineset_autoscale 0 3

  # scale workers to 1
  WORKER_MS="$(oc -n openshift-machine-api get machineset -o name | grep worker | head -n1)"
  ocp_scale_machineset 1 "${WORKER_MS}"

  ocp_control_nodes_schedulable
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
  echo "see https://docs.openshift.com/container-platform/4.16/nodes/scheduling/nodes-scheduler-profiles.html"
  echo "OPTIONS: LowNodeUtilization (default), HighNodeUtilization, NoScoring"
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

ocp_release_info(){
  VERSION=${1:-stable-4.12}
  echo "VERSION: ${VERSION}"
  curl -sL "https://mirror.openshift.com/pub/openshift-v4/amd64/clients/ocp/${VERSION}/release.txt"
}

ocp_run_on_all_nodes(){
  case $1 in
    --confirm)
      shift

      COMMAND=${*:-uptime}
      ALL_NODES=$(oc get nodes --show-kind --no-headers|awk '/node/{print $1}')

      for node in ${ALL_NODES}
        do
          # wipefs -af /dev/nvme0n1
          # oc debug $node -- chroot /host  bash -c "$(cat -)"
          # shellcheck disable=SC2086
          oc debug "$node" -- chroot /host ${COMMAND}
      done
      ;;
   *)
      echo "-------------------------------------------------------------------"
      echo "WARNING. This runs as root on all nodes!"
      echo "You can DESTROY ALL DATA, without recovery, if used incorrectly!"
      echo "-------------------------------------------------------------------"
      echo "Usage:"
      echo "  ocp_run_on_all_nodes --confirm < command >"
  esac

}

ocp_upgrade_cluster(){
  OCP_VERSION="${1:-latest}"

  if [ "${OCP_VERSION}" = "latest" ]; then
    oc adm upgrade --to-latest=true
  else
    oc adm upgrade --to="${OCP_VERSION}"
  fi
}

ocp_ack_upgrade_4.13(){
  oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.12-kube-1.26-api-removals-in-4.13":"true"}}' --type=merge
}

ocp_gpu_taint_nodes(){
  oc adm taint node -l node-role.kubernetes.io/gpu nvidia.com/gpu=:NoSchedule --overwrite
  oc adm drain -l node-role.kubernetes.io/gpu --ignore-daemonsets --delete-emptydir-data
  oc adm uncordon -l node-role.kubernetes.io/gpu
}

ocp_gpu_untaint_nodes(){
  oc adm taint node -l node-role.kubernetes.io/gpu nvidia.com/gpu=:NoSchedule-
}

ocp_gpu_label_nodes_from_nfd(){
  oc label node -l nvidia.com/gpu.machine node-role.kubernetes.io/gpu=''
}

ocp_get_pull_secret(){
  oc -n openshift-config \
    get secret/pull-secret \
    --template='{{index .data ".dockerconfigjson" | base64decode}}'
}

ocp_mirror_set_pull_secret(){
  export DOCKER_CONFIG="${GIT_ROOT}/scratch"

  [ -e "${DOCKER_CONFIG}/config.json" ] && return

  oc -n openshift-config \
    extract secret/pull-secret \
    --to=- | tee "${GIT_ROOT}/scratch/pull-secret" > "${DOCKER_CONFIG}/config.json"

  # cat scratch/pull-secret | jq .
}

ocp_mirror_dry_run(){
  DOC_URL=https://docs.openshift.com/container-platform/4.14/installing/disconnected_install/installing-mirroring-installation-images.html

  echo "See: ${DOC_URL}"

  # TIME_STAMP=$(date +%s)
  TIME_STAMP=$(date +%Y.%m.%d)

  LOCAL_SECRET_JSON=${1:-scratch/pull-secret}
  PRODUCT_REPO=${2:-openshift-release-dev}
  RELEASE_NAME=${3:-ocp-release}
  OCP_RELEASE=${4:-4.14.20}
  ARCHITECTURE=${5:-x86_64}

  LOCAL_REGISTRY=${6:-localhost:5000}
  LOCAL_REPOSITORY=${7:-ocp4/openshift4}

  REMOVABLE_MEDIA_PATH=scratch/mirror_media

  [ -d "${REMOVABLE_MEDIA_PATH}" ] || mkdir -p "${REMOVABLE_MEDIA_PATH}"

  [ -e "${DOCKER_CONFIG}/config.json" ] || ocp_mirror_set_pull_secret

  echo oc adm release mirror \
    -a "${LOCAL_SECRET_JSON}"  \
    --from="quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}" \
    --to="${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}" \
    --to-release-image="${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}" \
    --dry-run | \
      tee "${REMOVABLE_MEDIA_PATH}/cmd.${TIME_STAMP}" | \
      bash 2>&1 | tee "${REMOVABLE_MEDIA_PATH}/dryrun.${TIME_STAMP}"

  # sed '0,/use the following/d ; /^$/d' scratch/dryrun

  echo "
  SAVED TO: ${REMOVABLE_MEDIA_PATH}/{cmd,dryrun}.${TIME_STAMP}
  "
}

ocp_mirror_operator_catalog_list(){
  VERSION=${1:-4.14}
  INDEX=${2:-registry.redhat.io/redhat/redhat-operator-index:v${VERSION}}

  which oc-mirror >/dev/null 1>&2 || return

  [ -e "${DOCKER_CONFIG}/config.json" ] || ocp_mirror_set_pull_secret

  echo "Please be patient. This process is slow..." 1>&2
  echo "oc mirror list operators --catalog ${INDEX}" 1>&2
  echo "INDEX: ${INDEX}"

  oc mirror list operators --catalog "${INDEX}"

  echo ""
}

ocp_mirror_operator_catalog_list_all(){
  VERSION=4.12
  # redhat-operators
  INDEX_LIST="registry.redhat.io/redhat/redhat-operator-index:v${VERSION}"
  # certified-operators
  INDEX_LIST="${INDEX_LIST} registry.redhat.io/redhat/certified-operator-index:v${VERSION}"
  # redhat-marketplace
  INDEX_LIST="${INDEX_LIST} registry.redhat.io/redhat/redhat-marketplace-index:v${VERSION}"
  # community-operators
  INDEX_LIST="${INDEX_LIST} registry.redhat.io/redhat/community-operator-index:v${VERSION}"

  for index in ${INDEX_LIST}
  do
    ocp_mirror_operator_list "${index}"
  done
}

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

ocp_aro_clone_machineset(){
  [ -z "${1}" ] && \
  echo "
    usage: ocp_aro_clone_machineset < instance type, default Standard_NC64as_T4_v3 >
  "

  INSTANCE_TYPE=${1:-Standard_NC64as_T4_v3}
  INSTANCE_NAME=$(echo "${INSTANCE_TYPE,,}" | tr '_' '-')
  MACHINE_SET=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)

  # check for an existing instance machine set
  if oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep -q "${INSTANCE_NAME}"; then
    echo "Exists: machineset - ${INSTANCE_TYPE}"
  else
    echo "Creating: machineset - ${INSTANCE_NAME}"
    oc -n openshift-machine-api \
      get "${MACHINE_SET}" -o yaml | \
        sed '/machine/ s/-worker/-'"${INSTANCE_TYPE}"'/g
          /name/ s/-worker/-'"${INSTANCE_NAME}"'/g
          s/vmSize.*/vmSize: '"${INSTANCE_TYPE}"'/
          s/replicas.*/replicas: 0/' | \
      oc apply -f -
  fi
}

ocp_clean_install_pods(){
  oc delete pod \
    -A \
    -l app=installer
}

ocp_get_kubeconfigs(){
  # https://rcarrata.com/openshift/regenerate-kubeconfig/
  # https://gist.githubusercontent.com/rcarrata/016da295c1421cccbfbd66ed9a7922bc/raw/855486c363734892988cdf1b5d0d26ece5e0960a/regenerate-kubeconfig.sh
  # https://access.redhat.com/solutions/6054981
  # https://access.redhat.com/solutions/5286371
  # https://access.redhat.com/solutions/6112601

  oc -n openshift-kube-apiserver extract secret/node-kubeconfigs
}

ocp_auth_create_group(){
  OCP_GROUP=${1:-${DEFAULT_OCP_GROUP}}

  oc get group "${OCP_GROUP}" > /dev/null 2>&1 && return

echo "
apiVersion: user.openshift.io/v1
kind: Group
metadata:
  name: ${OCP_GROUP}
" | oc apply -f-

}

ocp_auth_add_to_group(){
  USER=${1:-admin}
  OCP_GROUP=${2:-${DEFAULT_OCP_GROUP}}

  ocp_auth_create_group "${OCP_GROUP}"

  oc adm groups add-users \
  "${OCP_GROUP}" "${USER}"
}

ocp_auth_setup_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}
  OCP_GROUP=${3:-${DEFAULT_OCP_GROUP}}

  htpasswd_add_user "${USER}" "${PASS}"
  ocp_auth_add_to_group "${USER}" "${OCP_GROUP}"

  echo "
    run: htpasswd_ocp_set_file
  "
}
