#!/bin/bash

HTPASSWD_FILE=scratch/htpasswd

# shellcheck disable=SC2120
genpass(){
  < /dev/urandom LC_ALL=C tr -dc Aa-zZ0-9 | head -c "${1:-32}"
}

which htpasswd || return 1

DEFAULT_HTPASSWD=scratch/htpasswd-local
DEFAULT_OCP_GROUP=users

htpasswd_add_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}
  HTPASSWD_FILE=${3:-${DEFAULT_HTPASSWD}}

  if ! which htpasswd >/dev/null; then
    echo "Error: install htpasswd"
    return 1
  fi

  echo "
    USERNAME: ${USER}
    PASSWORD: ${PASS}

    FILENAME: ${HTPASSWD_FILE}
  "

  [ -e "${HTPASSWD_FILE}" ] || touch "${HTPASSWD_FILE}"
  htpasswd -bB -C 10 "${HTPASSWD_FILE}" "${USER}" "${PASS}"
}

htpasswd_ocp_get_file(){
  HTPASSWD_FILE=${1:-${DEFAULT_HTPASSWD}}
  HTPASSWD_NAME=$(basename "${HTPASSWD_FILE}")

  oc -n openshift-config \
    extract secret/"${HTPASSWD_NAME}" \
    --keys=htpasswd \
    --to=- > "${HTPASSWD_FILE}"
}

htpasswd_ocp_set_file(){
  HTPASSWD_FILE=${1:-${DEFAULT_HTPASSWD}}
  HTPASSWD_NAME=$(basename "${HTPASSWD_FILE}")

  oc -n openshift-config \
    set data secret/"${HTPASSWD_NAME}" \
    --from-file=htpasswd="${HTPASSWD_FILE}"
}

htpasswd_encrypt_file(){
  HTPASSWD_FILE=${1:-${DEFAULT_HTPASSWD}}

  age --encrypt --armor \
    -R authorized_keys \
    -o "$(basename "${HTPASSWD_FILE}")".age \
    "${HTPASSWD_FILE}"
}

htpasswd_decrypt_file(){
  HTPASSWD_FILE=${1:-${DEFAULT_HTPASSWD}}

  age --decrypt \
    -i ~/.ssh/id_ed25519 \
    -i ~/.ssh/id_rsa \
    -o "${HTPASSWD_FILE}" \
    "$(basename "${HTPASSWD_FILE}")".age
}

ocp_auth_create_group(){
  OCP_GROUP=${1:-${DEFAULT_OCP_GROUP}}

  oc get group "${OCP_GROUP}" > /dev/null 2>&1 && return

echo "
apiVersion: user.openshift.io/v1
kind: Group
metadata:
  name: ${OCP_GROUP}
" | oc apply -f-

}

ocp_auth_add_to_group(){
  USER=${1:-admin}
  OCP_GROUP=${2:-${DEFAULT_OCP_GROUP}}
  
  ocp_auth_create_group "${OCP_GROUP}"

  oc adm groups add-users \
  "${OCP_GROUP}" "${USER}"
}

ocp_auth_setup_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}
  OCP_GROUP=${3:-${DEFAULT_OCP_GROUP}}

  htpasswd_add_user "${USER}" "${PASS}"
  ocp_auth_add_to_group "${USER}" "${OCP_GROUP}"

  echo "
    run: htpasswd_ocp_set_file
  "
}
