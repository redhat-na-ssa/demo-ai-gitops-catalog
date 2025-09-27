#!/bin/bash
# set -x

# https://www.redhat.com/en/blog/openshift-private-registry
# https://distribution.github.io/distribution/about/deploying/

genpass(){
  < /dev/urandom LC_ALL=C tr -dc Aa-zZ0-9 | head -c "${1:-32}"
}

registry_get_catalog(){
  curl -k -u "${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}" "https://${REGISTRY_HOSTNAME}:5000/v2/_catalog"
}

registry_init(){

  REGISTRY_HOSTNAME=${REGISTRY_HOSTNAME:-localhost}
  REGISTRY_USERNAME=${REGISTRY_USERNAME:-registry}
  REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-$(genpass 16)}

  [ -d registry/data/zot ] || mkdir -p registry/{config,data/zot}

  if [ ! -e registry/registry-info.txt ]; then
    echo "
      REGISTRY_HOSTNAME=${REGISTRY_HOSTNAME}
      REGISTRY_USERNAME=${REGISTRY_USERNAME}
      REGISTRY_PASSWORD=${REGISTRY_PASSWORD}
    " > registry/registry-info.txt
  else
    # shellcheck source=/dev/null
    . registry/registry-info.txt
  fi
}

registry_create_cert(){
  if [ ! -e "registry/config/${REGISTRY_HOSTNAME}.key" ]; then
    openssl req \
      -x509 -days 3650 \
      -newkey rsa:4096 \
      -nodes -sha256 \
      -keyout "registry/config/${REGISTRY_HOSTNAME}.key" \
      -out "registry/config/${REGISTRY_HOSTNAME}.crt" \
      -subj "/C=US/ST=NorthCarolina/L=Raleigh/O=Red Hat/OU=Sales/CN=${REGISTRY_HOSTNAME}" \
      -addext "subjectAltName = DNS:localhost, DNS:${REGISTRY_HOSTNAME}, DNS:${REGISTRY_HOSTNAME%%.*}"
  fi

  if [ -d /etc/pki/ca-trust/source/anchors/ ]; then
    [ -e /etc/pki/ca-trust/source/anchors/"${REGISTRY_HOSTNAME}.crt" ] && return
    echo "copying ${REGISTRY_HOSTNAME}.crt to /etc/pki/ca-trust/source/anchors/"
    cp -u "registry/config/${REGISTRY_HOSTNAME}.crt" /etc/pki/ca-trust/source/anchors/
    update-ca-trust
  else
    echo ""
  fi
}

registry_create_auth(){
  if [ ! -e registry/config/htpasswd ]; then
    which htpasswd || dnf -y install httpd-tools
    touch registry/config/htpasswd
    htpasswd -bB registry/config/htpasswd "${REGISTRY_USERNAME}" "${REGISTRY_PASSWORD}"
  fi
}

registry_create_systemd(){

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

}

registry_zot_config(){

  # https://github.com/project-zot/zot

cat << JSON > registry/config/config.json
{
  "storage": {
    "rootDirectory": "/var/lib/registry",
    "commit": false,
    "dedupe": true,
    "gc": true,
    "gcDelay": "1h",
    "gcInterval": "24h"
  },
  "http": {
    "address": "0.0.0.0",
    "port": "5000",
    "tls": {
      "cert": "/etc/zot/${REGISTRY_HOSTNAME}.crt",
      "key": "/etc/zot/${REGISTRY_HOSTNAME}.key"
    },
JSON

if [ -n "${AUTH_ON}" ]; then
cat << JSON >> registry/config/config.json
    "auth": {
      "htpasswd": {
        "path": "/etc/zot/htpasswd"
      },
      "failDelay": 5
    },
    "realm": "zot",
JSON
fi

cat << JSON >> registry/config/config.json
    "compat": ["docker2s2"]
  },
  "log": {
    "level": "info",
    "output": "/var/lib/registry/zot.log",
    "audit": "/var/lib/registry/zot-audit.log"
  },
  "extensions": {
JSON

if true; then

touch registry/config/sync-auth.json

cat << JSON >> registry/config/config.json
		"sync": {
      "enable": true,
      "credentialsFile": "/etc/zot/sync-auth.json",
      "registries": [
      	{
          "urls": ["https://index.docker.io"],
          "onDemand": true,
          "tlsVerify": true,
          "maxRetries": 5,
          "retryDelay": "30s"
				},
        {
          "urls": ["https://k8s.gcr.io"],
          "content": [
            {
              "prefix": "**", 
              "destination": "/k8s-cache"
            }
          ],
          "onDemand": true,
          "tlsVerify": true,
          "maxRetries": 5,
          "retryDelay": "30s"
				},
        {
          "urls": ["https://quay.io"],
          "content": [
            {
              "prefix": "**", 
              "destination": "/quay-cache"
            }
          ],
          "onDemand": true,
          "tlsVerify": true,
          "maxRetries": 5,
          "retryDelay": "30s"
				},
        {
          "urls": ["https://ghcr.io"],
          "content": [
            {
              "prefix": "**", 
              "destination": "/ghcr-cache"
            }
          ],
          "onDemand": true,
          "tlsVerify": true,
          "maxRetries": 5,
          "retryDelay": "30s"
				}
      ]
    },
JSON
fi

cat << JSON >> registry/config/config.json
    "search": {
      "enable": true,
      "cve": {
        "updateInterval": "4h"
      }
    },
    "ui": {
      "enable": true
    },
    "mgmt": {
      "enable": true
    }
  }
}
JSON
}

registry_zot_run(){

  registry_zot_config

  podman run -d \
    --replace \
    --name mirror-registry \
    --user 1000 \
    -p 5000:5000 \
    -v ./registry/config:/etc/zot:z \
    -v ./registry/data/zot:/var/lib/registry:z \
      ghcr.io/project-zot/zot:latest
}

registry_v2_run(){
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
    -e REGISTRY_HTTP_SECRET="$(openssl rand -hex 48)" \
    -e REGISTRY_HTTP_TLS_CERTIFICATE="/config/${REGISTRY_HOSTNAME}.crt" \
    -e REGISTRY_HTTP_TLS_KEY="/config/${REGISTRY_HOSTNAME}.key" \
    ${REGISTRY_AUTH_INFO} \
      docker.io/library/registry:2
}

local_registry_mirror(){

registry_create_cert
registry_create_auth

if which firewall-cmd; then
  firewall-cmd --permanent --add-port=5000/tcp
  firewall-cmd --reload
fi

# registry_v2_run
registry_zot_run

registry_create_systemd

cat << FILE > registry/registry-secret.json
"${REGISTRY_HOSTNAME}:5000": {
   "auth": "$(echo -n "${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}" | base64 -w0)"
}
FILE

echo "
# \$HOME/.config/containers/registries.conf

[[registry]]
location=\"${REGISTRY_HOSTNAME}\":5000
# insecure=true

[[registry]]
prefix = "quay.io"
location = "quay.io"
[[registry.mirror]]
location = "registry:5000/quay-cache"

[[registry]]
prefix = "k8s.gcr.io"
location = "k8s.gcr.io"
[[registry.mirror]]
location = "registry:5000/k8s-cache"

[[registry]]
prefix = "ghcr.io"
location = "ghcr.io"
[[registry.mirror]]
location = "registry:5000/ghcr-cache"

[[registry]]
prefix = "docker.io"
location = "registry:5000"

" > registry/registries.conf

cat registry/config/"${REGISTRY_HOSTNAME}".crt
cat registry/registry-info.txt
# cat registry/registry-secret.json
# cat registry/registries.conf

}

local_registry_browser_run(){
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

registry_init
local_registry_mirror
local_registry_browser_run
