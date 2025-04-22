#!/bin/bash
# shellcheck disable=SC1090
# see https://projectcalico.docs.tigera.io/getting-started/windows-calico/openshift/installation
# set -x

INSTALL_DIR=ocp-calico-install
TMP_DIR=generated
unset KUBECONFIG

setup_bin(){
  mkdir -p ${TMP_DIR}/bin
  echo "${PATH}" | grep -q "${TMP_DIR}/bin" || \
    PATH=$(pwd)/${TMP_DIR}/bin:$PATH
    export PATH
}

check_ocp_install(){
  which openshift-install >/dev/null 2>&1 || download_ocp_install
  echo "auto-complete: . <(openshift-install completion bash)"
  . <(openshift-install completion bash)
  openshift-install version
  sleep 3
}

check_oc(){
  which oc >/dev/null 2>&1 || download_oc
  echo "auto-complete: . <(oc completion bash)"
  . <(oc completion bash)
  oc version
  sleep 3
}

download_ocp_install(){
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.17/openshift-install-linux.tar.gz
  curl "${DOWNLOAD_URL}" -L | tar vzx -C ${TMP_DIR}/bin openshift-install
}

download_oc(){
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.17/openshift-client-linux.tar.gz
  curl "${DOWNLOAD_URL}" -L | tar vzx -C ${TMP_DIR}/bin oc
}

calico_init_install(){
    cd ${TMP_DIR} || exit
    [ ! -d ${INSTALL_DIR} ] && mkdir ${INSTALL_DIR}
    cd ${INSTALL_DIR} || exit
    
    [ -e install-config.yaml ] || openshift-install create install-config

    [ -e install-config.yaml ] || exit
}

calico_update_sdn(){
  sed -i 's/\(OpenShiftSDN\|OVNKubernetes\)/Calico/' install-config.yaml
  cp install-config.yaml ../install-config.yaml-"$(date +%s)"
}

calico_create_manifests(){
  openshift-install create manifests || exit 1
}

calico_download_manifests(){
  [ -d calico ] && rm -rf calico
  mkdir calico
  wget -qO- https://github.com/projectcalico/calico/releases/download/v3.29.3/ocp.tgz | tar xvz --strip-components=1 -C calico
  cp calico/* manifests/
}

calico_update_security_groups(){
# https://docs.tigera.io/calico/latest/getting-started/kubernetes/openshift/installation#generate-the-install-manifests

cat > insert.yaml << YAML
      - description: BGP (calico)
        fromPort: 179
        protocol: tcp
        toPort: 179
      - description: IP-in-IP (calico)
        fromPort: -1
        protocol: "4"
        toPort: -1
      - description: Typha (calico)
        fromPort: 5473
        protocol: tcp
        toPort: 5473
YAML

  sed '/cniIngressRules/r insert.yaml' \
    -i.orig cluster-api/02_infra-cluster.yaml
  
  rm insert.yaml
}

calico_backup_install(){
  cd ..
  [ ! -d install-"$(date +%s)" ] && cp -a "${INSTALL_DIR}" install-"$(date +%s)"
}

calico_print_cmd(){
  cd ..
  echo "${TMP_DIR}/bin/openshift-install create cluster --dir ${TMP_DIR}/${INSTALL_DIR}"
  echo "export KUBECONFIG=\$(pwd)/${TMP_DIR}/${INSTALL_DIR}/auth/kubeconfig"
  KUBECONFIG="$(pwd)/${TMP_DIR}/${INSTALL_DIR}/auth/kubeconfig"
  export KUBECONFIG
}

setup_bin
check_ocp_install
check_oc

calico_init_install
calico_update_sdn
calico_create_manifests
calico_download_manifests
calico_update_security_groups
calico_backup_install
calico_print_cmd
