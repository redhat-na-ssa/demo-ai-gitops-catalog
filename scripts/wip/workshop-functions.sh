#!/bin/bash

# shellcheck disable=SC2120
genpass(){
  < /dev/urandom LC_ALL=C tr -dc _A-Z-a-z-0-9 | head -c "${1:-32}"
}

TMP_DIR=scratch
OBJ_DIR=${TMP_DIR}/workshop

DEFAULT_USER=user
DEFAULT_PASS=openshift
DEFAULT_GROUP=workshop-users

HTPASSWD_FILE=${OBJ_DIR}/htpasswd-workshop

htpasswd_add_user(){
  USERNAME=${1:-admin}
  PASSWORD=${2:-$(genpass 16)}

  echo "
    USERNAME: ${USERNAME}
    PASSWORD: ${PASSWORD}
  "

  touch "${HTPASSWD_FILE}"
  echo "# ${USERNAME} - ${PASSWORD}" >> "${HTPASSWD_FILE}"
  htpasswd -bB -C 10 "${HTPASSWD_FILE}" "${USERNAME}" "${PASSWORD}"
}

htpasswd_get_file(){
  oc -n openshift-config \
    extract secret/"${HTPASSWD_FILE##*/}" \
    --keys=htpasswd \
    --to=scratch
}

htpasswd_set_file(){
  oc -n openshift-config \
    create secret generic "${HTPASSWD_FILE##*/}"

  oc -n openshift-config \
    set data secret/"${HTPASSWD_FILE##*/}" \
    --from-file=htpasswd="${HTPASSWD_FILE}"
}

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
  [ ! -z "${OBJ_DIR}" ] && rm -rf "${OBJ_DIR}"
  [ ! -d "${OBJ_DIR}" ] && mkdir -p "${OBJ_DIR}"

  oc apply -k workshop/overlays/default
}

workshop_add_user_to_group(){
  USER=${1:-admin}
  OCP_ADMIN_GROUP=${2:-workshop-users}
  
  oc adm groups add-users \
  "${OCP_ADMIN_GROUP}" "${USER}"
}

workshop_create_user_htpasswd(){
  echo "
    HTPASSWD_FILE: ${HTPASSWD_FILE}
  "

  for i in ${LIST[@]}
  do
    htpasswd_add_user "${DEFAULT_USER}${i}" "${DEFAULT_PASS}${i}"
  done

  htpasswd_set_file

}

workshop_create_user_ns(){
  OBJ_DIR=${TMP_DIR}/workshop
  [ ! -d "${OBJ_DIR}" ] && mkdir -p "${OBJ_DIR}"

  for i in ${LIST[@]}
  do
    cp -a workshop/instance "${OBJ_DIR}/${DEFAULT_USER}${i}"
    sed -i 's/user0/'"${DEFAULT_USER}${i}"'/g' "${OBJ_DIR}/${DEFAULT_USER}${i}/"*.yaml
    # oc apply -f "${OBJ_DIR}/${DEFAULT_USER}${i}/user-ns.yaml"
    oc apply -k "${OBJ_DIR}/${DEFAULT_USER}${i}"
    workshop_add_user_to_group "${DEFAULT_USER}${i}" "${DEFAULT_GROUP}"


    # create ns
    # oc -o yaml --dry-run=client \
    #   create ns "${DEFAULT_USER}${i}" > "${OBJ_DIR}/${DEFAULT_USER}${i}-ns.yaml"
    # oc apply -f "${OBJ_DIR}/${DEFAULT_USER}${i}-ns.yaml"
    # workshop_add_user_to_group "${DEFAULT_USER}${i}" "${DEFAULT_GROUP}"

    # create role binding - admin for user
    # oc -o yaml --dry-run=client \
    #   -n "${DEFAULT_USER}${i}" \
    #   create rolebinding "${DEFAULT_USER}${i}-admin" \
    #   --user "${DEFAULT_USER}${i}" \
    #   --clusterrole admin > "${OBJ_DIR}/${DEFAULT_USER}${i}-ns-rb-admin.yaml"

    # create role binding - view for workshop group
    # oc -o yaml --dry-run=client \
    #   -n "${DEFAULT_USER}${i}" \
    #   create rolebinding "${DEFAULT_USER}${i}-view" \
    #   --group "${DEFAULT_GROUP}" \
    #   --clusterrole view > "${OBJ_DIR}/${DEFAULT_USER}${i}-ns-rb-view.yaml"
  done

  # apply objects created in scratch dir
    # oc apply \
    #   -f "${OBJ_DIR}"
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
  echo "Workshop: Clean"
  workshop_clean_user_ns
  workshop_clean_user_notebooks
  oc delete group "${DEFAULT_GROUP}"
}

workshop_reset(){
  echo "Workshop: Reset"
  workshop_clean
  workshop_setup
}

echo "Workshop: Functions Loaded"
echo ""
echo "usage: workshop_[setup,reset,clean] [number of users]"
