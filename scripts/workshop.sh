#!/bin/bash
# shellcheck disable=SC2068,SC2120,SC1091

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "${SCRIPT_DIR}"/functions.sh || return 1

TMP_DIR=scratch
OBJ_DIR=${TMP_DIR}/workshop

WORKSHOP_USER=${WORKSHOP_USER:-user}
WORKSHOP_PASS=${WORKSHOP_PASS:-openshift}
WORKSHOP_NUM=${WORKSHOP_NUM:-50}
WORKSHOP_HTPASSWD=${OBJ_DIR}/htpasswd-workshop
WORKSHOP_GROUP=workshop-users

workshop(){
  workshop_init
  _workshop_usage
}

workshop_clean(){
  echo "Workshop: Remove User Namespaces"
  echo "Press CTRL + C to abort..."
  sleep 8

  [ -n "${OBJ_DIR}" ] && rm -rf "${OBJ_DIR}"

  workshop_stop_notebooks
  workshop_clean_users
}

workshop_clean_jobs(){
  oc delete jobs -l owner=workshop -A
}

workshop_clean_users(){
  oc delete ns -l workshop=user
  oc delete group "${WORKSHOP_GROUP}"
  oc delete identities,users --all
}

workshop_create_user(){
  USERNAME=${1:-user}
  PASSWORD=${2:-openshift}

  # create login things
  htpasswd_add_user "${USERNAME}" "${PASSWORD}" "${WORKSHOP_HTPASSWD}"
  ocp_auth_add_to_group "${USERNAME}" "${WORKSHOP_GROUP}"

  # create users from template
  cp -a workshops/instance "${OBJ_DIR}/${USERNAME}"
  sed -i 's/user0/'"${USERNAME}"'/g' "${OBJ_DIR}/${USERNAME}/"*.yaml
  oc apply -f "${OBJ_DIR}/${USERNAME}/ns.yaml"
  oc apply -k "${OBJ_DIR}/${USERNAME}"
}

workshop_create_users(){
  TOTAL=${1:-10}
  LIST=$(eval echo "{1..${TOTAL}}")

  for i in ${LIST[@]}
  # for ((i=1;i<=TOTAL;i++))
  do
    workshop_create_user "${WORKSHOP_USER}${i}" "${WORKSHOP_PASS}${i}" 
  done

  # update htpasswd in cluster
  htpasswd_ocp_set_file "${WORKSHOP_HTPASSWD}"
}

workshop_create_users_load(){
  LOAD_IMAGE=${1:-quay.io/devfile/universal-developer-image:ubi8-latest}
  LOAD_CPU=${2:-400m}
  LOAD_MEM=${3:-1Gi}

  for ((i=1;i<=WORKSHOP_NUM;i++))
  do

echo "
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: load-test
  # name: ${WORKSHOP_USER}${i}
  name: load-test
  namespace: ${WORKSHOP_USER}${i}
spec:
  containers:
  - name: test
    image: ${LOAD_IMAGE}
    command:
      - sleep
      - infinity
    resources:
      requests:
        cpu: ${LOAD_CPU}
        memory: ${LOAD_MEM}
  restartPolicy: Always
" | oc apply -f -
  done
}

workshop_init(){
  # create generated folder
  [ ! -d "${OBJ_DIR}" ] && mkdir -p "${OBJ_DIR}"
}

workshop_load_test(){
  workshop_create_user_load
}

workshop_load_test_clean(){
  oc delete pod -l run=load-test -A
}

workshop_reset(){
  echo "Workshop: Reset"
  workshop_clean
  sleep 8
  workshop_setup
}

workshop_setup(){
  TOTAL=${1:-10}
  echo "Workshop: Setup"

  workshop_init
  # apply_firmly workshop/overlays/default

  workshop_create_users "${TOTAL}"
  htpasswd_ocp_set_file "${WORKSHOP_HTPASSWD}"
}

workshop_stop_notebooks(){
  # stop notebooks
  oc annotate notebooks kubeflow-resource-stopped='now' --all -A

  # oc -n rhods-notebooks \
  #   delete pod -l app=jupyterhub
}

