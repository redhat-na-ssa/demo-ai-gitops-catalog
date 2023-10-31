#!/bin/bash
# shellcheck disable=SC1091

check_shell(){
  [ -n "$BASH_VERSION" ] && return
  echo "Please verify you are running in bash shell"
  sleep "${SLEEP_SECONDS:-8}"
}

check_git_root(){
  [ -n "${GIT_ROOT}" ] && return

  if [ -d .git ] && [ -d scripts ]; then
    GIT_ROOT=$(pwd)
    export GIT_ROOT
    echo "GIT_ROOT: ${GIT_ROOT}"
    return
  else
    echo "Please run this script from the root of the git repo"
    exit
  fi
}

get_script_path(){
  [ -n "${SCRIPT_DIR}" ] && return

  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo "SCRIPT_DIR: ${SCRIPT_DIR}"
}

source_library(){
  for file in "${SCRIPT_DIR}/library/"*.sh
  do
    if [ -f "$file" ] ; then
      # shellcheck source=/dev/null
      . "$file"
    fi
  done
}

setup_bin_path(){
  [ -z ${GIT_ROOT+x} ] && return 1
  BIN_PATH="${GIT_ROOT}/scratch/bin"

  mkdir -p "${BIN_PATH}"
  echo "${PATH}" | grep -q "${BIN_PATH}" || \
    PATH="${BIN_PATH}:${PATH}"
    export PATH
}

get_functions(){
  # echo -e "loaded functions:\n"
  sed -n '/(){/ s/(){$//p' "${SCRIPT_DIR}/"{library/*,functions}.sh | sort
}

is_sourced(){
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

check_shell
check_git_root
get_script_path
source_library
setup_bin_path

usage(){
  echo "USAGE: get_functions"
}

usage
