#!/bin/bash

LANG=C
SLEEP_SECONDS="${SLEEP_SECONDS:-8}"
SEALED_SECRETS_FOLDER=components/operators/sealed-secrets/operator/overlays/default
SEALED_SECRETS_SECRET=bootstrap/base/sealed-secrets-secret.yaml

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
        > ${SEALED_SECRETS_SECRET}

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
  if [ -f ${SEALED_SECRETS_SECRET} ]; then
    echo "Exists: ${SEALED_SECRETS_SECRET}"
    oc apply -f "${SEALED_SECRETS_FOLDER}/namespace.yaml"
    oc apply -f "${SEALED_SECRETS_SECRET}" || return 0
    oc apply -k "${SEALED_SECRETS_FOLDER}"
  else
    echo "Missing: ${SEALED_SECRETS_SECRET}"
    echo "The master key is required to bootstrap sealed secrets and CANNOT be checked into git."
    echo
    [ -n "${NON_INTERACTIVE}" ] || sealed_secret_create
  fi
}

ARGO_NS="openshift-gitops"
ARGO_CHANNEL="stable"
ARGO_DEPLOY_STABLE=(cluster kam openshift-gitops-applicationset-controller openshift-gitops-redis openshift-gitops-repo-server openshift-gitops-server)

# manage args passed to script
if [ "${1}" == "demo=enter_name_here" ]; then
  export NON_INTERACTIVE=true
  
  bootstrap_dir=bootstrap/overlays/workshop-rhdp
  ocp_control_nodes_not_schedulable
  ocp_create_machineset_autoscale 0 30
  ocp_scale_all_machineset 1
fi

wait_for_gitops(){
  echo "Waiting for operator to start"
  until oc get deployment gitops-operator-controller-manager -n openshift-operators >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for openshift-gitops namespace to be created"
  until oc get ns ${ARGO_NS} >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for deployments to start"
  until oc get deployment cluster -n ${ARGO_NS} >/dev/null 2>&1
  do
    sleep 1
  done

  echo "Waiting for all pods to be created"
  for i in "${ARGO_DEPLOY_STABLE[@]}"
  do
    echo "Waiting for deployment $i"
    oc rollout status deployment "$i" -n ${ARGO_NS} >/dev/null 2>&1
  done

  echo
  echo "OpenShift GitOps successfully installed."
}

install_gitops(){
  echo
  echo "Installing GitOps Operator."

  # kustomize build components/operators/openshift-gitops-operator/operator/overlays/stable | oc apply -f -
  oc apply -k "components/operators/openshift-gitops-operator/operator/overlays/${ARGO_CHANNEL}"

  echo "Pause ${SLEEP_SECONDS} seconds for the creation of the gitops-operator..."
  sleep "${SLEEP_SECONDS}"

  wait_for_gitops

}

select_bootstrap_folder(){
  PS3="Please select a bootstrap folder by number: "
  
  echo
  select bootstrap_dir in bootstrap/overlays/*/
  do
      test -n "$bootstrap_dir" && break
      echo ">>> Invalid Selection <<<";
  done

  bootstrap_cluster
}

bootstrap_cluster(){

  if [ -n "$bootstrap_dir" ]; then
    echo "Selected: ${bootstrap_dir}"
  else
    select_bootstrap_folder
  fi

  # kustomize build "${bootstrap_dir}" | oc apply -f -
  oc apply -k "${bootstrap_dir}"

  wait_for_gitops
  
  # apply the cr you know and love
  oc apply -k "components/operators/openshift-gitops-operator/instance/overlays/default"

  echo
  echo "GitOps has successfully deployed!  Check the status of the sync here:"

  route=$(oc get route openshift-gitops-server -o jsonpath='{.spec.host}' -n ${ARGO_NS})

  echo "https://${route}"
}
