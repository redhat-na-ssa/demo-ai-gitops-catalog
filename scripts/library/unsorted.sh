#!/bin/bash

select_folder(){
  FOLDER="${1:-options}"
  PS3="Select by number: "
  
  [ -d "${FOLDER}" ] || return

  echo "Options"

  pushd "${FOLDER}" >/dev/null || return
  
  select selected_folder in */
  do
    [ -d "${selected_folder}" ] && break
    echo ">>> Invalid Selection <<<";
  done

  if [ -n "${selected_folder}" ]; then
    echo "Selected: ${selected_folder}"
  else
    select_folder "${FOLDER}"
  fi

  popd >/dev/null || return
}

operator_list(){
  VERSION=4.12
  INDEX=${1:-registry.redhat.io/redhat/redhat-operator-index:v${VERSION}}

  which oc-mirror >/dev/null 1>&2 || return

  echo "Please be patient. This process is slow..." 1>&2
  echo "oc mirror list operators --catalog ${INDEX}" 1>&2
  echo "INDEX: ${INDEX}"

  oc mirror list operators --catalog "${INDEX}"
  
  echo ""
}

operator_list_all(){
  VERSION=4.12
  # redhat-operators
  INDEX_LIST="registry.redhat.io/redhat/redhat-operator-index:v${VERSION}"
  # certified-operators
  INDEX_LIST="${INDEX_LIST} registry.redhat.io/redhat/certified-operator-index:v${VERSION}"
  # redhat-marketplace
  INDEX_LIST="${INDEX_LIST} registry.redhat.io/redhat/redhat-marketplace-index:v${VERSION}"
  # community-operators
  INDEX_LIST="${INDEX_LIST} registry.redhat.io/redhat/community-operator-index:v${VERSION}"

  for index in ${INDEX_LIST}
  do
    operator_list "${index}"
  done
}

reset_wordlist(){
  pyspelling | sort -u | grep -E -v ' |---|/|^$' > .wordlist-md
}

setup_namespace(){
  NAMESPACE=${1}

  oc new-project "${NAMESPACE}" 2>/dev/null || \
    oc project "${NAMESPACE}"
}

ocp_gcp_get_key(){
  # get gcp creds
  oc -n kube-system extract secret/gcp-credentials --keys=service_account.json --to=- | jq . > service_account.json
}
