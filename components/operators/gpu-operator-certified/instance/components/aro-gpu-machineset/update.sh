#!/bin/sh

# shellcheck disable=SC2086,SC2129

create_file(){
  # See https://github.com/redhat-na-ssa/demo-ai-gitops-catalog
  FILENAME=${1:-functions.sh}

  FUNCTIONS='
  ocp_aro_cluster
  ocp_aro_machineset_create_gpu
  ocp_aro_machineset_clone_worker
  ocp_aro_machineset_fix_storage
  ocp_machineset_create_autoscale
  ocp_machineset_patch_accelerator
  ocp_machineset_taint_gpu
  '

  curl -sL -o ocp.tmp https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/raw/refs/heads/main/scripts/library/ocp.sh 
  curl -sL -o ocp_aro.tmp https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/raw/refs/heads/main/scripts/library/ocp_aro.sh 

  # create new script
  [ -e "${FILENAME}" ] || echo "#!/bin/sh" > "${FILENAME}"
  sed -n '1,/(){/ {/(){/d; p}' "${FILENAME}" > tmp

  for function in ${FUNCTIONS}
  do
    function_extract $function ocp.tmp >> tmp
    function_extract $function ocp_aro.tmp >> tmp
    echo >> tmp
  done

  mv tmp "${FILENAME}"
  rm -- *.tmp
}

function_extract(){
  EXPORT_NAME=${1:-ocp_check_login}
  FILE=${2:-scripts/library/ocp.sh}

  sed -n '/'"${EXPORT_NAME}"'(){/,/^}/p' "${FILE}"
}

create_file ocp.sh
