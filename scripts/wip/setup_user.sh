#!/bin/bash

# shellcheck disable=SC2120
genpass(){
    < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"${1:-32}"
}

USER=${1:-admin}
PASS=${2:-$(genpass)}

htpasswd_add_user(){
  HTPASSWD_FILE=scratch/htpasswd

  echo "
    USERNAME: ${USER}
    PASSWORD: ${PASS}
  "

  touch "${HTPASSWD_FILE}"
  htpasswd -bB -C 10 "${HTPASSWD_FILE}" "${USER}" "${PASS}"
}

htpasswd_set_file(){
  oc -n openshift-config \
    set data secret/oauth-htpasswd \
    --from-file=htpasswd="${HTPASSWD_FILE}"
}

htpasswd_set_ocp_admin(){
  OCP_ADMIN_GROUP=demo-admins
  
  oc adm groups add-users \
  "${OCP_ADMIN_GROUP}" "${USER}"
}

htpasswd_encrypt_file(){
  age --encrypt --armor \
    -R authorized_keys \
    -o htpasswd.age \
    scratch/htpasswd
}

htpasswd_decrypt_file(){
  age --decrypt \
    -i ~/.ssh/id_ed25519 \
    -i ~/.ssh/id_rsa \
    -o scratch/htpasswd \
    htpasswd.age
}

ocp_setup_user(){
  htpasswd_add_user
  htpasswd_set_ocp_admin

  echo "
    run: htpasswd_set_file
  "
}
