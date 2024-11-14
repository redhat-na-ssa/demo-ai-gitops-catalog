#!/bin/bash

TIMEOUT=60
DEFAULT_CRDS=ocp-default-crds-4.16.txt
UNWANTED_CRDS=/tmp/unwanted-crds.txt

cd "$(dirname "$0")" && pwd

self_distruct(){
  NAMESPACE=${1:-adhoc-admin}
  [ -z "${NAMESPACE}" ] && return
  echo "
    engaging self cleaning...
    removing project: ${NAMESPACE} in ${TIMEOUT}s
  "
  
  sleep "${TIMEOUT}"
  oc delete project "${NAMESPACE}"
}

k8s_null_finalizers(){
  OBJ=${1}
  [ -z "${OBJ}" ] && return
  NS=${2}
  [ -z "${NS}" ] || ARGS="-n ${NS}"

  # shellcheck disable=SC2086
  kubectl \
    patch "${OBJ}" \
    ${ARGS} \
    --type=merge \
    -p '{"metadata":{"finalizers":null}}'
    # --type="json" \
    # -p '[{"op": "remove", "path":"/metadata/finalizers"}]'

  # shellcheck disable=SC2086
  kubectl delete ${ARGS} "${OBJ}"
}

delete_namespaces(){
  xargs -l oc delete ns < namespaces.txt
}

delete_machine_sets(){
  GPU_MACHINE_SET=$(oc -n openshift-machine-api get machinesets -o name | grep -E -v 'worker')
  for set in ${GPU_MACHINE_SET}
  do
    oc -n openshift-machine-api delete "$set"
  done
}

get_unwanted_crds(){
  oc get crds -o name | sed 's/.*\///' > "${UNWANTED_CRDS}"

  for obj in $(< "${DEFAULT_CRDS}")
  do
    sed -i "/${obj}/d" "${UNWANTED_CRDS}"
  done
}

get_crs(){
  get_unwanted_crds

  for obj in $(< "${UNWANTED_CRDS}")
  do
    CR=$(oc get "${obj}" -A -o go-template='{{range .items}}'"${obj}"'/{{.metadata.name}}{{if .metadata.namespace}} {{.metadata.namespace}}{{end}}{{"\n"}}{{end}}')
    [ -n "${CR// }" ] && echo "${CR}"
  done
}

delete_crs(){
  while read -r obj ns
  do
    k8s_null_finalizers "${obj}" "${ns}"
  done < <(get_crs)
}

delete_crds(){
  xargs -l oc delete crds < "${UNWANTED_CRDS}"
}

delete_webhooks(){
  WEBHOOK=$(oc get validatingwebhookconfiguration,mutatingwebhookconfiguration -o name | grep -E 'tekton.dev|devfile|maistra')
  for set in ${WEBHOOK}
  do
    oc -n openshift-machine-api delete "$set"
  done
}

delete_misc(){
  oc -n knative-serving delete knativeservings.operator.knative.dev knative-serving
  oc -n openshift-operators delete deploy devworkspace-webhook-server

  oc delete consoleplugin console-plugin-nvidia-gpu
}

delete_csvs(){

  CSVS=(
    operators.coreos.com/authorino-operator.openshift-operators
    operators.coreos.com/devworkspace-operator.openshift-operators
    operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator
    operators.coreos.com/openshift-pipelines-operator-rh.openshift-operators
    operators.coreos.com/nfd.openshift-nfd
    operators.coreos.com/rhods-operator.redhat-ods-operator
    operators.coreos.com/servicemeshoperator.openshift-operators
    operators.coreos.com/serverless-operator.openshift-serverless
    operators.coreos.com/web-terminal.openshift-operators
  )

  # shellcheck disable=SC2068
  for csv in ${CSVS[@]}
  do
    # set csv to cleanup
    oc get csv -A -l "${csv}" -o yaml | \
      sed 's/^    enabled: false/    enabled: true/' | \
        oc apply -f -
    sleep 3
    oc delete csv -A -l "${csv}"
  done
}

uninstall_demo(){

  echo "start: uninstall"

  delete_webhooks
  delete_crs
  delete_csvs
  delete_machine_sets
  delete_misc

  oc delete --ignore-not-found=true --timeout=0s --force -k https://github.com/adrezni/cluster-jump-start/demos/default

  delete_crds
  delete_namespaces

  echo "end: uninstall"
}

uninstall_demo
self_distruct
