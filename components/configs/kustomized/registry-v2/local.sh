#!/usr/bin/env bash

mirror_registry_local(){

# https://www.redhat.com/en/blog/openshift-private-registry
# https://distribution.github.io/distribution/about/deploying/

genpass(){
  < /dev/urandom LC_ALL=C tr -dc Aa-zZ0-9 | head -c "${1:-32}"
}

REGISTRY_HOSTNAME=localhost
REGISTRY_USERNAME=registry
REGISTRY_PASSWORD=${REGISTRY_PASSWORD:-$(genpass 16)}

mkdir -p registry/{config,data}

if [ ! -e registry/config/${REGISTRY_HOSTNAME}.key ]; then
  openssl req \
    -x509 -days 3650 \
    -newkey rsa:4096 \
    -nodes -sha256 \
    -keyout registry/config/${REGISTRY_HOSTNAME}.key \
    -out registry/config/${REGISTRY_HOSTNAME}.crt \
    -subj "/C=US/ST=NorthCarolina/L=Raleigh/O=Red Hat/OU=Sales/CN=${REGISTRY_HOSTNAME}" \
    -addext "subjectAltName = DNS:${REGISTRY_HOSTNAME}"
fi

cp registry/config/${REGISTRY_HOSTNAME}.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust

if [ ! -e registry/config/htpasswd ]; then
  dnf -y install httpd-tools
  touch registry/config/htpasswd
  htpasswd -bB registry/config/htpasswd "${REGISTRY_USERNAME}" "${REGISTRY_PASSWORD}"
fi

podman rm mirror-registry --force
podman run -d \
  --name mirror-registry \
  -p 5000:5000 \
  -v ./registry/data:/var/lib/registry:z \
  -v ./registry/config:/config:z \
  -e REGISTRY_AUTH=htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/config/htpasswd \
  -e REGISTRY_AUTH_HTPASSWD_REALM=Registry \
  -e REGISTRY_HTTP_SECRET=1559d180c2ce1acc3c41ef745535d5 \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/config/${REGISTRY_HOSTNAME}.crt \
  -e REGISTRY_HTTP_TLS_KEY=/config/${REGISTRY_HOSTNAME}.key \
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

firewall-cmd --permanent --add-port=5000/tcp
firewall-cmd --reload

sleep 6
curl -u "${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}" https://${REGISTRY_HOSTNAME}:5000/v2/_catalog

cat << FILE > registry/registry-secret.json
"${REGISTRY_HOSTNAME}:5000": {
   "auth": "$(echo -n "${REGISTRY_USERNAME}:${REGISTRY_PASSWORD}" | base64 -w0)"
}
FILE

if [ ! -e registry-info.txt ]; then
  echo "
    REGISTRY_HOSTNAME=${REGISTRY_HOSTNAME}
    REGISTRY_USERNAME=${REGISTRY_USERNAME}
    REGISTRY_PASSWORD=${REGISTRY_PASSWORD}
  " > registry/registry-info.txt
else
  return
fi
cat registry/config/${REGISTRY_HOSTNAME}.crt
cat registry/registry-info.txt
cat registry/registry-secret.json
}

mirror_registry_local