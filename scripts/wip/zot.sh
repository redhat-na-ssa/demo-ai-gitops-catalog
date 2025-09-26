#!/bin/sh

zot_config(){

cat << JSON > config.json
{
  "distSpecVersion": "1.1.1",
  "storage": {
    "rootDirectory": "/var/lib/registry"
  },
  "http": {
    "address": "0.0.0.0",
    "port": "8080",
    "compat": [
      "docker2s2"
    ],
    "tls": {
      "cert": "/etc/zot/registry.crt",
      "key": "/etc/zot/registry.key"
    }
  },
  "log": {
    "level": "info"
  },
  "extensions": {
    "search": {
      "cve": {
        "updateInterval": "2h"
      }
    },
    "ui": {
      "enable": true
    }
  }
}
JSON

}

zot_run(){

podman run -d \
  --replace \
  --name mirror_registry \
  --user 1000 \
  -p 5000:5000 \
  -v /srv/registry/config:/etc/zot:z \
  -v /srv/registry/data:/var/lib/registry:z \
    ghcr.io/project-zot/zot:latest
}

get_repos(){
  REG_SRC=${1:-registry:5000}

  curl -k -s -X GET https://"${REG_SRC}"/v2/_catalog \
    | jq '.repositories[]' \
    | sort -u

}

mirror_repos(){
  REG_SRC=${1:-registry:5000}
  REG_DST=${2:-registry:8080}

  get_repos "${REG_SRC}" \
    | xargs -I _ skopeo sync \
      --src docker --dest docker \
      --dest-tls-verify=false \
      "${REG_SRC}"/_ "${REG_DST}"/_

}
