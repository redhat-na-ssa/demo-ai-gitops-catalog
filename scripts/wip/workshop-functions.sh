#!/bin/bash

USER=user
PASS=ThisIsFine
GROUP=workshop-users
HTPASSWD=htpasswd-workshop-secret
TMP_DIR=scratch

check_init(){
  # do you have oc
  which oc > /dev/null || exit 1

  # create generated folder
  [ ! -d ${TMP_DIR} ] && mkdir -p ${TMP_DIR}
}

workshop_create_user_htpasswd(){
  FILE=${TMP_DIR}/htpasswd
  touch ${FILE}

  which htpasswd || return

  for i in {0..20}
  do
    htpasswd -bB ${FILE} "${USER}${i}" "${PASS}${i}"
  done

  oc -n openshift-config create secret generic ${HTPASSWD} --from-file=${FILE}
  oc -n openshift-config set data secret/${HTPASSWD} --from-file=${FILE}

}

workshop_create_user_ns(){
  OBJ_DIR=${TMP_DIR}/users
  [ ! -d ${OBJ_DIR} ] && mkdir -p ${OBJ_DIR}

  for i in {0..20}
  do
    # create ns
    oc -o yaml --dry-run=client \
      create ns "${USER}${i}" > "${OBJ_DIR}/${USER}${i}-ns.yml"
    oc apply -f ${OBJ_DIR}

    # create role binding - admin for user
    oc -o yaml --dry-run=client \
      -n "${USER}${i}" \
      create rolebinding "${USER}${i}-admin" \
      --user "${USER}${i}" \
      --clusterrole admin > "${OBJ_DIR}/${USER}${i}-ns-admin-rb.yml"

    # create role binding - view for workshop group
    oc -o yaml --dry-run=client \
      -n "${USER}${i}" \
      create rolebinding "${USER}${i}-view" \
      --group ${GROUP} \
      --clusterrole view > "${OBJ_DIR}/${USER}${i}-rb-ns-view.yml"
  done

  # apply objects created in scratch dir
    oc apply -f ${OBJ_DIR}
 }

workshop_clean_user_ns(){
  for i in {0..20}
  do
    oc delete project "${USER}${i}"
  done
}

workshop_clean_user_notebooks(){
  oc -n rhods-notebooks \
    delete po -l app=jupyterhub
}

workshop_setup(){
  check_init
  workshop_create_user_htpasswd
  workshop_create_user_ns
}

workshop_clean(){
  echo "Workshop: Clean User Namespaces"
  check_init
  workshop_clean_user_ns
  workshop_clean_user_notebooks
}

workshop_reset(){
  echo "Workshop: Reset"
  check_init
  workshop_clean
  workshop_setup
}

echo "Workshop: Functions Loaded"
echo ""
echo "usage: workshop_[setup,reset,clean]"
