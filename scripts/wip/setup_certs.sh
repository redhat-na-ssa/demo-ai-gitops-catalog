#!/bin/bash
# shellcheck disable=SC2068

# see https://ksingh7.medium.com/lets-automate-let-s-encrypt-tls-certs-for-openshift-4-211d6c081875

export EMAIL=${EMAIL:-no-reply@github.com}

SCRATCH=./scratch
ACME_DIR=${SCRATCH}/acme
CERT_DIR=${SCRATCH}/le-certs

[ ! -d "${CERT_DIR}" ] && mkdir -p "${CERT_DIR}"

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

ocp_get_apps_domain(){
  oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}'
}

ocp_get_domain(){
  OCP_APPS_DOMAIN=$(ocp_get_apps_domain)
  echo "${OCP_APPS_DOMAIN#apps.}"
}

acme_setup(){
  [ ! -d "${ACME_DIR}" ] && git clone https://github.com/acmesh-official/acme.sh.git "${ACME_DIR}"

  # init acme
  ${ACME_DIR}/acme.sh \
    --register-account \
    -m "${EMAIL}"
}

acme_ocp_get_domain(){
  OCP_DOMAIN=$(ocp_get_domain)
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

acme_request_cert(){
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
    ${LE_DOMAINS[@]}

  "${ACME_DIR}"/acme.sh \
    --install-cert \
    --cert-file "${CERT_DIR}"/cert.pem \
    --key-file "${CERT_DIR}"/key.pem \
    --fullchain-file "${CERT_DIR}"/fullchain.pem \
    --ca-file "${CERT_DIR}"/ca.cer \
    ${LE_DOMAINS[@]}
}

acme_ocp_setup_certs_apps(){
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

acme_ocp_setup_certs_api(){
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

acme_ocp_setup_certs(){
  acme_request_cert "${OCP_API}" "${OCP_APPS}"
  acme_ocp_setup_certs_apps
  acme_ocp_setup_certs_api
}

acme_ocp_setup_certs_acs(){
  acme_request_cert "central-stackrox.${OCP_APPS}"
  echo "Please import the following cert into ACS:"
  echo "  ${CERT_DIR}/fullchain.pem"
  echo "  ${CERT_DIR}/key.pem"
}

check_git_root
acme_setup
acme_ocp_get_domain
acme_ocp_setup_certs

sleep 6
oc get po -n openshift-ingress
