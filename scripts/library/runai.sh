#!/bin/bash

runai_help(){
  echo "
  See: https://docs.run.ai/v2.15/admin/runai-setup/self-hosted/ocp/prerequisites
  
  "
  
  sleep 6
}
runai_setup(){
  OCP_CLUSTER_DOMAIN=${1:-$(oc -n openshift-ingress-operator get dns cluster --template='{{.spec.baseDomain}}')}

  runai_help

  oc apply -k "${GIT_ROOT}"/components/configs/kustomized/runai-setup

  helm repo add runai-backend https://backend-charts.storage.googleapis.com
  helm repo update
  helm upgrade -i runai-backend -n runai-backend runai-backend/control-plane \
    --set global.domain=runai.apps."${OCP_CLUSTER_DOMAIN}" \
    --set global.config.kubernetesDistribution=openshift

  echo "
  Login @ https://runai.apps.${OCP_CLUSTER_DOMAIN}
    User: test@run.ai
    Password: Abcd!234
  "
}

runai_setup_cluster(){
  OCP_CLUSTER_DOMAIN=${1:-$(oc -n openshift-ingress-operator get dns cluster --template='{{.spec.baseDomain}}')}

  helm repo add runai https://run-ai-charts.storage.googleapis.com
  helm repo update
  helm upgrade -i runai-cluster runai/runai-cluster -n runai \
    --set controlPlane.url=runai.apps."${OCP_CLUSTER_DOMAIN}" \
    --set cluster.url=runai.apps."${OCP_CLUSTER_DOMAIN}" \
    --set controlPlane.clientSecret=Nkm7yzwnuK3NUa2XSoVk5EZ9xI4nVycA \
    --set cluster.uid=465a3cbe-11ca-448b-aa93-3c0847d9cfe9 \
    --version=2.15.9 \
    --create-namespace

}