#!/bin/sh
# https://www.redhat.com/en/blog/customizing-oc-output-with-go-templates

observe_pod_status(){
  oc observe pods \
    --all-namespaces \
    --template '{ .status.phase }' -- ./controller.sh ${@}
}

get_all_pods_pending(){
  oc get pods \
    --all-namespaces \
    --field-selector status.phase=Pending
}

get_pod_pending_gpu(){
  [ "${3}" = "Pending" ] || return 0
  oc get -n ${1} pod ${2} \
    -o json | jq '.spec.containers[].resources.requests["nvidia.com/gpu"]'
    # -o jsonpath \
    # --template='{.spec.containers[*].resources.requests["nvidia.com/gpu"]}'
}

[ -n "${1}" ] && get_pod_pending_gpu ${@}
