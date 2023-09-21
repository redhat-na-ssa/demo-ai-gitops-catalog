#!/bin/bash
# shellcheck disable=SC2155

# kludges
# these may be useful but not mature

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

# get functions
# sed -n '/(){/ s/(){$//p' scripts/kludges.sh
