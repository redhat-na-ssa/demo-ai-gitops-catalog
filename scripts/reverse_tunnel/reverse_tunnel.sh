#!/bin/bash
# NOTE: install to /usr/local/bin

ENV_FILE=/usr/local/bin/reverse_tunnel.env

usage(){
  echo "
    Install script and env into /usr/local/bin

    cp reverse_tunnel.sh /usr/local/bin/
    cp reverse_tunnel.env /usr/local/bin/
    cp reverse-tunnel.service /etc/systemd/system/

    systemctl enable reverse-tunnel --now
    systemctl status reverse-tunnel

    journalctl -u reverse-tunnel
  "
  exit 0
}

get_script_path(){
  SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
  echo "${SCRIPT_DIR}"
}

check_install(){
  [ "$(get_script_path)" == "/usr/local/bin" ] && usage
}

# shellcheck disable=SC1090
[ -e "${ENV_FILE}" ] && . "${ENV_FILE}"

[ -z "${PUBLIC_IP}" ] && usage
[ -z "${EGRESS_IP}" ] && usage
[ -z "${OCP_API_IP}" ] && usage
[ -z "${OCP_APP_IP}" ] && usage
[ -z "${OCP_DNS_NAME}" ] && usage


kludge_tunnel(){
  echo "Setup your private dns to resolve:

  *.apps.${OCP_DNS_NAME}  ${OCP_APP_IP}
  api.${OCP_DNS_NAME}     ${OCP_API_IP}
  "
  echo "Setup your public dns to resolve:

  *.apps.${OCP_DNS_NAME}  ${PUBLIC_IP}
  api.${OCP_DNS_NAME}     ${PUBLIC_IP}
  "

  ssh -NT -p 443 \
    root@"${PUBLIC_IP}" \
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

kludge_tunnel
