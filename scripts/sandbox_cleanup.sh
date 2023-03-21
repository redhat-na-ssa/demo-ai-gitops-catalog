#!/bin/sh

# get all resources
get_api_resources() {
    oc api-resources \
      --verbs=list \
      --namespaced \
      -o name | \
        grep -v "events.events.k8s.io" | \
        grep -v "events" | \
        sort | uniq
}

get_most_api_resources() {
    oc api-resources \
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

oc_get_all() {
NAMESPACE=${1:-$(oc project -q)}
echo "${NAMESPACE}"
sleep 3

for i in $(get_api_resources)
do
    echo "Resource:" "${i}"
    oc -n "${NAMESPACE}" \
      get "${i}" \
      --ignore-not-found
done
}

oc_delete_most() {
NAMESPACE=${1:-sandbox}
echo "${NAMESPACE}"
sleep 3

for i in $(get_most_api_resources)
do
    echo "Resource:" "${i}"
    oc -n "${NAMESPACE}" \
      delete "${i}" \
      --all
done
}
