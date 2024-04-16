#!/bin/bash

# shellcheck disable=SC2120
genpass(){
  < /dev/urandom LC_ALL=C tr -dc _A-Z-a-z-0-9 | head -c "${1:-32}"
}

TMP_DIR=scratch

DEFAULT_USER=user
DEFAULT_PASS=openshift
DEFAULT_GROUP=workshop-users

HTPASSWD_FILE=${TMP_DIR}/htpasswd-workshop

workshop_init(){
  TOTAL=${1:-25}
  LIST=$(eval echo "{0..${TOTAL}}" )

  # do you have oc
  which oc > /dev/null || return 1

  # do you have htpasswd
  if ! which htpasswd >/dev/null; then
    echo "error: install htpasswd"
    return 1
  fi

  # create generated folder
  [ ! -d ${TMP_DIR} ] && mkdir -p ${TMP_DIR}
}

htpasswd_add_user(){
  USERNAME=${1:-admin}
  PASSWORD=${2:-$(genpass 16)}

  echo "
    USERNAME: ${USERNAME}
    PASSWORD: ${PASSWORD}
  "

  touch "${HTPASSWD_FILE}"
  htpasswd -bB -C 10 "${HTPASSWD_FILE}" "${USERNAME}" "${PASSWORD}"
}

workshop_create_user_htpasswd(){
  echo "
    HTPASSWD_FILE: ${HTPASSWD_FILE}
  "

  for i in ${LIST[@]}
  do
    htpasswd_add_user "${DEFAULT_USER}${i}" "${DEFAULT_PASS}${i}"
  done
}

workshop_create_user_ns(){
  OBJ_DIR=${TMP_DIR}/workshop
  [ ! -d "${OBJ_DIR}" ] && mkdir -p "${OBJ_DIR}"

  for i in ${LIST[@]}
  do
    # create ns
    oc -o yaml --dry-run=client \
      create ns "${DEFAULT_USER}${i}" > "${OBJ_DIR}/${DEFAULT_USER}${i}-ns.yaml"
    oc apply -f "${OBJ_DIR}/${DEFAULT_USER}${i}-ns.yaml"

    # create role binding - admin for user
    oc -o yaml --dry-run=client \
      -n "${DEFAULT_USER}${i}" \
      create rolebinding "${DEFAULT_USER}${i}-admin" \
      --user "${DEFAULT_USER}${i}" \
      --clusterrole admin > "${OBJ_DIR}/${DEFAULT_USER}${i}-ns-rb-admin.yaml"

    # create role binding - view for workshop group
    oc -o yaml --dry-run=client \
      -n "${DEFAULT_USER}${i}" \
      create rolebinding "${DEFAULT_USER}${i}-view" \
      --group "${DEFAULT_GROUP}" \
      --clusterrole view > "${OBJ_DIR}/${DEFAULT_USER}${i}-ns-rb-view.yaml"
  done

  # apply objects created in scratch dir
    oc apply \
      -f "${OBJ_DIR}"
 }

workshop_clean_user_ns(){
  for i in ${LIST[@]}
  do
    oc delete project "${DEFAULT_USER}${i}"
  done
}

workshop_clean_user_notebooks(){
  oc -n rhods-notebooks \
    delete po -l app=jupyterhub
}

workshop_setup(){
  TOTAL=${1:-25}

  echo "Workshop: Setup"
  workshop_init "${TOTAL}"
  workshop_create_user_htpasswd
  workshop_create_user_ns
}

workshop_clean(){
  echo "Workshop: Clean User Namespaces"
  workshop_clean_user_ns
  workshop_clean_user_notebooks
}

workshop_reset(){
  echo "Workshop: Reset"
  workshop_clean
  workshop_setup
}

echo "Workshop: Functions Loaded"
echo ""
echo "usage: workshop_[setup,reset,clean]"
