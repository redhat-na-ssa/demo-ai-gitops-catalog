#!/bin/bash
set -e

check_shell(){
  [ -n "$BASH_VERSION" ] && return
  echo "Please verify you are running in bash shell"
  sleep "${SLEEP_SECONDS:-8}"
}

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

get_script_path(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo "SCRIPT_DIR: ${SCRIPT_DIR}"
}


check_shell
check_git_root
get_script_path

################# standard init #################

export SLEEP_SECONDS=8

# shellcheck source=/dev/null
. "${SCRIPT_DIR}/functions.sh"

# # manage args passed to script
# if [ "${1}" == "demo=enter_name_here" ]; then
#   export NON_INTERACTIVE=true
  
#   bootstrap_dir=bootstrap/overlays/workshop-rhdp
#   ocp_control_nodes_not_schedulable
#   ocp_create_machineset_autoscale 0 30
#   ocp_scale_machineset 1
# fi

check_bin oc
# check_bin kustomize
# check_bin kubeseal
ocp_check_info

# bootstrap
# sealed_secret_check
argo_install
select_folder bootstrap

# shellcheck disable=SC2154
oc apply -k "bootstrap/${selected}"
