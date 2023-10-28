#!/bin/bash

bin_check(){
  name=${1:-oc}

  which "${name}" || download_"${name}"
 
  case ${name} in
    helm|kustomize|oc|oc-mirror|odo|openshift-install|opm|s2i|tkn)
      echo "auto-complete: . <(${name} completion bash)"
      
      # shellcheck source=/dev/null
      . <(${name} completion bash)
      ${name} completion bash > "${BIN_PATH}/${name}.bash"
      
      ${name} version 2>&1 || ${name} --version
      ;;
    restic)
      restic generate --bash-completion "${BIN_PATH}/restic.bash"
      restic version
      ;;
    *)
      echo
      ${name} --version
      ;;
  esac
  sleep 2
}

download_busybox(){
  DOWNLOAD_URL=https://www.busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
  curl "${DOWNLOAD_URL}" -sLo "${BIN_PATH}/busybox"
  chmod +x "${BIN_PATH}/busybox"
  pushd "${BIN_PATH}" || return
  ln -s busybox unzip
  ln -s busybox bzcat
  popd || return
}

download_helm(){
  BIN_VERSION=latest
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/helm/${BIN_VERSION}/helm-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}"/ helm-linux-amd64
  mv "${BIN_PATH}/helm-linux-amd64"  "${BIN_PATH}/helm"
}

download_kustomize(){
  cd "${BIN_PATH}" || return
  curl -sL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
  cd ../..
}

download_oc(){
  BIN_VERSION=4.12
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-${BIN_VERSION}/openshift-client-linux.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/" oc kubectl
}

download_oc-mirror(){
  BIN_VERSION=4.12
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable-${BIN_VERSION}/oc-mirror.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
  chmod +x "${BIN_PATH}/oc-mirror"
}

download_odo(){
  BIN_VERSION=latest
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/odo/${BIN_VERSION}/odo-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}

download_opm(){
  BIN_VERSION=latest
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${BIN_VERSION}/opm-linux.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}

download_s2i(){
  # BIN_VERSION=
  DOWNLOAD_URL=https://github.com/openshift/source-to-image/releases/download/v1.3.2/source-to-image-v1.3.2-78363eee-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}

download_rclone(){
  curl -LsO https://downloads.rclone.org/rclone-current-linux-amd64.zip
  unzip rclone-current-linux-amd64.zip
  cd rclone-*-linux-amd64 || return

  cp rclone "${BIN_PATH}"
  chgrp root "${BIN_PATH}/rclone"
  chmod 755 "${BIN_PATH}/rclone"

  cd ..
  rm -rf rclone-*-linux-amd64*
}

download_restic(){
  BIN_VERSION=0.15.1
  DOWNLOAD_URL=https://github.com/restic/restic/releases/download/v${BIN_VERSION}/restic_${BIN_VERSION}_linux_amd64.bz2
  curl "${DOWNLOAD_URL}" -sL | bzcat > "${BIN_PATH}/restic"
  chmod 755 "${BIN_PATH}/restic"
}

download_tkn(){
  BIN_VERSION=latest
  DOWNLOAD_URL=https://mirror.openshift.com/pub/openshift-v4/clients/pipeline/${BIN_VERSION}/tkn-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}
