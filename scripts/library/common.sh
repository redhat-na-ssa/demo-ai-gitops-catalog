#!/bin/bash

check_cluster_version(){
  OCP_VERSION=$(oc version | sed -n '/Server Version: / s/Server Version: //p')
  AVOID_VERSIONS=()
  TESTED_VERSIONS=("4.12.33")

  echo "Current OCP version: ${OCP_VERSION}"
  echo "Tested OCP version(s): ${TESTED_VERSIONS[*]}"
  echo ""

  # shellcheck disable=SC2076
  if [[ " ${AVOID_VERSIONS[*]} " =~ " ${OCP_VERSION} " ]]; then
    echo "OCP version ${OCP_VERSION} is known to have issues with this demo"
    echo ""
    echo 'Recommend: "oc adm upgrade --to-latest=true"'
    echo ""
  fi
}

micro_argocd(){
  if [ ! -f "${1}/kustomization.yaml" ]; then
    echo "Please provide a dir with \"kustomization.yaml\""
    return
  fi

  until_true oc apply -k "${1}"
}

until_true(){
  echo "Running:" "${@}"
  until "${@}"
  do
    echo "again..."
    sleep 2
  done

  echo "[OK]"
}
