#!/bin/sh

k8s_null_finalizers(){
  OBJ=${1}
  [ -z ${OBJ+x} ] && return 1

  NAMESPACE=${NAMESPACE:-$(oc project -q)}

  kubectl \
  patch "${OBJ}" \
  -n "${NAMESPACE}" \
  --type=merge \
  -p '{"metadata":{"finalizers":null}}'
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

k8s_null_finalizers_for_all_resource_instances(){
  RESOURCE=${1}
  [ -z ${RESOURCE+x} ] && return 1

  NAMESPACE=${NAMESPACE:-$(oc project -q)}

  for OBJ in $(oc -n "${NAMESPACE}" get "${RESOURCE}" -o name)
  do
    k8s_null_finalizers "${OBJ}"
  done
}

k8s_ns_delete_most_resources_force(){
    NAMESPACE=${1:-sandbox}

    for i in $(k8s_get_most_api_resources)
    do
      echo "Resource:" "${i}"
      k8s_null_finalizers_for_all_resource_instances "${i}"
      kubectl -n "${NAMESPACE}" \
        delete "${i}" \
        --all
    done
}

k8s_ns_delete_most_resources_force "${TARGET_NS}"
