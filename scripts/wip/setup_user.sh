#!/bin/bash

HTPASSWD_FILE=scratch/htpasswd

# shellcheck disable=SC2120
genpass(){
  < /dev/urandom LC_ALL=C tr -dc _A-Z-a-z-0-9 | head -c "${1:-32}"
}

htpasswd_add_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}

  if ! which htpasswd >/dev/null; then
    echo "Error: install htpasswd"
    return 1
  fi

  echo "
    USERNAME: ${USER}
    PASSWORD: ${PASS}

    FILENAME: ${HTPASSWD_FILE}
  "

  touch "${HTPASSWD_FILE}"
  htpasswd -bB -C 10 "${HTPASSWD_FILE}" "${USER}" "${PASS}"
}

htpasswd_get_file(){
  oc -n openshift-config \
    extract secret/htpasswd-local \
    --keys=htpasswd \
    --to=scratch
}

htpasswd_set_file(){
  oc -n openshift-config \
    set data secret/htpasswd-local \
    --from-file=htpasswd="${HTPASSWD_FILE}"
}

htpasswd_encrypt_file(){
  age --encrypt --armor \
    -R authorized_keys \
    -o htpasswd.age \
    "${HTPASSWD_FILE}"
}

htpasswd_decrypt_file(){
  age --decrypt \
    -i ~/.ssh/id_ed25519 \
    -i ~/.ssh/id_rsa \
    -o "${HTPASSWD_FILE}" \
    htpasswd.age
}

ocp_setup_htpasswd(){
  # check for existing secret
  oc -n openshift-config \
    get secret/htpasswd-local >/dev/null && return

  # apply htpasswd login
  oc apply -k components/configs/cluster/login/overlays/htpasswd
}

ocp_add_admin(){
  USER=${1:-admin}
  OCP_ADMIN_GROUP=${2:-demo-admins}
  
  oc adm groups add-users \
  "${OCP_ADMIN_GROUP}" "${USER}"
}

ocp_setup_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}

  ocp_setup_htpasswd
  ocp_add_admin "${USER}"
  htpasswd_add_user "${USER}" "${PASS}"

  echo "
    When complete run:
      htpasswd_set_file
  "
}
