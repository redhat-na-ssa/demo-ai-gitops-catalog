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

operator_list_init(){
  export DOCKER_CONFIG="${GIT_ROOT}/scratch"
  oc -n openshift-config extract secret/pull-secret --keys=.dockerconfigjson
  mkdir -p "${DOCKER_CONFIG}" && mv .dockerconfigjson "${DOCKER_CONFIG}/config.json"
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

setup_namespace(){
  NAMESPACE=${1}

  oc new-project "${NAMESPACE}" 2>/dev/null || \
    oc project "${NAMESPACE}"
}

ocp_gcp_get_key(){
  # get gcp creds
  oc -n kube-system extract secret/gcp-credentials --keys=service_account.json --to=- | jq . > scratch/service_account.json
}

lint_wordlist_reset(){
  pyspelling | sort -u | grep -Ev ' |---|/|^$' > .wordlist-md
}

lint_wordlist_sort(){
  LC_COLLATE=C sort -u < .wordlist-md > tmp
  mv tmp .wordlist-md
}

velero_create_secret(){
  VELERO_SECRET=scratch/credentials-velero

cat << YAML > "${VELERO_SECRET}"
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

[backupStorage]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

[volumeSnapshot]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
YAML

  oc create secret generic \
    -n openshift-adp \
    "$(basename ${VELERO_SECRET})" \
    --from-file cloud="${VELERO_SECRET}"
}
