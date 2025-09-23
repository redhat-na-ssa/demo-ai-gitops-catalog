#!/bin/bash
# shellcheck disable=SC2035

OPENSHIFT_MIRROR_URL=https://mirror.openshift.com/pub
OPENSHIFT_CLIENTS_URL=${OPENSHIFT_MIRROR_URL}/openshift-v4/x86_64/clients

bin_check(){
  name=${1:-oc}

  BIN_PATH=${BIN_PATH:-scratch/bin}
  BASH_COMP=${BASH_COMP:-scratch/bash}

  OS="$(uname | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"

  [ -d "${BIN_PATH}" ] || mkdir -p "${BIN_PATH}"
  [ -d "${BASH_COMP}" ] || mkdir -p "${BASH_COMP}"

  [ -e "${BIN_PATH}/${name}" ] || download_"${name}"

  # which "${name}" && return 0

  echo "
    CLI:    ${name}
    OS:     ${OS}
    ARCH:   ${ARCH}
  "

  case ${name} in
    oc|odo|virtctl)
      ${name} completion bash > "${BASH_COMP}/${name}.sh"
      ${name} version --client 2>&1
      [ "$name" == "oc" ] && kubectl completion bash > "${BASH_COMP}/kubectl.sh"
      ;;
    hcp|helm|kit|tkn|k9s|kn|krew|kustomize|oc-mirror|openshift-install|opm|oras|s2i|subctl|crane)
      ${name} completion bash > "${BASH_COMP}/${name}.sh"
      ${name} version 2>&1 || ${name} --version
      [ -e .oc-mirror.log ] && rm .oc-mirror.log
      ;;
    rhoas)
      export RHOAS_TELEMETRY=false
      ${name} completion bash > "${BASH_COMP}/${name}.sh"
      ${name} version 2>&1 || ${name} --version
      ;;
    rclone)
      ${name} completion bash - > "${BASH_COMP}/${name}.sh"
      ${name} version 2>&1
      ;;
    kubectl-operator)
      ;;
    restic)
      restic generate --bash-completion "${BASH_COMP}/${name}.sh"
      restic version
      ;;
    yq)
      ${name} shell-completion bash > "${BASH_COMP}/${name}.sh"
      ${name} --version
      ;;
    *)
      echo
      ${name} --version
      ;;
  esac
  # sleep 2
}

download_age(){
  BIN_VERSION=1.2.0
  DOWNLOAD_URL=https://github.com/FiloSottile/age/releases/download/v${BIN_VERSION}/age-v${BIN_VERSION}-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar vzx --strip-components=1 -C "${BIN_PATH}/"
  chmod +x "${BIN_PATH}"/age*
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

download_crane(){
  BIN_VERSION=0.20.6
  DOWNLOAD_URL=https://github.com/google/go-containerregistry/releases/download/v${BIN_VERSION}/go-containerregistry_Linux_x86_64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar vzx -C "${BIN_PATH}/" {crane,gcrane}
}

download_hcp(){
  BIN_VERSION=2.8.2-8
  # https://developers.redhat.com/content-gateway/rest/browse/pub/mce/clients/hcp-cli/
  DOWNLOAD_URL=https://developers.redhat.com/content-gateway/file/pub/mce/clients/hcp-cli/${BIN_VERSION}/hcp-cli-${BIN_VERSION}-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}

download_helm(){
  BIN_VERSION=latest
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/helm/${BIN_VERSION}/helm-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}"/ helm-linux-amd64
  mv "${BIN_PATH}/helm-linux-amd64" "${BIN_PATH}/helm"
}

download_k9s(){
  BIN_VERSION=v0.50.6
  K9S="k9s_${OS}_${ARCH}"
  DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${BIN_VERSION}/${K9S}.tar.gz"
  curl "${DOWNLOAD_URL}" -sL | tar vzx -C "${BIN_PATH}/"
  chmod +x "${BIN_PATH}/k9s"
}

download_kit(){
  DOWNLOAD_URL=https://github.com/jozu-ai/kitops/releases/latest/download/kitops-linux-x86_64.tar.gz
  echo $DOWNLOAD_URL
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/" kit
  chmod +x "${BIN_PATH}/kit"
}

download_kn(){
  BIN_VERSION=latest
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/serverless/${BIN_VERSION}/kn-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
  mv "${BIN_PATH}/kn-linux-amd64" "${BIN_PATH}/kn"
}

download_krew(){
  BIN_VERSION=latest
  KREW="krew-${OS}_${ARCH}"
  DOWNLOAD_URL="https://github.com/kubernetes-sigs/krew/releases/${BIN_VERSION}/download/${KREW}.tar.gz"
  curl "${DOWNLOAD_URL}" -sL | tar vzx -C "${BIN_PATH}/"
  mv "${BIN_PATH}/${KREW}" "${BIN_PATH}/krew"
  chmod +x "${BIN_PATH}/krew"
  krew install krew
}

download_kubectl-operator(){
  BIN_VERSION=0.5.1
  DOWNLOAD_URL=https://github.com/operator-framework/kubectl-operator/releases/download/v${BIN_VERSION}/kubectl-operator_v${BIN_VERSION}_linux_amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar vzx -C "${BIN_PATH}/"
  chmod +x "${BIN_PATH}/kubectl-operator"
}

download_kustomize(){
  BIN_VERSION=5.7.0
  DOWNLOAD_URL=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${BIN_VERSION}/kustomize_v${BIN_VERSION}_linux_amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/" kustomize
}

download_mirror-registry(){
  BIN_VERSION=latest
  DOWNLOAD_URL=${OPENSHIFT_MIRROR_URL}/cgw/mirror-registry/${BIN_VERSION}/mirror-registry-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
  chmod +x "${BIN_PATH}/mirror-registry"
}

download_oc(){
  BIN_VERSION=stable-4.18
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/ocp/${BIN_VERSION}/openshift-client-${OS:-linux}.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/" oc kubectl
}

download_oc-mirror(){
  BIN_VERSION=latest
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/ocp/${BIN_VERSION}/oc-mirror.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
  chmod +x "${BIN_PATH}/oc-mirror"
}

download_odo(){
  BIN_VERSION=latest
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/odo/${BIN_VERSION}/odo-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}

download_openshift-install(){
  BIN_VERSION=4.18.22
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/ocp/${BIN_VERSION}/openshift-install-linux.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/" openshift-install
  chmod +x "${BIN_PATH}/openshift-install"
}

download_opm(){
  BIN_VERSION=latest
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/ocp/${BIN_VERSION}/opm-linux.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}

download_oras(){
  BIN_VERSION=1.2.3
  DOWNLOAD_URL=https://github.com/oras-project/oras/releases/download/v${BIN_VERSION}/oras_${BIN_VERSION}_linux_amd64.tar.gz
  echo $DOWNLOAD_URL
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/" oras
  chmod +x "${BIN_PATH}/oras"
}

download_rclone(){
  curl -LsO https://downloads.rclone.org/rclone-current-linux-amd64.zip
  unzip rclone-current-linux-amd64.zip

  cp rclone-*-linux-amd64/rclone "${BIN_PATH}/rclone"
  chgrp root "${BIN_PATH}/rclone"
  chmod +x "${BIN_PATH}/rclone"

  rm -rf rclone-*-linux-amd64*
}

download_restic(){
  BIN_VERSION=0.18.0
  DOWNLOAD_URL=https://github.com/restic/restic/releases/download/v${BIN_VERSION}/restic_${BIN_VERSION}_linux_amd64.bz2
  curl "${DOWNLOAD_URL}" -sL | bzcat > "${BIN_PATH}/restic"
  chmod +x "${BIN_PATH}/restic"
}

download_rhoas(){
  BIN_VERSION=0.53.0
  DOWNLOAD_URL=https://github.com/redhat-developer/app-services-cli/releases/download/v${BIN_VERSION}/rhoas_${BIN_VERSION}_linux_amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx --strip-components=1 -C "${BIN_PATH}/"
}

download_s2i(){
  # BIN_VERSION=
  DOWNLOAD_URL=https://github.com/openshift/source-to-image/releases/download/v1.5.1/source-to-image-v1.5.1-c301811d-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}

download_sops(){
  BIN_VERSION=3.10.2
  DOWNLOAD_URL=https://github.com/getsops/sops/releases/download/v${BIN_VERSION}/sops-v${BIN_VERSION}.linux.amd64
  curl "${DOWNLOAD_URL}" -sLo "${BIN_PATH}/sops"
  chmod +x "${BIN_PATH}/sops"
}

download_subctl(){
  BIN_VERSION=0.20.1
  DOWNLOAD_URL=https://github.com/submariner-io/releases/releases/download/v${BIN_VERSION}/subctl-v${BIN_VERSION}-linux-amd64.tar.xz
  curl "${DOWNLOAD_URL}" -sL | tar Jx --strip-components=1 -C "${BIN_PATH}/"
}

download_tkn(){
  BIN_VERSION=latest
  DOWNLOAD_URL=${OPENSHIFT_CLIENTS_URL}/pipeline/${BIN_VERSION}/tkn-linux-amd64.tar.gz
  curl "${DOWNLOAD_URL}" -sL | tar zx -C "${BIN_PATH}/"
}

download_virtctl(){
  BIN_VERSION=1.5.2
  DOWNLOAD_URL=https://github.com/kubevirt/kubevirt/releases/download/v${BIN_VERSION}/virtctl-v${BIN_VERSION}-linux-amd64
  curl "${DOWNLOAD_URL}" -sL -o "${BIN_PATH}/virtctl"
  chmod +x "${BIN_PATH}/virtctl"
}

download_yq(){
  BIN_VERSION=4.45.4
  DOWNLOAD_URL=https://github.com/mikefarah/yq/releases/download/v${BIN_VERSION}/yq_linux_amd64
  curl "${DOWNLOAD_URL}" -sLo "${BIN_PATH}/yq"
  chmod +x "${BIN_PATH}/yq"
}
