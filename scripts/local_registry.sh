#!/bin/bash

mirror_registry_local(){

# https://www.redhat.com/en/blog/openshift-private-registry
# https://distribution.github.io/distribution/about/deploying/

genpass(){
  < /dev/urandom LC_ALL=C tr -dc Aa-zZ0-9 | head -c "${1:-32}"
}

REGISTRY_HOSTNAME=${REGISTRY_HOSTNAME:-localhost}
REGISTRY_USERNAME=${REGISTRY_USERNAME:-registry}
REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-$(genpass 16)}

[ -d registry ] || mkdir -p registry

if [ ! -e registry/registry-info.txt ]; then
  echo "
    REGISTRY_HOSTNAME=${REGISTRY_HOSTNAME}
    REGISTRY_USERNAME=${REGISTRY_USERNAME}
    REGISTRY_PASSWORD=${REGISTRY_PASSWORD}
  " > registry/registry-info.txt

  # shellcheck source=/dev/null
  . registry/registry-info.txt
fi

mkdir -p registry/{config,data}

if [ ! -e "registry/config/${REGISTRY_HOSTNAME}.key" ]; then
  openssl req \
    -x509 -days 3650 \
    -newkey rsa:4096 \
    -nodes -sha256 \
    -keyout "registry/config/${REGISTRY_HOSTNAME}.key" \
    -out "registry/config/${REGISTRY_HOSTNAME}.crt" \
    -subj "/C=US/ST=NorthCarolina/L=Raleigh/O=Red Hat/OU=Sales/CN=${REGISTRY_HOSTNAME}" \
    -addext "subjectAltName = DNS:${REGISTRY_HOSTNAME}, DNS:${REGISTRY_HOSTNAME%%.*}"
fi

if [ -d /etc/pki/ca-trust/source/anchors/ ]; then
  echo "copying ${REGISTRY_HOSTNAME}.crt to /etc/pki/ca-trust/source/anchors/"
  cp "registry/config/${REGISTRY_HOSTNAME}.crt" /etc/pki/ca-trust/source/anchors/
  update-ca-trust
else
  echo ""
fi

if [ ! -e registry/config/htpasswd ]; then
  which htpasswd || dnf -y install httpd-tools
  touch registry/config/htpasswd
  htpasswd -bB registry/config/htpasswd "${REGISTRY_USERNAME}" "${REGISTRY_PASSWORD}"
fi

if [ -n "${AUTH_ON}" ]; then
  REGISTRY_AUTH_INFO="
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/config/htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM=Registry"
fi

podman rm mirror-registry --force

# shellcheck disable=SC2086
podman run -d \
  --name mirror-registry \
  --replace \
  -p 5000:5000 \
  -v ./registry/data:/var/lib/registry:z \
  -v ./registry/config:/config:z \
  -e REGISTRY_HTTP_SECRET=1559d180c2ce1acc3c41ef745535d5 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE="/config/${REGISTRY_HOSTNAME}.crt" \
  -e REGISTRY_HTTP_TLS_KEY="/config/${REGISTRY_HOSTNAME}.key" \
  ${REGISTRY_AUTH_INFO} \
    docker.io/library/registry:2

cat << FILE > /etc/systemd/system/mirror-registry.service
[Unit]
Description="Container Registry"

[Service]
Restart=always
ExecStart=/usr/bin/podman start -a mirror-registry
ExecStop=/usr/bin/podman stop -t 10 mirror-registry

[Install]
WantedBy=network-online.target
FILE

systemctl daemon-reload
systemctl enable --now mirror-registry.service
systemctl restart mirror-registry.service

if which firewall-cmd; then
  firewall-cmd --permanent --add-port=5000/tcp
  firewall-cmd --reload
fi

sleep 6
curl -u "${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}" "https://${REGISTRY_HOSTNAME}:5000/v2/_catalog"

cat << FILE > registry/registry-secret.json
"${REGISTRY_HOSTNAME}:5000": {
   "auth": "$(echo -n "${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}" | base64 -w0)"
}
FILE

cat registry/config/"${REGISTRY_HOSTNAME}".crt
cat registry/registry-info.txt
cat registry/registry-secret.json

echo "
# \$HOME/.config/containers/registries.conf

[[registry]]
location=\"${REGISTRY_HOSTNAME}\":5000
insecure=true
"
}

registry_browser(){
  # https://github.com/klausmeyer/docker-registry-browser

  podman run -d \
    --name registry-browser \
    --replace \
    -e SECRET_KEY_BASE="$(openssl rand -hex 48)" \
    -e DOCKER_REGISTRY_URL=https://registry:5000 \
    -e NO_SSL_VERIFICATION=true \
    -e ENABLE_DELETE_IMAGES=true \
    -p 8080:8080 \
      docker.io/klausmeyer/docker-registry-browser
}

AUTH_ON=${1}

mirror_registry_local