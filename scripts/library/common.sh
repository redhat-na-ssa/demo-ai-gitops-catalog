#!/bin/bash

# shellcheck disable=SC2034
RED='\033[1;31m'
BLUE='\033[1;36m'
PURPLE='\033[1;35m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# echo -e "${BLUE}INFO:${NC}"
# echo -e "${RED}ERROR:${NC}"
# echo -e "${ORANGE}WARNING:${NC}""

genpass(){
  < /dev/urandom LC_ALL=C tr -dc Aa-zZ0-9 | head -c "${1:-32}"
}

apply_config(){
  retry oc apply -f "$1" 2>/dev/null
}

apply_kustomize(){
  if [ ! -f "$1/kustomization.yaml" ]; then
    echo "Please provide a dir with 'kustomization.yaml'"
    echo "'kustomization.yaml' not found in ${1}"
    return 0
  fi

  retry oc apply -k "$1" 2>/dev/null
}

apply_firmly(){
  if [ ! -f "${1}/kustomization.yaml" ]; then
    echo "Please provide a dir with 'kustomization.yaml'"
    echo "'kustomization.yaml' not found in ${1}"
    return 0
  fi

  # until oc kustomize "${1}" --enable-helm | oc apply -f- 2>/dev/null
  until_true oc apply -k "${1}" 2>/dev/null
}

until_true(){
  echo "Running:" "${@}"
  echo "Press <ctrl> + c to cancel"
  until "${@}" 1>&2
  do
    echo "again..."
    sleep 20
  done

  echo "[OK]"
}

retry(){
  local n=1
  local max=12
  local delay=20

  echo "Running:" "${@}"
  echo "Repeat: x${max}"
  echo "Delay: ${delay}s"

  # until "${@}" 1>&2
  until "${@}"
  do
    if [[ $n -lt $max ]]; then
      ((n++))
      echo "Retry after $delay sec"
      sleep $delay
    else
      echo "Failed after $n attempts."
        return 1
    fi
  done
  echo "[OK]"
}

extract_function(){
  EXPORT_NAME=${1:-ocp_aws_cluster}
  FILE=${2:-scripts/library/ocp.sh}

  sed -n '/'"${EXPORT_NAME}"'(){/,/^}/p' "${FILE}"
}
