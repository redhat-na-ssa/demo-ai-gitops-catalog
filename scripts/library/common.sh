#!/bin/bash
  
apply_config(){
  if [ ! -f "$1" ]; then
    echo "${1:-file} not found"
    return 1
  fi
  retry oc apply -f "$1" 2>/dev/null
}

apply_firmly(){
  if [ ! -f "${1:-.}/kustomization.yaml" ]; then
    echo "Please provide a dir with 'kustomization.yaml'"
    echo "'kustomization.yaml' not found in ${1}"
    return 1
  fi

  # until oc kustomize "${1}" --enable-helm | oc apply -f- 2>/dev/null
  until_true oc apply -k "${1}" 2>/dev/null
}

apply_kustomize(){
  if [ ! -f "${1}/kustomization.yaml" ]; then
    echo "Please provide a dir with 'kustomization.yaml'"
    echo "'kustomization.yaml' not found in ${1}"
    return 1
  fi

  retry oc apply -k "$1" 2>/dev/null
}

function_extract(){
  EXPORT_NAME=${1:-ocp_check_login}
  FILE=${2:-scripts/library/ocp.sh}

  sed -n '/'"${EXPORT_NAME}"'(){/,/^}/p' "${FILE}"
}

function_list(){
  FILE=${1:-scripts/library/ocp.sh}
  sed -n '/(){/ {/^_/d; s/(){$//p}' "${FILE}" | sort -u
}

function_sort_file(){
  FILE=${1:-scripts/library/ocp.sh}

  # create new script
  echo \
  "#!/bin/bash
  " > tmp

  for function in $(function_list "${FILE}")
  do
    function_extract "$function" "${FILE}" >> tmp
    echo >> tmp
  done

  mv tmp "${FILE}"
}

genpass(){
  < /dev/urandom LC_ALL=C tr -dc Aa-zZ0-9 | head -c "${1:-32}"
}

retry(){
  local attempts=30
  local delay=20

  echo "Running:" "${@}"
  echo "Attempts:  ${attempts}"
  echo "Delay:     ${delay}s"

  # until "${@}" 1>&2
  until "${@}"
  do
    if [[ $attempts -gt "1" ]]; then
      ((attempts--))
      echo "Remaining attempts: $attempts - waiting ${delay}s"
      sleep $delay
    else
      echo "[FAILED]"
        return 1
    fi
  done
  echo "[OK]"
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
