#!/bin/bash

# https://mirror.openshift.com/pub/openshift-v4

ocp_add_admin_user(){
  HT_USERNAME=${1:-admin}
  HT_PASSWORD=${2:-$(genpass)}

  htpasswd_ocp_get_file
  htpasswd_add_user "${HT_USERNAME}" "${HT_PASSWORD}"
  htpasswd_ocp_set_file
  htpasswd_validate_user "${HT_USERNAME}" "${HT_PASSWORD}"
}

ocp_auth_add_to_group(){
  USER=${1:-admin}
  OCP_GROUP=${2:-${DEFAULT_OCP_GROUP}}

  ocp_auth_create_group "${OCP_GROUP}"

  oc adm groups add-users \
  "${OCP_GROUP}" "${USER}"
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

ocp_check_info(){
  echo "== OCP INFO =="
  ocp_check_login || return 1

  echo "NAMESPACE: $(oc project -q)"
  sleep "${SLEEP_SECONDS:-8}"
}

ocp_check_login(){
  oc whoami || return 1
  oc cluster-info | head -n1
  echo
}

ocp_clean_install_pods(){
  oc delete pod \
    -A \
    -l app=installer
}

ocp_control_nodes_not_schedulable(){
  oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": false}}'
}

ocp_control_nodes_schedulable(){
  oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": true}}'
}

ocp_expose_image_registry(){
  oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"defaultRoute":true}}'

  # remove 'default-route-openshift-image-' from route
  HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
  SHORTER_HOST=$(echo "${HOST}" | sed '/host/ s/default-route-openshift-image-//')
  oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"host": "'"${SHORTER_HOST}"'"}}'

  echo "OCP image registry is available at: ${SHORTER_HOST}"
}

ocp_fix_duplicate_operator_groups(){
  for ns in $(oc get og -A | awk '{print $1}' | uniq -d)
  do
    oc -n "${ns}" \
      get og -o name | \
        tail -n+2 | \
        xargs oc -n "${ns}" delete
    
    # oc -n "${ns}" \
    #   delete pod --all
  done
}

ocp_get_apps_domain(){
  oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}'
}

ocp_get_domain(){
  OCP_APPS_DOMAIN=$(ocp_get_apps_domain)
  echo "${OCP_APPS_DOMAIN#apps.}"
}

ocp_get_kubeconfigs(){
  # https://rcarrata.com/openshift/regenerate-kubeconfig/
  # https://gist.githubusercontent.com/rcarrata/016da295c1421cccbfbd66ed9a7922bc/raw/855486c363734892988cdf1b5d0d26ece5e0960a/regenerate-kubeconfig.sh
  # https://access.redhat.com/solutions/6054981
  # https://access.redhat.com/solutions/5286371
  # https://access.redhat.com/solutions/6112601

  oc -n openshift-kube-apiserver extract secret/node-kubeconfigs
}

ocp_get_pull_secret(){
  oc -n openshift-config \
    get secret/pull-secret \
    --template='{{index .data ".dockerconfigjson" | base64decode}}'
}

ocp_gpu_pretty_label(){
  oc label node -l nvidia.com/gpu.machine node-role.kubernetes.io/gpu=''
}

ocp_gpu_taint_nodes(){
  oc adm taint node -l node-role.kubernetes.io/gpu nvidia.com/gpu=:NoSchedule --overwrite
  oc adm drain -l node-role.kubernetes.io/gpu --ignore-daemonsets --delete-emptydir-data
  oc adm uncordon -l node-role.kubernetes.io/gpu
}

ocp_gpu_untaint_nodes(){
  oc adm taint node -l node-role.kubernetes.io/gpu nvidia.com/gpu=:NoSchedule-
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
    echo -e "${RED}
    WARNING: you must run - ocp_remove_kubeadmin YES

    WARNING: you will lose access to your cluster if you do not
      have a way to login to your cluster without kubeadmin. 
      
      Examples:
        - An identity provider with a cluster-admin user setup
        - A kubeconfig file
    ${NC}"
    return
  fi
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

ocp_machineset_patch_accelerator(){
  MACHINE_SET_NAME=${1:-gpu}
  LABEL=${2:-nvidia-gpu}

  oc -n openshift-machine-api \
    patch machineset "${MACHINE_SET_NAME}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"cluster-api/accelerator":"'"${LABEL}"'"}}}}}}'
  
  oc -n openshift-machine-api \
    patch machineset "${MACHINE_SET_NAME}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/gpu":""}}}}}}'
}

ocp_machineset_scale(){
  REPLICAS=${1:-1}
  MACHINE_SETS=${2:-$(oc -n openshift-machine-api get machineset -o name)}

  # scale workers
  echo "${MACHINE_SETS}" | \
    xargs \
      oc -n openshift-machine-api \
      scale --replicas="${REPLICAS}"
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

ocp_save_money(){

  # run work on masters
  ocp_control_nodes_schedulable

  # scale to zero
  ocp_machineset_scale 0

  # place as many pods on as few nodes as possible
  ocp_scheduler_set_profile HighNodeUtilization
}

ocp_scheduler_set_profile(){
  SCHED_PROFILE=${1:-LowNodeUtilization}

  # LowNodeUtilization, HighNodeUtilization, NoScoring
  echo "see https://docs.openshift.com/container-platform/4.16/nodes/scheduling/nodes-scheduler-profiles.html"
  echo "OPTIONS: LowNodeUtilization (default), HighNodeUtilization, NoScoring"
  echo "SCHED_PROFILE: ${SCHED_PROFILE}"

  oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"profile": "'"${SCHED_PROFILE}"'"}}'
}

ocp_setup_namespace(){
  NAMESPACE=${1}

  oc new-project "${NAMESPACE}" 2>/dev/null || \
    oc project "${NAMESPACE}"
}

ocp_update_pull_secret(){
  echo "see https://access.redhat.com/solutions/4902871"

  PULL_SECRET_FILE=${1:-${GIT_ROOT}/scratch/pull-secret}

  oc extract secret/pull-secret \
    -n openshift-config \
    --keys .dockerconfigjson \
    --to=- > "${PULL_SECRET_FILE}"
  
  oc get secret/pull-secret \
    -n openshift-config \
    -o yaml > "${PULL_SECRET_FILE}.yaml"

  [ -e "${PULL_SECRET_FILE}" ] || return 0

  if oc get secret/pull-secret -n openshift-config -o name; then
    oc set data secret/pull-secret \
      -n openshift-config \
      --from-file=.dockerconfigjson="${PULL_SECRET_FILE}"
  else
    oc create secret generic pull-secret \
      -n openshift-config \
      --type=kubernetes.io/dockerconfigjson \
      --from-file=.dockerconfigjson="${PULL_SECRET_FILE}"
  fi  
}

ocp_upgrade_ack_4.13(){
  oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.12-kube-1.26-api-removals-in-4.13":"true"}}' --type=merge
}

ocp_upgrade_ack_4.19(){
  oc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.18-kube-1.32-api-removals-in-4.19":"true"}}' --type=merge
}

ocp_upgrade_cluster(){
  OCP_VERSION="${1:-latest}"

  if [ "${OCP_VERSION}" = "latest" ]; then
    oc adm upgrade --to-latest=true
  else
    oc adm upgrade --to="${OCP_VERSION}"
  fi
}
