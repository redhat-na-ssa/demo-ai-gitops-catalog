#!/bin/bash

# shellcheck disable=SC2120
genpass(){
    < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c"${1:-32}"
}

HTPASSWD_FILE=scratch/htpasswd

htpasswd_add_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}

  echo "
    USERNAME: ${USER}
    PASSWORD: ${PASS}
  "

  touch "${HTPASSWD_FILE}"
  htpasswd -bB -C 10 "${HTPASSWD_FILE}" "${USER}" "${PASS}"
}

htpasswd_get_file(){
  oc -n openshift-config \
    extract secret/oauth-htpasswd \
    --keys=htpasswd \
    --to=scratch
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
    "${HTPASSWD_FILE}"
}

htpasswd_decrypt_file(){
  age --decrypt \
    -i ~/.ssh/id_ed25519 \
    -i ~/.ssh/id_rsa \
    -o "${HTPASSWD_FILE}" \
    htpasswd.age
}

ocp_setup_user(){
  USER=${1:-admin}
  PASS=${2:-$(genpass)}
  
  htpasswd_add_user "${USER}" "${PASS}"
  htpasswd_set_ocp_admin

  echo "
    run: htpasswd_set_file
  "
}
