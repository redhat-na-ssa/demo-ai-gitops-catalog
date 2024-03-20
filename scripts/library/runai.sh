#!/bin/bash

runai_help(){
  echo "
  See: https://docs.run.ai/v2.15/admin/runai-setup/self-hosted/ocp/prerequisites
  "
  sleep 6
}
runai_setup_control_plane(){
  OCP_CLUSTER_DOMAIN=${1:-$(oc -n openshift-ingress-operator get dns cluster --template='{{.spec.baseDomain}}')}

  runai_help

  oc apply -k "${GIT_ROOT}"/components/configs/kustomized/runai-setup

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
  Login @ https://runai.apps.${OCP_CLUSTER_DOMAIN}
    User: test@run.ai
    Password: Abcd!234
  "
}

runai_create_cluster(){
  USER=test@run.ai
  PASS='Abcd!234'
  DATA={\"name\":\"default\",\"description\":\"Default\"}
  
  curl -vk -X POST https://runai.apps."${OCP_CLUSTER_DOMAIN}"/auth/realms/runai/protocol/openid-connect/token \
  -u "${USER}:${PASS}" \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode 'scope=openid' \
  --data-urlencode 'response_type=id_token' \
  --data-urlencode 'client_id=test@run.ai' \
  --data-urlencode 'client_secret=Abcd!234'

  # curl -vk -o /tmp/auth -u "${USER}:${PASS}" https://runai.apps."${OCP_CLUSTER_DOMAIN}"/v1/k8s/auth/me
  # curl -vk -o /tmp/bundle.json -u "${USER}:${PASS}" -H "Content-Type: application/json" --data ${DATA} https://runai.apps."${OCP_CLUSTER_DOMAIN}"/v1/k8s/clusters
}

runai_setup_cluster(){
  OCP_CLUSTER_DOMAIN=${1:-$(oc -n openshift-ingress-operator get dns cluster --template='{{.spec.baseDomain}}')}

  helm repo add runai https://run-ai-charts.storage.googleapis.com
  helm repo update

  CERT_NAME=$(oc -n openshift-ingress-operator get ingresscontrollers default --template='{{.spec.defaultCertificate.name}}')

  if [ "${CERT_NAME}" == "<no value>" ]; then  
    HELM_OPTS="--set global.customCA.enabled=true"
  fi

  helm upgrade -i runai-cluster runai/runai-cluster -n runai \
    --set controlPlane.url=runai.apps."${OCP_CLUSTER_DOMAIN}" \
    --set cluster.url=runai.apps."${OCP_CLUSTER_DOMAIN}" \
    --set controlPlane.clientSecret=E1LqoomxPjyrdy0OgXANc2fMzGxXjrRI \
    --set cluster.uid=911f6190-4efc-430c-888b-959f1e3ab7e7 \
    ${HELM_OPTS} \
    --version=2.15.9 \
    --create-namespace

}

runai_uninstall(){
  helm uninstall runai-cluster -n runai
  oc delete -k "${GIT_ROOT}"/components/configs/kustomized/runai-setup
}
