#!/bin/bash

# shellcheck disable=SC2034
RED='\033[1;31m'
BLUE='\033[1;36m'
PURPLE='\033[1;35m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# echo -e "${BLUE}INFO:${NC}
# echo -e "${RED}ERROR:${NC}
# echo -e "${ORANGE}WARNING:${NC}

genpass(){
  < /dev/urandom LC_ALL=C tr -dc Aa-zZ0-9 | head -c "${1:-32}"
}

apply_firmly(){
  if [ ! -f "${1}/kustomization.yaml" ]; then
    echo "Please provide a dir with \"kustomization.yaml\""
    return 0
  fi

  # until oc kustomize "${1}" --enable-helm | oc apply -f- 2>/dev/null
  until_true oc apply -k "${1}" 2>/dev/null
}

until_true(){
  echo "Running:" "${@}"
  until "${@}" 1>&2
  do
    echo "again..."
    sleep 20
  done

  echo "[OK]"
}
