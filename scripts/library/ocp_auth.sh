#!/bin/bash

# shellcheck source=/dev/null
[ -e htpasswd.sh ] && . htpasswd.sh

ocp_auth_add_admin_user(){
  HT_USERNAME=${1:-admin}
  HT_PASSWORD=${2:-$(genpass)}

  htpasswd_ocp_get_file
  htpasswd_add_user "${HT_USERNAME}" "${HT_PASSWORD}"
  htpasswd_ocp_set_file
  htpasswd_validate_user "${HT_USERNAME}" "${HT_PASSWORD}"
}

ocp_auth_add_to_group(){
  USER=${1:-admin}
  OCP_GROUP=${2:-${DEFAULT_OCP_GROUP}}

  ocp_auth_create_group "${OCP_GROUP}"

  oc adm groups add-users \
  "${OCP_GROUP}" "${USER}"
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

ocp_auth_kubeadmin_create(){
  PASS=${1:-$(genpass 5 )-$(genpass 5 )-$(genpass 5 )-$(genpass 5 )}

  which htpasswd >/dev/null || return 1

  HTPASSWD=$(htpasswd -nbB -C10 null "${PASS}")
  HASH=${HTPASSWD##*:}

  echo "
  PASSWORD: ${PASS}
  HASH:     ${HASH}

  oc apply -f scratch/kubeadmin.yaml
  "

cat << YAML > scratch/kubeadmin.yaml
kind: Secret
apiVersion: v1
metadata:
  name: kubeadmin
  namespace: kube-system
stringData:
  kubeadmin: ${HASH}
  password: ${PASS}
type: Opaque
YAML
}

ocp_auth_kubeadmin_remove(){
  FORCE=${1:-No}

  if [ "${FORCE}" = "YES" ]; then
    [ ! -e scratch/kubeadmin.yaml ] && \
      oc get secret kubeadmin -n kube-system -o yaml > scratch/kubeadmin.yaml || return 1
    oc delete secret kubeadmin -n kube-system
  else
    echo -e "${RED}
    WARNING: you must run - ocp_kubeadmin_remove YES

    WARNING: you will lose access to your cluster if you do not
      have a way to login to your cluster without kubeadmin. 
      
      Examples:
        - An identity provider with a cluster-admin user setup
        - A kubeconfig file
    ${NC}"
    return
  fi
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
