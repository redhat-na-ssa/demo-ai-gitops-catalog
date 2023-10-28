#!/bin/bash

# setup manifest info
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
MANIFEST_INFO="${MANIFEST_INFO},DISPLAY_NAME:.status.channels[0].currentCSVDesc.displayName"

BASIC_INFO="NAME:.status.packageName"
BASIC_INFO="${BASIC_INFO},DISPLAY_NAME:.status.channels[0].currentCSVDesc.displayName"
BASIC_INFO="${BASIC_INFO},DEFAULT_CHANNEL:.status.defaultChannel"
BASIC_INFO="${BASIC_INFO},CATALOG_SOURCE:.status.catalogSource"

pkg_manifests_get_all(){
  oc get packagemanifest \
    -o custom-columns="${BASIC_INFO}" \
    --sort-by='.status.catalogSource'
}

pkg_manifests_get_all_by_group(){
  PKG_GROUP=${1:-Red Hat Operators}
  pkg_manifests_get_all | grep "${PKG_GROUP}"
}

pkg_manifests_get_all_names_only(){
  pkg_manifests_get_all | grep -v NAME | awk '{print $1}'
}

pkg_manifests_get_all_details(){
  oc get packagemanifest \
    --sort-by='.status.packageName' \
    -o custom-columns="${MANIFEST_INFO}"
}

pkg_manifest_get_info(){
  [ "${1}x" == "x" ] && return 1
  NAME="${1}"
  
  oc get packagemanifest \
    "${NAME}" \
    -o=custom-columns="${MANIFEST_INFO}"
}

pkg_manifest_get_channels(){
  [ "${1}x" == "x" ] && return 1
  NAME="${1}"
  
  echo "NAME: ${NAME}"
  oc get packagemanifest \
    "${NAME}" \
    -o=jsonpath='{range .status.channels[*]}{.name}{"\n"}{end}' | sort
}

pkg_manifest_get_description(){
  [ "${1}x" == "x" ] && return 1
  NAME="${1}"

  echo -e "# ${NAME}\n"
  oc get packagemanifest \
    "${NAME}" \
    -o=jsonpath="{.status.channels[0].currentCSVDesc.description}"
}

pkg_manifests_save_all_details(){
  echo -e "# created: $(date -u)\n# script: dump_operator_info" > operator_info.txt
  pkg_manifests_get_all_details >> operator_info.txt
}
