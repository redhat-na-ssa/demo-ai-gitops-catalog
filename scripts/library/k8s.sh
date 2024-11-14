#!/bin/bash
# shellcheck disable=SC2120,SC2119

which oc >/dev/null && alias kubectl=oc

k8s_wait_for_crd(){
  CRD=${1:-projects.config.openshift.io}
  printf "Waiting for CRD %s." "${CRD}"
  until kubectl get crd "${CRD}" >/dev/null 2>&1
    do sleep 1
    printf .
  done
}

k8s_null_finalizers(){
  OBJ=${1}
  [ -z "${OBJ}" ] && return

  NAMESPACE=${NAMESPACE:-$(oc project -q)}

  kubectl \
    patch "${OBJ}" \
    -n "${NAMESPACE}" \
    --type=merge \
    -p '{"metadata":{"finalizers":null}}'

  # oc patch "${OBJ}" \
  #   --type="json" \
  #   -p '[{"op": "remove", "path":"/metadata/finalizers"}]'
}

k8s_null_finalizers_for_all_resource_instances(){
  RESOURCE=${1}
  [ -z "${RESOURCE}" ] && return

  NAMESPACE=${NAMESPACE:-$(oc project -q)}

  for OBJ in $(oc -n "${NAMESPACE}" get "${RESOURCE}" -o name)
  do
    k8s_null_finalizers "${OBJ}"
  done
}

# get all resources
k8s_get_api_resources(){
    kubectl api-resources \
      --verbs=list \
      --namespaced \
      -o name | \
        grep -v "events.events.k8s.io" | \
        grep -v "events" | \
        sort | uniq
}

k8s_get_most_api_resources(){
    kubectl api-resources \
        --verbs=list \
        --namespaced \
        -o name | \
        grep -v "events.events.k8s.io" | \
        grep -v "events" | \
        grep -v "packagemanifests" | \
        grep -v "operator.openshift.io" | \
        grep -v "operators.coreos.com" | \
        grep -v "authorization.openshift.io" | \
        grep -v "serviceaccount" | \
        grep -v "rbac" | \
        sort | uniq
}

k8s_ns_get_resources(){
  NAMESPACE=${1:-sandbox}

  for i in $(k8s_get_api_resources)
  do
    echo "Resource:" "${i}"
    kubectl -n "${NAMESPACE}" \
    get "${i}" \
    --ignore-not-found
  done
}

k8s_ns_delete_most_resources(){
  NAMESPACE=${1}

  if [ -z "${NAMESPACE}" ]; then
    echo "usage: k8s_ns_delete_most_resources < namespace >"
    return
  fi

  for i in $(k8s_get_most_api_resources)
  do
    echo "Resource:" "${i}"
    kubectl -n "${NAMESPACE}" \
      delete "${i}" \
      --all
  done
}

k8s_ns_delete_most_resources_force(){
  NAMESPACE=${1}

  if [ -z "${NAMESPACE}" ]; then
    echo "usage: k8s_ns_delete_most_resources_force < namespace >"
    return
  fi

  for i in $(k8s_get_most_api_resources)
  do
    echo "Resource:" "${i}"
    k8s_null_finalizers_for_all_resource_instances "${i}"
    kubectl -n "${NAMESPACE}" \
      delete "${i}" \
      --all
  done
}

k8s_api_proxy(){
  ACTION=${1:-start}
  PORT=${2:-8001}

  if [ "${ACTION}" = "start" ]; then
    echo "k8s api proxy: starting..."
    kubectl proxy -p "${PORT}" &
    API_PROXY_PID=$!
    sleep 3
  else
    echo "k8s api proxy: stopping..."
    kill "${API_PROXY_PID}"
  fi
}

# do core resources first, which are at a separate api location
k8s_api_dump_core(){
  SERVER=${1:-http://localhost:8001}
  api="core"
  curl -s "${SERVER}/api/v1" | \
    jq -r --arg api "$api" \
    '.resources | .[] | "\($api) \(.name): [ \(.verbs | join(",")) ]"'
}

# now do non-core resources
k8s_api_dump_noncore(){
  SERVER=${1:-http://localhost:8001}
  APIS=$(curl -s "${SERVER}/apis" | jq -r '[.groups | .[].name] | join(" ")')

  for api in ${APIS}; do
    version=$(curl -s "$SERVER/apis/${api}" | jq -r '.preferredVersion.version')
    curl -s "${SERVER}/apis/${api}/${version}" | \
      jq -r --arg api "$api" \
      '.resources | .[]? | "\($api) \(.name): [ \(.verbs | join(",")) ]"'
  done
}

k8s_api_dump_resources(){
  k8s_api_proxy start
  k8s_api_dump_core
  k8s_api_dump_noncore
  k8s_api_proxy stop
}

k8s_delete_extended_resource_on_all_nodes(){
  RESOURCE_NAME=${1:-devices.custom.io~1tpm}

  echo "Attempting to delete extended resource ${RESOURCE_NAME}..."

  k8s_api_start_proxy

  for node in $(kubectl get nodes -o name | sed 's/node.//')
  do
    echo "modifying: ${node}"
    curl "http://localhost:8001/api/v1/nodes/${node}/status" \
      --header "Content-Type: application/json-patch+json" \
      --request PATCH \
      --data '[{"op": "remove", "path": "/status/capacity/'"${RESOURCE_NAME}"'"}]' \
      --no-fail
      
  done

  echo "k8s api proxy: stopping..."
  kill "${API_PROXY_PID}"
}
