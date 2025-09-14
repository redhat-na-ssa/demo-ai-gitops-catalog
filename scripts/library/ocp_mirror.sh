#!/bin/bash

ocp_mirror_dry_run(){
  echo "See: https://docs.openshift.com/container-platform/4.14/installing/disconnected_install/installing-mirroring-installation-images.html"

  # TIME_STAMP=$(date +%s)
  TIME_STAMP=$(date +%Y.%m.%d)

  LOCAL_SECRET_JSON=${1:-scratch/pull-secret}
  PRODUCT_REPO=${2:-openshift-release-dev}
  RELEASE_NAME=${3:-ocp-release}
  OCP_RELEASE=${4:-4.14.20}
  ARCHITECTURE=${5:-x86_64}

  LOCAL_REGISTRY=${6:-localhost:5000}
  LOCAL_REPOSITORY=${7:-ocp4/openshift4}

  REMOVABLE_MEDIA_PATH=scratch/mirror_media

  [ -d "${REMOVABLE_MEDIA_PATH}" ] || mkdir -p "${REMOVABLE_MEDIA_PATH}"

  [ -e "${DOCKER_CONFIG}/config.json" ] || ocp_mirror_setup_pull_secret

  echo oc adm release mirror \
    -a "${LOCAL_SECRET_JSON}"  \
    --from="quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE}" \
    --to="${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}" \
    --to-release-image="${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}" \
    --dry-run | \
      tee "${REMOVABLE_MEDIA_PATH}/cmd.${TIME_STAMP}" | \
      bash 2>&1 | tee "${REMOVABLE_MEDIA_PATH}/dryrun.${TIME_STAMP}"

  # sed '0,/use the following/d ; /^$/d' scratch/dryrun

  echo "
  SAVED TO: ${REMOVABLE_MEDIA_PATH}/{cmd,dryrun}.${TIME_STAMP}
  "
}

ocp_mirror_operator_catalog_list(){
  VERSION=${1:-4.14}
  INDEX=${2:-registry.redhat.io/redhat/redhat-operator-index:v${VERSION}}

  which oc-mirror >/dev/null 1>&2 || return

  [ -e "${DOCKER_CONFIG}/config.json" ] || ocp_mirror_setup_pull_secret

  echo "Please be patient. This process is slow..." 1>&2
  echo "oc mirror --v2 list operators --catalog ${INDEX}" 1>&2
  echo "INDEX: ${INDEX}"

  oc mirror --v2 list operators --catalog "${INDEX}"

  echo ""
}

ocp_mirror_operator_catalog_list_all(){
  VERSION=${1:-4.18}

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
    ocp_mirror_operator_catalog_list "${VERSION}" "${index}"
  done
}

ocp_mirror_setup_pull_secret(){
  export DOCKER_CONFIG="${GIT_ROOT}/scratch"

  [ -e "${DOCKER_CONFIG}/config.json" ] && return

  oc -n openshift-config \
    extract secret/pull-secret \
    --to=- | tee "${GIT_ROOT}/scratch/pull-secret" > "${DOCKER_CONFIG}/config.json"

  # cat scratch/pull-secret | jq .
}
