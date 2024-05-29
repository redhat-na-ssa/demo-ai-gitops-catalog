#!/bin/bash

ENV_FILE=${ENV_FILE:-/etc/reverse_tunnel/reverse_tunnel.env}
SSH_KEY=${SSH_KEY:-/etc/reverse_tunnel/id_ed25519}

is_sourced(){
  if [ -n "$ZSH_VERSION" ]; then
      case $ZSH_EVAL_CONTEXT in *:file:*) return 0;; esac
  else  # Add additional POSIX-compatible shell names here, if needed.
      case ${0##*/} in dash|-dash|bash|-bash|ksh|-ksh|sh|-sh) return 0;; esac
  fi
  return 1  # NOT sourced.
}

gen_key(){
  echo "
    Attempting to generate a ssh key...
    WARNING: This key pair will be lost if the container is restarted!!!
  "
  [ -d $(dirname "${SSH_KEY}") ] || mkdir -p $(dirname "${SSH_KEY}")
  ssh-keygen -q -P '' -t ed25519 -f "${SSH_KEY}" -C "generated@container"
  cat "${SSH_KEY}"*

  return 0
}

var_unset(){
  echo "
    ${1} env var is NOT set

    oc create configmap reverse-tunnel --from-env-file scripts/reverse_tunnel/reverse_tunnel.env.sample
  "
  exit 0
}

usage_host(){
  echo "
    Install script and env into /usr/local/bin

    cp reverse_tunnel.sh /usr/local/bin/
    cp reverse_tunnel.env.sample /usr/local/bin/reverse_tunnel.env
    cp reverse-tunnel.service /etc/systemd/system/

    systemctl enable reverse-tunnel --now
    systemctl status reverse-tunnel

    journalctl -u reverse-tunnel
  "
  exit 0
}

run_app(){
  echo "
    running in a container
  "
  tunnel_info
  kludge_tunnel
  sleep infinity
}

get_script_path(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo "${SCRIPT_DIR}"
}

check_install(){
  # shellcheck disable=SC1090
  [ -e "${ENV_FILE}" ] && . "${ENV_FILE}"

  [ -z "${SSH_KEY}" ] && var_unset "SSH_KEY"
  [ -e "${SSH_KEY}" ] || gen_key

  [ -z "${PUBLIC_IP}" ] && var_unset "PUBLIC_IP"
  [ -z "${EGRESS_IP}" ] && var_unset "EGRESS_IP"
  [ -z "${OCP_API_IP}" ] && var_unset "OCP_API_IP"
  [ -z "${OCP_APP_IP}" ] && var_unset "OCP_APP_IP"
  [ -z "${OCP_DNS_NAME}" ] && var_unset "OCP_DNS_NAME"

  [ "$(get_script_path)" == "/app" ] && run_app
  [ "$(get_script_path)" == "/usr/local/bin" ] || usage_host
}

tunnel_info(){
  echo "Private DNS should resolve:

  *.apps.${OCP_DNS_NAME}  ${OCP_APP_IP}
  api.${OCP_DNS_NAME}     ${OCP_API_IP}
  "
  echo "Public DNS should resolve:

  *.apps.${OCP_DNS_NAME}  ${PUBLIC_IP}
  api.${OCP_DNS_NAME}     ${PUBLIC_IP}
  "
  
  which host || return
  host "ping.apps.${OCP_DNS_NAME}"
  host "api.${OCP_DNS_NAME}"
}

kludge_tunnel(){
  
  tunnel_info

  ssh -NT -p 443 \
    root@"${PUBLIC_IP}" \
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
  iptables -t nat \
    -I PREROUTING -s "${EGRESS_IP}" -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 22
  iptables -t nat \
    -I PREROUTING -s "${EGRESS_IP}" -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 22
}

is_sourced && return

check_install
kludge_tunnel
