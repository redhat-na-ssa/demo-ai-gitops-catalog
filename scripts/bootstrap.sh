#!/bin/bash
set -e

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

# manage args passed to script
if [ -z ${1+x} ]; then
  export NON_INTERACTIVE=true

  echo "NON INTERACTIVE MODE"
  echo "You are running ${1}"
fi

bin_check oc
set -x
ocp_check_info
set +x
# bootstrap
argo_install
select_folder bootstrap

# shellcheck disable=SC2154
oc apply -k "bootstrap/${selected}"
