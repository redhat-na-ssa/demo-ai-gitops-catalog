#!/bin/bash
# shellcheck disable=SC2034,SC2125,SC2086,SC2119,SC2120

RUNAI_DEFAULT_USER='test@run.ai'
RUNAI_DEFAULT_PASS='Abcd!234'
OCP_CLUSTER_DOMAIN=${1:-$(oc -n openshift-ingress-operator get dns cluster --template='{{.spec.baseDomain}}')}
RUNAI_URL="https://runai.apps.${OCP_CLUSTER_DOMAIN}"

runai_help(){
  echo "
  See: https://docs.run.ai/v2.15/admin/runai-setup/self-hosted/ocp/prerequisites
  "
  sleep 6
}

runai_get_token(){
  RUNAI_URL_AUTH="${RUNAI_URL}/auth/realms/runai/protocol/openid-connect/token"

  RUNAI_TOKEN=$(curl "${RUNAI_URL_AUTH}" \
    --insecure --location \
    --request POST \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=runai' \
    --data-urlencode "username=${RUNAI_DEFAULT_USER}" \
    --data-urlencode "password=${RUNAI_DEFAULT_PASS}" \
    --data-urlencode 'scope=openid' \
    --data-urlencode 'response_type=id_token' | jq -r .access_token
  )

  echo "${RUNAI_TOKEN}"
}

runai_login_with_sso(){
  curl --request PUT "${RUNAI_URL}/v1/k8s/setting" \
  -H 'Accept: */*' \
  -H "Authorization: Bearer ${RUNAI_TOKEN}" \
  -H 'Content-Type: application/json' \
  --data-raw '{"key":"tenant.login_with_sso","value":true}'
}

runai_setup_control_plane(){

  runai_help

  oc apply -k "${GIT_ROOT}"/components/app-configs/runai-setup

  which helm || return 1
  helm repo add runai-backend https://backend-charts.storage.googleapis.com
  helm repo update

  CERT_NAME=$(oc -n openshift-ingress-operator get ingresscontrollers default --template='{{.spec.defaultCertificate.name}}')

  if [ "${CERT_NAME}" == "<no value>" ]; then

    HELM_OPTS="--set global.customCA.enabled=true"

    oc -n openshift-ingress extract secrets/router-certs-default --keys=tls.crt --to=- > "${GIT_ROOT}"/scratch/runai-ca.pem

    oc -n runai create secret generic runai-ca-cert \
      --from-file=runai-ca.pem="${GIT_ROOT}"/scratch/runai-ca.pem

    oc -n runai-backend create secret generic runai-ca-cert \
      --from-file=runai-ca.pem="${GIT_ROOT}"/scratch/runai-ca.pem

    oc -n openshift-monitoring create secret generic runai-ca-cert \
      --from-file=runai-ca.pem="${GIT_ROOT}"/scratch/runai-ca.pem
  fi

  helm upgrade -i runai-backend -n runai-backend runai-backend/control-plane \
    --set global.domain=runai.apps."${OCP_CLUSTER_DOMAIN}" \
    --set global.config.kubernetesDistribution=openshift \
    ${HELM_OPTS}

  echo "
  Login @ ${RUNAI_URL}
    User: ${RUNAI_DEFAULT_USER}
    Password: ${RUNAI_DEFAULT_PASS}
  "
}

runai_create_cluster(){
  CLUSTER_NAME=${1:-local-cluster}
  DATA='{"name":"'"${CLUSTER_NAME}"'","description":"Default"}'

  RUNAI_TOKEN=$(runai_get_token)

  OUTPUT=$(
    curl --request POST "${RUNAI_URL}/v1/k8s/clusters" \
      -H 'Accept: */*' \
      -H "Authorization: Bearer ${RUNAI_TOKEN}" \
      -H 'Content-Type: application/json' \
      --data-raw "${DATA}"
   )

  RUNAI_CLUSTER_UUID=$(echo "${OUTPUT}" | jq -r .uuid)

  echo "${RUNAI_CLUSTER_UUID}"
}

runai_get_cluster_install(){
  RUNAI_CLUSTER_UUID=${1}
  RUNAI_CLUSTER_VER=${2:2.15}

  DATA='{"version":"'"${RUNAI_CLUSTER_VER}"'}'

  [ -z "${RUNAI_CLUSTER_UUID}" ] && return

  RUNAI_TOKEN=$(runai_get_token)

  OUTPUT=$(
    curl "${RUNAI_URL}/v1/k8s/clusters/${RUNAI_CLUSTER_UUID}/cluster-install-info" \
      -H 'Accept: */*' \
      -H "Authorization: Bearer ${RUNAI_TOKEN}" \
      -H 'Content-Type: application/json' \
      --data-raw "${DATA}"
  )

  echo "${OUTPUT}"
}

runai_setup_cluster(){

  CERT_NAME=$(oc -n openshift-ingress-operator get ingresscontrollers default --template='{{.spec.defaultCertificate.name}}')

  if [ "${CERT_NAME}" == "<no value>" ]; then
    HELM_OPTS="--set global.customCA.enabled=true"
  fi

  RUNAI_CLUSTER_UUID=$(runai_create_cluster)
  echo ${RUNAI_CLUSTER_UUID}

  RUNAI_CLUSTER_INSTALL=$(runai_get_cluster_install "${RUNAI_CLUSTER_UUID}")

  echo ${RUNAI_CLUSTER_INSTALL}

  # helm upgrade -i runai-cluster runai/runai-cluster -n runai \
  #   --set controlPlane.url=runai.apps."${OCP_CLUSTER_DOMAIN}" \
  #   --set cluster.url=runai.apps."${OCP_CLUSTER_DOMAIN}" \
  #   --set controlPlane.clientSecret=E1LqoomxPjyrdy0OgXANc2fMzGxXjrRI \
  #   --set cluster.uid=911f6190-4efc-430c-888b-959f1e3ab7e7 \
  #   ${HELM_OPTS} \
  #   --version=2.15.9 \
  #   --create-namespace
}

runai_uninstall(){
  helm uninstall runai-cluster -n runai
  oc delete -k "${GIT_ROOT}"/components/app-configs/runai-setup
}
