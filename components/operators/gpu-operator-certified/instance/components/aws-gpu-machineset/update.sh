#!/bin/sh

# shellcheck disable=SC2086,SC2129

create_file(){
  # See https://github.com/redhat-na-ssa/demo-ai-gitops-catalog
  FILENAME=${1:-functions.sh}

  FUNCTIONS='
  ocp_aws_cluster
  ocp_aws_machineset_create_gpu
  ocp_aws_machineset_clone_worker
  ocp_aws_machineset_fix_storage
  ocp_machineset_create_autoscale
  ocp_machineset_patch_accelerator
  ocp_machineset_taint_gpu
  '

  curl -sL -o ocp.tmp https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/raw/refs/heads/main/scripts/library/ocp.sh 
  curl -sL -o ocp_aws.tmp https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/raw/refs/heads/main/scripts/library/ocp_aws.sh 

  # create new script
  [ -e "${FILENAME}" ] || echo "#!/bin/sh" > "${FILENAME}"
  sed -n '1,/(){/ {/(){/d; p}' "${FILENAME}" > tmp

  for function in ${FUNCTIONS}
  do
    function_extract $function ocp.tmp >> tmp
    function_extract $function ocp_aws.tmp >> tmp
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
