#!/bin/bash
# shellcheck disable=SC2155

# kludges
# TODO: ArgoCD Hooks

setup_namespace(){
  NAMESPACE=${1}

  oc new-project "${NAMESPACE}" 2>/dev/null || \
    oc project "${NAMESPACE}"
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

# get functions
# sed -n '/(){/ s/(){$//p' scripts/kludges.sh
