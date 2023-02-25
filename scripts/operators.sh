#!bin/bash

MANIFEST_INFO="NAME:.status.packageName"
MANIFEST_INFO="${MANIFEST_INFO},NAMESPACE:.status.channels[0].currentCSVDesc.annotations.operatorframework\.io/suggested-namespace"
MANIFEST_INFO="${MANIFEST_INFO},CATALOG_SOURCE:.status.catalogSource"
MANIFEST_INFO="${MANIFEST_INFO},SOURCE_NAMESPACE:.status.catalogSourceNamespace"
MANIFEST_INFO="${MANIFEST_INFO},DEFAULT_CHANNEL:.status.defaultChannel"
MANIFEST_INFO="${MANIFEST_INFO},CHANNELS:.status.channels[*].name"
MANIFEST_INFO="${MANIFEST_INFO},"'NS_OWN:.status.channels[0].currentCSVDesc.installModes[?(@.type=="OwnNamespace")].supported'
MANIFEST_INFO="${MANIFEST_INFO},"'NS_SINGLE:.status.channels[0].currentCSVDesc.installModes[?(@.type=="SingleNamespace")].supported'
MANIFEST_INFO="${MANIFEST_INFO},"'NS_MULTI:.status.channels[0].currentCSVDesc.installModes[?(@.type=="MultiNamespace")].supported'
MANIFEST_INFO="${MANIFEST_INFO},"'NS_ALL:.status.channels[0].currentCSVDesc.installModes[?(@.type=="AllNamespaces")].supported'

get_all_manifests(){
    oc get packagemanifest \
      --sort-by='.status.catalogSource'
}

get_manifest_channels(){
    NAME=${1}
    oc get \
      packagemanifest \
      "${NAME}" \
      -o=jsonpath="{.status.channels[*].name}{'\n'}"
}

get_manifest_info(){
    NAME=${1}
    oc get \
      packagemanifest \
      "${NAME}" \
      --no-headers \
      -o custom-columns="${MANIFEST_INFO}"
}

get_all_manifest_info(){
    NAME=${1}
    oc get \
      packagemanifest \
      --sort-by='.status.catalogSource' \
      -o custom-columns="${MANIFEST_INFO}"
}

create_operator_dir(){
    # default ns: openshift-operators
    # all namespaces: no operatorgroup
    NAME=${1}
    read -r NAME NAMESPACE CATALOG_SOURCE SOURCE_NAMESPACE OTHER <<<"$(get_manifest_info ${NAME})"

    create_base_subscription ${NAME} ${NAMESPACE} ${CATALOG_SOURCE} ${SOURCE_NAMESPACE}

}

create_base_subscription(){
NAME=${1}
NAMESPACE=${2}
CATALOG_SOURCE=${3}
SOURCE_NAMESPACE=${4}

BASE_DIR=components/operators/${NAMESPACE}/operator/base

mkdir -p ${BASE_DIR}

cat <<YAML > ${BASE_DIR}/subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ${NAME}
  namespace: ${NAMESPACE}
spec:
  channel: patch-me-see-overlays-dir
  installPlanApproval: Automatic
  name: ${NAME}
  source: ${CATALOG_SOURCE}
  sourceNamespace: ${SOURCE_NAMESPACE}
YAML

cat <<YAML > ${BASE_DIR}/kustomize.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - namespace.yaml
  - operator-group.yaml
  - subscription.yaml
YAML
}

debug(){
    NAME=${1}
    oc get \
      packagemanifest \
      "${NAME}" \
      -o jsonpath='{.status.channels[0].currentCSVDesc.installModes}{"\n"}'
}
