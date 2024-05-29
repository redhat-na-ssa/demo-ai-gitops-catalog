#!/bin/bash

APP_PATH=${APP_PATH:-/etc/reverse_tunnel}
ENV_FILE=${ENV_FILE:-${APP_PATH}/env}
SSH_KEY=${SSH_KEY:-${APP_PATH}/id_ed25519}

is_sourced(){
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

usage(){
  [ -e /var/run/secrets/kubernetes.io/ ] && usage_ocp
  usage_host
}

usage_ocp(){
  echo "
    Add the following for OCP:

    oc create configmap reverse-tunnel \
      --from-env-file scripts/reverse_tunnel/env.sample
    oc set env deploy/reverse-tunnel \
      --from=configmap/reverse-tunnel

    oc create secret generic reverse-tunnel \
      --from-file=id_ed25519=id_ed25519 \
      --from-file=id_ed25519.pub=id_ed25519.pub
    oc set volumes deploy/reverse-tunnel \
      --add -t secret \
      --secret-name reverse-tunnel \
      --read-only \
      --name config \
      --mount-path /config
  "
  exit 0
}

usage_host(){
  echo "
    Add reverse-tunnel user:

    sudo useradd reverse-tunnel -g -m -d ${APP_PATH} -k /dev/null
    sudo chmod 770 ${APP_PATH}
    sudo usermod \$USER -a -G reverse-tunnel

    Install script and env into ${APP_PATH}:

    cp reverse_tunnel.sh ${APP_PATH}/
    cp reverse_tunnel.env.sample ${APP_PATH}/env
    cp reverse-tunnel.service /etc/systemd/system/

    Enable service:

    systemctl enable reverse-tunnel --now
    systemctl status reverse-tunnel

    journalctl -u reverse-tunnel
  "
  exit 0
}

kludge_uninstall(){
  sudo su root /bin/bash -c "
    rm /etc/systemd/system/reverse-tunnel.service
    sudo userdel reverse-tunnel -r
    sudo groupdel reverse-tunnel
  "
}

check_install(){
  # shellcheck disable=SC1090
  [ -e "${ENV_FILE}" ] && . "${ENV_FILE}"

  [ -z "${OCP_API_IP}" ] && var_unset "OCP_API_IP"
  [ -z "${OCP_APP_IP}" ] && var_unset "OCP_APP_IP"
  [ -z "${OCP_DNS_NAME}" ] && var_unset "OCP_DNS_NAME"
  [ -z "${PUBLIC_IP}" ] && var_unset "PUBLIC_IP"

  [ -z "${SSH_KEY}" ] && var_unset "SSH_KEY"
  [ -e "${SSH_KEY}" ] || gen_key

  [ "$(get_script_path)" == "${APP_PATH}" ] && return
  
  usage
}

gen_key(){
  KEY_PATH=$(dirname "${SSH_KEY}")

  echo "
    Attempting to generate a ssh key in ${KEY_PATH}
  "
  [ -d "${KEY_PATH}" ] || mkdir -p "${KEY_PATH}"
  ssh-keygen -q -P '' -t ed25519 -f "${SSH_KEY}" -C "generated@reverse-tunnel"
  cat "${SSH_KEY}"*

  return 0
}

setup_sshd(){
  echo 'GatewayPorts yes' > /etc/ssh/sshd_config.d/99-reverse-tunnel.conf
  echo 'no-agent-forwarding,no-X11-forwarding,command="echo Only for SSH Tunnel; sleep infinity" ssh-rsa AAAA...'
  echo 'PermitRootLogin prohibit-password'
}

var_unset(){
  echo "${1} env var is NOT set"
}

get_script_path(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo "${SCRIPT_DIR}"
}

kludge_info(){

  [ -z "${OCP_DNS_NAME}" ] && usage

  echo "Private DNS should resolve:

  *.apps.${OCP_DNS_NAME}  ${OCP_APP_IP}
  api.${OCP_DNS_NAME}     ${OCP_API_IP}
  "
  echo "Public DNS should resolve:

  *.apps.${OCP_DNS_NAME}  ${PUBLIC_IP}
  api.${OCP_DNS_NAME}     ${PUBLIC_IP}
  "
  
  which host || return
  echo "Checking DNS records...
  "
  host "canary-in-the-mine.apps.${OCP_DNS_NAME}"
  echo ""
  host "api.${OCP_DNS_NAME}"
}

kludge_tunnel(){
  SSH_PORT=${1:-443}

  kludge_info

  echo "
    Attempting ssh tunnel...
  "
  
  ssh -NT root@"${PUBLIC_IP}" \
    -p "${SSH_PORT}" \
    -i "${SSH_KEY}" \
    -o "ExitOnForwardFailure yes" \
    -o "ServerAliveInterval 60" \
    -o "StrictHostKeyChecking no" \
    -R 0.0.0.0:80:"${OCP_APP_IP}":80 \
    -R 0.0.0.0:443:"${OCP_APP_IP}":443 \
    -R 0.0.0.0:6443:"${OCP_API_IP}":6443 \
    -R 0.0.0.0:2222:localhost:22
}

kludge_test(){
  curl -k \
    --connect-to "${PUBLIC_IP}":443:example.apps."${OCP_DNS_NAME}":443 \
    https://example.apps."${OCP_DNS_NAME}"
}

kludge_iptables(){
  EGRESS_IP=${1:-${EGRESS_IP}}

  if [ -z "${EGRESS_IP}" ]; then
    echo "
      usage: 
        kluge_iptables 143.166.117.0/24

      usage:
        EGRESS_IP=143.166.117.0/24
        kluge_iptables
    "
    return
  fi

  iptables -t nat \
    -I PREROUTING -s "${EGRESS_IP}" -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 22
  iptables -t nat \
    -I PREROUTING -s "${EGRESS_IP}" -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 22
}

is_sourced && return

check_install
kludge_tunnel
