#!/bin/bash
# see https://projectcalico.docs.tigera.io/getting-started/windows-calico/openshift/installation
# set -x

INSTALL_DIR=ocp-calico-install
TMP_DIR=generated
unset KUBECONFIG

setup_bin() {
  mkdir -p ${TMP_DIR}/bin
  echo ${PATH} | grep -q "${TMP_DIR}/bin" || \
    export PATH=$(pwd)/${TMP_DIR}/bin:$PATH
}

check_ocp_install() {
  which openshift-install 2>&1 >/dev/null || download_ocp_install
  echo "auto-complete: . <(openshift-install completion bash)"
  . <(openshift-install completion bash)
  openshift-install version
  sleep 5
}

check_oc() {
  which oc 2>&1 >/dev/null || download_oc
  echo "auto-complete: . <(oc completion bash)"
  . <(oc completion bash)
  oc version
  sleep 5
}

download_ocp_install() {
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.10/openshift-install-linux.tar.gz
  curl "${DOWNLOAD_URL}" -L | tar vzx -C ${TMP_DIR}/bin openshift-install
}

download_oc() {
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-4.10/openshift-client-linux.tar.gz
  curl "${DOWNLOAD_URL}" -L | tar vzx -C ${TMP_DIR}/bin oc
}

calico_init_install() {
    cd ${TMP_DIR}
    [ ! -d ${INSTALL_DIR} ] && mkdir ${INSTALL_DIR}
    cd ${INSTALL_DIR}
    
    [ -e install-config.yaml ] || openshift-install create install-config

    [ -e install-config.yaml ] || exit
}

calico_update_sdn() {
  sed -i 's/OpenShiftSDN/Calico/' install-config.yaml
  cp install-config.yaml ../install-config.yaml-$(date +%s)
}

calico_download_manifests() {
  openshift-install create manifests

  [ ! -d manifests ] && mkdir manifests
  [ -d calico ] && rm -rf calico 
  wget -qO- https://github.com/projectcalico/calico/releases/download/v3.29.3/ocp.tgz | tar xvz --strip-components=1 -C calico
  cp calico/* manifests/
}

calico_create_cr_vxlan() {

echo "
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  variant: Calico
  calicoNetwork:
    bgp: Disabled
    ipPools:
    - blockSize: 26
      cidr: 10.128.0.0/14
      encapsulation: VXLAN
      natOutgoing: Enabled
      nodeSelector: all()
" > manifests/01-cr-installation.yaml

}

calico_backup_install() {
  cd ..
  [ ! -d install-$(date +%s) ] && cp -a ${INSTALL_DIR} install-$(date +%s)
}

calico_print_cmd() {
  cd ..
  echo "${TMP_DIR}/bin/openshift-install create cluster --dir ${TMP_DIR}/${INSTALL_DIR}"
  echo "export KUBECONFIG=\$(pwd)/${TMP_DIR}/${INSTALL_DIR}/auth/kubeconfig"
  export KUBECONFIG=$(pwd)/${TMP_DIR}/${INSTALL_DIR}/auth/kubeconfig
}

setup_bin
check_ocp_install
check_oc
calico_init_install
calico_update_sdn
calico_download_manifests
calico_create_cr_vxlan
calico_backup_install
calico_print_cmd