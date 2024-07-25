#!/bin/bash

# shellcheck disable=SC2164
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

uninstall_rhods_easy(){
  oc delete datasciencecluster default-dsc
  oc delete dscinitialization default-dsci
  oc delete -k "${SCRIPTPATH}"/../operator/overlays/uninstall
}

uninstall_rhods(){
  echo "
  starting: uninstall

  This is a WIP...
  "

  uninstall_rhods_easy || uninstall_rhods_hard
}

uninstall_rhods
