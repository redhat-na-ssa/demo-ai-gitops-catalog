#!/bin/bash
# shellcheck disable=SC2155

# kludges
# TODO: ArgoCD Hooks


# clobber htpasswd-secret on demo cluster
oc delete -n openshift-config sealedsecret/htpasswd-secret >/dev/null 2>&1
oc delete -n openshift-config secret/htpasswd-secret >/dev/null 2>&1

# Create ack operator secrets with main creds
# NOTE: operators are in godmode, meh

# manually create ack-system
NAMESPACE=ack-system
oc create ns ${NAMESPACE}

# get aws creds
export AWS_ACCESS_KEY_ID=$(oc -n kube-system extract secret/aws-creds --keys=aws_access_key_id --to=-)
export AWS_SECRET_ACCESS_KEY=$(oc -n kube-system extract secret/aws-creds --keys=aws_secret_access_key --to=-)

# create secrets for ack controllers

< components/operators/ack-ec2-controller/operator/overlays/alpha/user-secrets-secret.yaml \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

< components/operators/ack-ecr-controller/operator/overlays/alpha/user-secrets-secret.yaml \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

< components/operators/ack-iam-controller/operator/overlays/alpha/user-secrets-secret.yaml \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

< components/operators/ack-s3-controller/operator/overlays/alpha/user-secrets-secret.yaml \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

< components/operators/ack-sagemaker-controller/operator/overlays/alpha/user-secrets-secret.yaml \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

# create a gpu machineset
MACHINE_SET=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep worker | head -n1)

oc -n openshift-machine-api get "${MACHINE_SET}" -o yaml | \
  sed '/machine/ s/-worker/-gpu/g
    /name/ s/-worker/-gpu/g
    s/instanceType.*/instanceType: g3s.xlarge/
    s/replicas.*/replicas: 0/' | \
  oc apply -f -

# fix API cert issues
CERT_NAME=$(oc -n openshift-ingress-operator get ingresscontrollers default --template='{{.spec.defaultCertificate.name}}')
API_HOST_NAME=$(oc -n openshift-console extract cm/console-config --to=- | sed -n '/masterPublicURL/ s/.*:\/\///; s/:6443//p')

oc -n openshift-ingress get secret "${CERT_NAME}" -o yaml | \
  sed 's/namespace: .*/namespace: openshift-config/' | \
  oc -n openshift-config apply -f-

oc patch apiserver cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates": [{"names": ["'"${API_HOST_NAME}"'"], "servingCertificate": {"name": "'"${CERT_NAME}"'"}}]}}}'

# try to save money
openshift_save_money(){
  # run work on masters (save $$$)
  oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": true}}'

  # scale down workers (save $$$)
  oc scale "$(oc -n openshift-machine-api get machineset -o name | grep worker)" -n openshift-machine-api --replicas=0
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

openshift_save_money
expose_image_registry
remove_kubeadmin
