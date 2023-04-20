#!/bin/bash
# shellcheck disable=SC2015,SC1091

COMPLETION_PATH=scratch
BIN_PATH=${COMPLETION_PATH}/bin
SEALED_SECRETS_FOLDER=components/operators/sealed-secrets/operator/overlays/default
SEALED_SECRETS_SECRET=bootstrap/base/sealed-secrets-secret.yaml

debug(){
echo "PWD:  $(pwd)"
echo "PATH: ${PATH}"
}

usage(){
echo "
You can run individual functions!
"
}

is_sourced() {
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

setup_venv(){
  python3 -m venv venv
  source venv/bin/activate
  pip install -q -U pip
  pip install -q awscli

  check_venv || usage
}

check_venv(){
  # activate python venv
  [ -d venv ] && . venv/bin/activate || setup_venv
  [ -e requirements.txt ] && pip install -q -r requirements.txt
}

check_oc(){
  echo "Are you on the right OCP cluster?"

  oc whoami || exit 0
  UUID=$(oc whoami --show-server | sed 's@https://@@; s@:.*@@; s@api.*-@@; s@[.].*$@@')
  export UUID
  oc status

  echo "UUID: ${UUID}"
  sleep 4
}

setup_bin(){
  mkdir -p "${BIN_PATH}"
  echo "${PATH}" | grep -q "${BIN_PATH}" || \
    PATH="$(pwd)/${BIN_PATH}:${PATH}"
    export PATH
}

check_aws(){
  aws --version || return
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

wait_for_crd(){
  CRD=${1}
  until oc get crd "${CRD}" >/dev/null 2>&1
    do sleep 1
  done
}

null_finalizers(){
  OBJ=${1}

  oc patch "${OBJ}" \
    --type=merge \
    -p '{"metadata":{"finalizers":null}}'

  # oc patch "${OBJ}" \
  #   --type="json" \
  #   -p '[{"op": "remove", "path":"/metadata/finalizers"}]'
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
  cd rclone-*-linux-amd64 || return

  cp rclone ${BIN_PATH}
  chown root:root ${BIN_PATH}/rclone
  chmod 755 ${BIN_PATH}/rclone

  cd ..
  rm -rf rclone-*-linux-amd64
}

download_restic(){
  BIN_VERSION=0.15.1
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

      # sanity check
      [ -e ${SEALED_SECRETS_SECRET} ] && return

      # TODO: explore using openssl
      # oc -n sealed-secrets -o yaml \
      #   create secret generic

      # just wait for it
      wait_for_crd sealedsecrets.bitnami.com
      oc -n sealed-secrets \
        rollout status deployment sealed-secrets-controller
      sleep 10

      oc -n sealed-secrets \
        -o yaml \
        get secret \
        -l sealedsecrets.bitnami.com/sealed-secrets-key=active \
        > ${SEALED_SECRETS_SECRET}

      ;;
    [nN][oO]|[nN])
      echo
      ;;
    *)
      echo
      echo "!!NOTICE!!: Cluster automation MAY NOT WORK w/o a valid sealed secret"
      echo "Choosing NO may have unintended results - see docs for more info"
      echo "Contact a repo MAINTINAER to get a current sealed secrets key"
      echo
      echo 'You must choose yes or no to continue'
      echo      
      create_sealed_secret
      ;;
  esac
}

# Validate sealed secrets secret exists
check_sealed_secret(){
  if [ -f ${SEALED_SECRETS_SECRET} ]; then
    echo "Exists: ${SEALED_SECRETS_SECRET}"
    oc apply -f ${SEALED_SECRETS_FOLDER}/namespace.yaml
    oc apply -f ${SEALED_SECRETS_SECRET} || return 0
    oc apply -k ${SEALED_SECRETS_FOLDER}
  else
    echo "Missing: ${SEALED_SECRETS_SECRET}"
    echo "The master key is required to bootstrap sealed secrets and CANNOT be checked into git."
    echo
    create_sealed_secret
  fi
}

get_aws_key(){
  # get aws creds
  AWS_ACCESS_KEY_ID=$(oc -n kube-system extract secret/aws-creds --keys=aws_access_key_id --to=-)
  AWS_SECRET_ACCESS_KEY=$(oc -n kube-system extract secret/aws-creds --keys=aws_secret_access_key --to=-)
  AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-us-east-2}

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION
}

aws_stop_all_ec2(){
  RUNNING_IDS=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[].Instances[].InstanceId' --output text | sed 's/\t/ /g')
  BASTION_ID=$(aws ec2 describe-instances --filters Name=tag:Name,Values=bastion --query 'Reservations[].Instances[].InstanceId' --output text)

  echo "BASTION_ID: ${BASTION_ID}"
  aws ec2 stop-instances \
    --instance-ids \
    "${RUNNING_IDS}" \
    --output text >/dev/null
}

aws_start_ocp4_cluster(){
  CLUSTER_IDS=$(aws ec2 describe-instances --filters Name=tag:env_type,Values=ocp4-cluster --query 'Reservations[].Instances[].InstanceId' --output text | sed 's/\t/ /g')

  aws ec2 start-instances \
    --instance-ids \
    "${CLUSTER_IDS}" \
    --output text >/dev/null
}
