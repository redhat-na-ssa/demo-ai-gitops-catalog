#!/bin/bash


OCP_VERSION=4.10
BIN_PATH=generated
COMPLETION_PATH=${BIN_PATH}
SEALED_SECRETS_FOLDER=components/operators/sealed-secrets/operator/overlays/default
SEALED_SECRETS_SECRET=bootstrap/base/sealed-secrets-secret.yaml

debug(){
echo "PWD:  $(pwd)"
echo "PATH: ${PATH}"
}

setup_bin(){
  mkdir -p ${BIN_PATH}/bin
  echo "${PATH}" | grep -q "${BIN_PATH}/bin" || \
    PATH=$(pwd)/${BIN_PATH}/bin:${PATH}
    export PATH
}

check_bin(){
  name=$1
  
  which "${name}" || download_"${name}"
 
  case ${name} in
    helm|kustomize|oc|odo|openshift-install|s2i)
      echo "auto-complete: . <(${name} completion bash)"
      
      # shellcheck source=/dev/null
      . <(${name} completion bash)
      ${name} completion bash > "${COMPLETION_PATH}/${name}.bash"
      
      ${name} version
      ;;
    restic)
      restic generate --bash-completion ${COMPLETION_PATH}/restic.bash
      restic version
      ;;
    *)
      echo
      ${name} --version
      ;;
  esac
  sleep 2
}

download_helm(){
BIN_VERSION=latest
DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/helm/${BIN_VERSION}/helm-linux-amd64.tar.gz
curl "${DOWNLOAD_URL}" -sL | tar zx -C ${BIN_PATH}/ helm-linux-amd64
mv  ${BIN_PATH}/helm-linux-amd64  ${BIN_PATH}/helm
}

download_kustomize(){
  cd "${BIN_PATH}" || return
  curl -sL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
  cd ../..
}

download_oc(){
BIN_VERSION=4.10
DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-${BIN_VERSION}/openshift-client-linux.tar.gz
curl "${DOWNLOAD_URL}" -sL | tar zx -C ${BIN_PATH}/ oc kubectl
}

download_odo(){
BIN_VERSION=latest
DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/odo/${BIN_VERSION}/odo-linux-amd64.tar.gz
curl "${DOWNLOAD_URL}" -sL | tar zx -C ${BIN_PATH}/
}

download_s2i(){
# BIN_VERSION=
DOWNLOAD_URL=https://github.com/openshift/source-to-image/releases/download/v1.3.2/source-to-image-v1.3.2-78363eee-linux-amd64.tar.gz
curl "${DOWNLOAD_URL}" -sL | tar zx -C ${BIN_PATH}/
}

download_rclone(){
curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip
unzip rclone-current-linux-amd64.zip
cd rclone-*-linux-amd64

cp rclone ${BIN_PATH}
chown root:root ${BIN_PATH}/rclone
chmod 755 ${BIN_PATH}/rclone

cd ..
rm -rf rclone-*-linux-amd64
}

download_restic(){
BIN_VERSION=0.14.0
DOWNLOAD_URL=https://github.com/restic/restic/releases/download/v${BIN_VERSION}/restic_${BIN_VERSION}_linux_amd64.bz2
curl "${DOWNLOAD_URL}" -sL | bzcat > ${BIN_PATH}/restic
chmod 755 ${BIN_PATH}/restic
}


# check login
check_oc_login(){
  oc cluster-info | head -n1
  oc whoami || exit 1
  echo
  sleep 3
}

create_sealed_secret(){
  read -r -p "Create NEW [${SEALED_SECRETS_SECRET}]? [y/N] " input
  case $input in
    [yY][eE][sS]|[yY])

      oc apply -k ${SEALED_SECRETS_FOLDER}
      [ -e ${SEALED_SECRETS_SECRET} ] && return

      # TODO: explore using openssl
      # oc -n sealed-secrets -o yaml \
      #   create secret generic

      # just wait for it
      sleep 20

      oc -n sealed-secrets -o yaml \
        get secret \
        -l sealedsecrets.bitnami.com/sealed-secrets-key=active \
        > ${SEALED_SECRETS_SECRET}

      ;;
    [nN][oO]|[nN])
      echo
      ;;
    *)
      echo
      ;;
  esac
}

# Validate sealed secrets secret exists
check_sealed_secret(){
  if [ -f ${SEALED_SECRETS_SECRET} ]; then
    echo "Exists: ${SEALED_SECRETS_SECRET}"
    oc apply -f ${SEALED_SECRETS_FOLDER}/sealed-secrets-namespace.yaml
    oc apply -f ${SEALED_SECRETS_SECRET} || return 0
    oc apply -k ${SEALED_SECRETS_FOLDER}
  else
    echo "Missing: ${SEALED_SECRETS_SECRET}"
    echo "The master key is required to bootstrap sealed secrets and CANNOT be checked into git."
    echo
    create_sealed_secret
  fi
}
