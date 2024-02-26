#!/bin/bash
# set -e

# 8 seconds is usually enough time for the average user to realize they foobar
export SLEEP_SECONDS=8

################# standard init #################

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

# shellcheck source=/dev/null
. "${SCRIPT_DIR}/functions.sh"

is_sourced && return

bin_check oc
ocp_check_info || exit

main(){
  select_folder bootstrap

  # kludge
  # shellcheck disable=SC2154
  if [ "${selected_folder}" == "argo-managed/" ]; then
    oc apply -k components/operators/openshift-gitops-operator/operator/overlays/latest
    
    echo "Waiting for OpenShift GitOps deployments to start"
    until oc get deployment cluster -n openshift-gitops >/dev/null 2>&1
    do
      sleep 1
    done
  fi

  # shellcheck disable=SC2154
  apply_firmly "bootstrap/${selected_folder}"
}

# manage args passed to script
if [ -z ${1+x} ]; then
  main
else

  # this is specifically intended for demo.redhat.com
  export NON_INTERACTIVE=true

  echo "MODE: NON INTERACTIVE"

  if get_functions | grep -q "${1}"; then
    echo "running: ${1}"
    "${1}"
  else
    echo "error: ${1} is not a valid function"
  fi
fi
