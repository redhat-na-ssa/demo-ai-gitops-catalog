#!/bin/bash
# kludges

# TODO: ArgoCD Hooks
# clobber htpasswd-secret on demo cluster
oc delete -n openshift-config sealedsecret/htpasswd-secret
oc delete -n openshift-config secret/htpasswd-secret

# Create ack operator secrets with main creds
# NOTE: operators are in godmode, meh

# manually create ack-system
oc create ns ack-system

# get aws creds
export AWS_ACCESS_KEY_ID=$(oc -n kube-system extract secret/aws-creds --keys=aws_access_key_id --to=-)
export AWS_SECRET_ACCESS_KEY=$(oc -n kube-system extract secret/aws-creds --keys=aws_secret_access_key --to=-)

# create secrets for ack controllers
NAMESPACE=ack-system
cat components/operators/ack-ec2-controller/operator/overlays/alpha/user-secrets-secret.yaml | \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

cat components/operators/ack-ecr-controller/operator/overlays/alpha/user-secrets-secret.yaml | \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

cat components/operators/ack-iam-controller/operator/overlays/alpha/user-secrets-secret.yaml | \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

cat components/operators/ack-s3-controller/operator/overlays/alpha/user-secrets-secret.yaml | \
  sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
  oc -n ${NAMESPACE} apply -f -

cat components/operators/ack-sagemaker-controller/operator/overlays/alpha/user-secrets-secret.yaml | \
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

oc patch apiserver cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates": [{"names": ["'${API_HOST_NAME}'"], "servingCertificate": {"name": "'${CERT_NAME}'"}}]}}}'
