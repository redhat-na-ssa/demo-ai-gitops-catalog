#!/bin/sh

ocp_check_login(){
  oc cluster-info | head -n1
  oc whoami || exit 1
  echo
}

ocp_check_info(){
  ocp_check_login

  echo "NAMESPACE: $(oc project -q)"
  sleep "${SLEEP_SECONDS:-8}"
}

ocp_aws_get_key(){
  # get aws creds
  AWS_ACCESS_KEY_ID=$(oc -n kube-system extract secret/aws-creds --keys=aws_access_key_id --to=-)
  AWS_SECRET_ACCESS_KEY=$(oc -n kube-system extract secret/aws-creds --keys=aws_secret_access_key --to=-)
  AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-2}

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION

  echo "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"
}

ocp_aws_cluster_autoscaling(){
  oc apply -k components/configs/autoscale/overlays/gpus

  ocp_aws_create_gpu_machineset g4dn.4xlarge
  ocp_create_machineset_autoscale 0 3

  ocp_control_nodes_schedulable

  # scale workers to 1
  WORKER_MS="$(oc -n openshift-machine-api get machineset -o name | grep worker)"
  ocp_scale_machineset 1 "${WORKER_MS}"
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
  oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep gpu || \
    oc -n openshift-machine-api get "${MACHINE_SET}" -o yaml | \
      sed '/machine/ s/-worker/-gpu/g
        /name/ s/-worker/-gpu/g
        s/instanceType.*/instanceType: '"${INSTANCE_TYPE}"'/
        s/replicas.*/replicas: 0/' | \
      oc apply -f -

  MACHINE_SET_GPU=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep gpu | head -n1)

  # cosmetic
  oc -n openshift-machine-api \
    patch "${MACHINE_SET_GPU}" \
    --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/gpu":""}}}}}}'

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
  [ ! -e scratch/kubeadmin.yaml ] && \
    oc get secret kubeadmin -n kube-system -o yaml > scratch/kubeadmin.yaml
  oc delete secret kubeadmin -n kube-system
}

ocp_upgrade_cluster(){
  OCP_VERSION="${1:-latest}"

  if [ "${OCP_VERSION}" = "latest" ]; then
    oc adm upgrade --to-latest=true
  else
    oc adm upgrade --to="${OCP_VERSION}"
  fi
}