#!/bin/bash
# shellcheck disable=SC2155

# kludges
# TODO: ArgoCD Hooks

setup_namespace(){
  NAMESPACE=${1}

  oc new-project "${NAMESPACE}" 2>/dev/null || \
    oc project "${NAMESPACE}"
}

# clobber htpasswd-secret on demo cluster
# fix_htpasswd(){
#   oc delete -n openshift-config sealedsecret/htpasswd-secret >/dev/null 2>&1
#   oc delete -n openshift-config secret/htpasswd-secret >/dev/null 2>&1
# }

# get aws creds
get_aws_key(){
  # get aws creds
  export AWS_ACCESS_KEY_ID=$(oc -n kube-system extract secret/aws-creds --keys=aws_access_key_id --to=-)
  export AWS_SECRET_ACCESS_KEY=$(oc -n kube-system extract secret/aws-creds --keys=aws_secret_access_key --to=-)
  export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-west-2}
}

# create secrets for ack controllers
setup_ack_system(){
  # NOTE: operators are in godmode, meh
  NAMESPACE=ack-system

  # manually create ack-system
  setup_namespace "${NAMESPACE}"

  for type in ec2 ecr iam s3 sagemaker
  do
    # oc apply -k openshift/operators/ack-${type}-controller/operator/overlays/alpha

    # create ack operator secrets with main creds
    < components/operators/ack-${type}-controller/overlays/alpha/user-secrets-secret.yaml \
      sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
      oc -n "${NAMESPACE}" apply -f -
  done
}

# create a gpu machineset
setup_gpu_machineset(){
  MACHINE_SET=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)
  INSTANCE_TYPE=${1:-g4dn.12xlarge}

  oc -n openshift-machine-api get "${MACHINE_SET}" -o yaml | \
    sed '/machine/ s/-worker/-gpu/g
      /name/ s/-worker/-gpu/g
      s/instanceType.*/instanceType: '"${INSTANCE_TYPE}"'/
      s/replicas.*/replicas: 0/' | \
    oc apply -f -
}

# lets encrypt api cert
fix_api_cert(){
  echo "
  issue: RHDP can not start cluster due to ca.crt change

  fix:
    # login to bastion
    sed -i.bak '/certificate-authority-data/d' ~/.kube/config
  "

  CERT_NAME=$(oc -n openshift-ingress-operator get ingresscontrollers default --template='{{.spec.defaultCertificate.name}}')
  # API_HOST_NAME=$(oc -n openshift-console extract cm/console-config --to=- | sed -n '/masterPublicURL/ s/.*:\/\///; s/:6443//p')
  API_HOST_NAME=$(oc whoami --show-server | sed 's@https://@@; s@:.*@@')

  oc -n openshift-ingress get secret "${CERT_NAME}" -o yaml | \
    sed 's/namespace: .*/namespace: openshift-config/' | \
    oc -n openshift-config apply -f-

  oc patch apiserver cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates": [{"names": ["'"${API_HOST_NAME}"'"], "servingCertificate": {"name": "'"${CERT_NAME}"'"}}]}}}'
}

add_control_as_workers(){
  oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": true}}'
}

# try to save money
save_money(){
  # run work on masters (save $$$)
  add_control_as_workers
  # scale down workers (save $$$)
  oc -n openshift-machine-api \
    get machineset \
    -o name | grep worker | \
      xargs \
        oc -n openshift-machine-api \
        scale --replicas=1
}

expose_image_registry(){
  oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"defaultRoute":true}}'

  # remove 'default-route-openshift-image-' from route
  HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
  SHORTER_HOST=$(echo "${HOST}" | sed '/host/ s/default-route-openshift-image-//')
  oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge --patch '{"spec":{"host": "'"${SHORTER_HOST}"'"}}'
}

remove_kubeadmin(){
  oc get secret kubeadmin -n kube-system -o yaml > scratch/kubeadmin.yaml
  oc delete secret kubeadmin -n kube-system
}

# get functions
# sed -n '/(){/ s/(){$//p' scripts/kludges.sh

# fix_htpasswd
# get_aws_key
# setup_ack_system
# setup_gpu_machineset
# fix_api_cert
# openshift_save_money
# expose_image_registry
# remove_kubeadmin
