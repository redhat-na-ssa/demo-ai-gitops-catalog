#!/bin/bash

# see https://ksingh7.medium.com/lets-automate-let-s-encrypt-tls-certs-for-openshift-4-211d6c081875

check_git_root(){
  if [ -d .git ] && [ -d scripts ]; then
    GIT_ROOT=$(pwd)
    export GIT_ROOT
    echo "GIT_ROOT: ${GIT_ROOT}"
  else
    echo "Please run this script from the root of the git repo"
    exit
  fi
}

if [ -z "${AWS_ACCESS_KEY_ID}" ]; then
  echo "Error:
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
  "
  exit 1
fi

export EMAIL=${EMAIL:-no-reply@github.com}

SCRATCH=./scratch
ACME_DIR=${SCRATCH}/acme
CERT_DIR=${SCRATCH}/le-certs

[ ! -d "${CERT_DIR}" ] && mkdir -p "${CERT_DIR}"

setup_acme(){
  [ ! -d "${ACME_DIR}" ] && git clone https://github.com/acmesh-official/acme.sh.git "${ACME_DIR}"

  # init acme
  ${ACME_DIR}/acme.sh \
    --register-account \
    -m "${EMAIL}"
}

set_cluster_cert_names(){
  # LE_HOSTNAME=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
  OCP_APPS="$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')"
  OCP_DOMAIN="${OCP_APPS#apps.}"
  OCP_API="api.${OCP_DOMAIN}"
  OCP_APPS="*.apps.${OCP_DOMAIN}"
  
  echo "
    OCP_DOMAIN: ${OCP_DOMAIN}
    OCP_API:    ${OCP_API}
    OCP_APPS:   ${OCP_APPS}
  "

  [ -z "${OCP_DOMAIN}" ] && exit 1

  # sleep 8
}

request_le_cert(){
  unset LE_DOMAINS
  DOMAINS=( "$@" )

  for domain in "${DOMAINS[@]}"
  do
    LE_DOMAINS=("${LE_DOMAINS[@]}" "-d ${domain}")
  done

  "${ACME_DIR}"/acme.sh \
    --issue \
    --dnssleep 60 \
    --dns dns_aws \
    "${LE_DOMAINS[@]}"

  "${ACME_DIR}"/acme.sh \
    --install-cert \
    --cert-file "${CERT_DIR}"/cert.pem \
    --key-file "${CERT_DIR}"/key.pem \
    --fullchain-file "${CERT_DIR}"/fullchain.pem \
    --ca-file "${CERT_DIR}"/ca.cer \
    "${LE_DOMAINS[@]}"

}

config_openshift_apps_certs(){
  [ -e "${CERT_DIR}"/key.pem ] || return

  oc -n openshift-ingress \
    delete secret wildcard-certificate

  oc -n openshift-ingress \
    create secret tls wildcard-certificate \
    --cert="${CERT_DIR}"/fullchain.pem \
    --key="${CERT_DIR}"/key.pem

  if oc -n openshift-ingress get secret wildcard-certificate; then
    oc -n openshift-ingress-operator \
      patch ingresscontroller default \
      --type=merge \
      --patch='{"spec": { "defaultCertificate": { "name": "wildcard-certificate" }}}'
  else
    echo "LE Setup: Error wildcard-certificate"
    exit 1
  fi
}

config_openshift_api_certs(){
  [ -e "${CERT_DIR}"/key.pem ] || return

  oc -n openshift-config \
    delete secret api-certificate

  oc -n openshift-config \
    create secret tls api-certificate \
    --cert=${CERT_DIR}/fullchain.pem \
    --key=${CERT_DIR}/key.pem

  if oc -n openshift-config get secret api-certificate; then
    oc patch apiserver cluster \
      --type=merge -p '{"spec":{"servingCerts": {"namedCertificates": [{"names": ["'"${LE_HOSTNAME}"'"], "servingCertificate": {"name": "api-certificate"}}]}}}'
  else
    echo "LE Setup: Error api-certificate"
    exit 1
  fi
}

setup_openshift_certs(){
  request_le_cert "${OCP_API}" "${OCP_APPS}"
  config_openshift_apps_certs
  config_openshift_api_certs
}

setup_acs_cert(){
  request_le_cert "central-stackrox.${OCP_APPS}"
  config_acs_cert
}

check_git_root
setup_acme
set_cluster_cert_names
setup_openshift_certs

sleep 6
oc get po -n openshift-ingress
