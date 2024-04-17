#!/bin/bash
# shellcheck disable=SC2068

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
  HTPASSWD=${3:-scratch/htpasswd-local}

  echo "
    USERNAME: ${USERNAME}
    PASSWORD: ${PASSWORD}
  "

  touch "${HTPASSWD}"
  echo "# ${USERNAME} - ${PASSWORD}" >> "${HTPASSWD}"
  htpasswd -bB -C 10 "${HTPASSWD}" "${USERNAME}" "${PASSWORD}"
}

htpasswd_get_file(){
  HTPASSWD=${1:-scratch/htpasswd-local}

  oc -n openshift-config \
    extract secret/"${HTPASSWD##*/}" \
    --keys=htpasswd \
    --to=scratch
}

htpasswd_set_file(){
  HTPASSWD=${1:-scratch/htpasswd-local}

  oc -n openshift-config \
    set data secret/"${HTPASSWD##*/}" \
    --from-file=htpasswd="${HTPASSWD}"
}

workshop_usage(){
  echo ""
  echo "Usage: workshop_[setup,clean,reset] [number of users]
  "
}

workshop_init(){
  # do you have oc
  which oc || return 1

  # do you have htpasswd
  which htpasswd || return 1

  # create generated folder
  [ -n  "${OBJ_DIR}" ] && rm -rf "${OBJ_DIR}"
  [ ! -d "${OBJ_DIR}" ] && mkdir -p "${OBJ_DIR}"

  echo "Workshop: Functions Loaded"
  workshop_usage
}

workshop_create_group(){
  OCP_GROUP=${1:-workshop-users}

cat << YAML | oc apply -f -
kind: Group
apiVersion: user.openshift.io/v1
metadata:
  name: ${OCP_GROUP}
users: []
YAML
}

workshop_add_user_to_group(){
  USER=${1:-user0}
  OCP_GROUP=${2:-workshop-users}

  if ! oc get group "${OCP_GROUP}" > /dev/null; then
    workshop_create_group "${OCP_GROUP}"
  fi

  oc adm groups add-users \
    "${OCP_GROUP}" "${USER}"
}

workshop_create_users(){
  TOTAL=${1:-25}
  LIST=$(eval echo "{0..${TOTAL}}")

  for i in ${LIST[@]}
  do

    # create login things
    htpasswd_add_user "${DEFAULT_USER}${i}" "${DEFAULT_PASS}${i}" "${HTPASSWD_FILE}"
    workshop_add_user_to_group "${DEFAULT_USER}${i}" "${DEFAULT_GROUP}"

    # create users objs from template
    cp -a workshop/instance "${OBJ_DIR}/${DEFAULT_USER}${i}"
    sed -i 's/user0/'"${DEFAULT_USER}${i}"'/g' "${OBJ_DIR}/${DEFAULT_USER}${i}/"*.yaml
    # oc apply -f "${OBJ_DIR}/${DEFAULT_USER}${i}/user-ns.yaml"
    oc apply -k "${OBJ_DIR}/${DEFAULT_USER}${i}"

  done

  # update htpasswd in cluster
  htpasswd_set_file "${HTPASSWD_FILE}"

}

workshop_clean_active_notebooks(){
  oc -n rhods-notebooks \
    delete po -l app=jupyterhub
}

workshop_clean_users(){
  oc delete project -l owner=workshop
  oc delete group "${DEFAULT_GROUP}"
  oc delete identities,users --all
}

workshop_setup(){
  TOTAL=${1:-25}

  echo "Workshop: Setup"

  oc apply -k workshop/overlays/default

  htpasswd_set_file
  workshop_create_users
}

workshop_clean(){
  echo "Workshop: Clean"
  workshop_clean_active_notebooks
  workshop_clean_users
}

workshop_reset(){
  echo "Workshop: Reset"
  workshop_clean
  sleep 10
  workshop_setup
}

workshop_init
