#!/bin/bash
SERVER="localhost:8080"

oc proxy -p 8080 &
sleep 3

APIS=$(curl -s "${SERVER}/apis" | jq -r '[.groups | .[].name] | join(" ")')

# do core resources first, which are at a separate api location
k8s_api_dump_core(){
  api="core"
  curl -s "${SERVER}/api/v1" | \
    jq -r --arg api "$api" \
    '.resources | .[] | "\($api) \(.name): [ \(.verbs | join(",")) ]"'
}
# now do non-core resources
k8s_api_dump_noncore(){
  for api in ${APIS}; do
    version=$(curl -s "$SERVER/apis/${api}" | jq -r '.preferredVersion.version')
    curl -s "${SERVER}/apis/${api}/${version}" | \
      jq -r --arg api "$api" \
      '.resources | .[]? | "\($api) \(.name): [ \(.verbs | join(",")) ]"'
  done

  killall 'oc'
}

k8s_api_dump_core
k8s_api_dump_noncore
