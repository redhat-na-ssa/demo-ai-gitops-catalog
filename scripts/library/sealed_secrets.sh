#!/bin/bash

SEALED_SECRETS_FOLDER="${GIT_ROOT}/components/operators/sealed-secrets-operator/operator/overlays/default"
SEALED_SECRETS_SECRET="${GIT_ROOT}/bootstrap/sealed-secrets-secret.yaml"

sealed_secret_create(){
  read -r -p "Create NEW [${SEALED_SECRETS_SECRET}]? [y/N] " input
  case $input in
    [yY][eE][sS]|[yY])

      oc apply -k "${SEALED_SECRETS_FOLDER}"

      # sanity check
      [ -e "${SEALED_SECRETS_SECRET}" ] && return

      # TODO: explore using openssl
      # oc -n sealed-secrets -o yaml \
      #   create secret generic

      # just wait for it
      k8s_wait_for_crd sealedsecrets.bitnami.com
      oc -n sealed-secrets \
        rollout status deployment sealed-secrets-controller
      sleep 10

      oc -n sealed-secrets \
        -o yaml \
        get secret \
        -l sealedsecrets.bitnami.com/sealed-secrets-key=active \
        > "${SEALED_SECRETS_SECRET}"

      ;;
    [nN][oO]|[nN])
      echo
      ;;
    *)
      echo
      echo "!!NOTICE!!: Cluster automation MAY NOT WORK w/o a valid sealed secret"
      echo "Choosing NO may have unintended results - see docs for more info"
      echo "Contact a repo MAINTINAER to get a current sealed secrets key"
      echo
      echo 'You must choose yes or no to continue'
      echo      
      sealed_secret_create
      ;;
  esac
}

sealed_secret_check(){
  if [ -f "${SEALED_SECRETS_SECRET}" ]; then
    echo "Exists: ${SEALED_SECRETS_SECRET}"
    oc apply -f "${SEALED_SECRETS_FOLDER}/namespace.yaml"
    oc apply -f "${SEALED_SECRETS_SECRET}" || return 1
    oc apply -k "${SEALED_SECRETS_FOLDER}"
  else
    echo "Missing: ${SEALED_SECRETS_SECRET}"
    echo "The master key is required to bootstrap sealed secrets and CANNOT be checked into git."
    echo
    [ -n "${NON_INTERACTIVE}" ] || sealed_secret_create
  fi
}
