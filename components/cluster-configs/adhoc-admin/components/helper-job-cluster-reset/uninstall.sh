#!/bin/bash
# shellcheck disable=SC2120,SC2129

TIMEOUT=60
OCP_VER=4.16
OCP_DEFAULTS=ocp-defaults-${OCP_VER}.txt

cd "$(dirname "$0")" && pwd

self_destruct(){
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

reset_machine_sets(){
  GPU_MACHINE_SET=$(oc -n openshift-machine-api get machinesets -o name | grep -E -v 'worker')
  for set in ${GPU_MACHINE_SET}
  do
    oc -n openshift-machine-api delete "$set"
  done
}

delete_list(){
  LIST_FILE=${1}
  xargs -l oc delete < "${LIST_FILE}"
}

get_unwanted_obj(){
  OBJ=${1}
  DEFAULT_LIST=${2}

  TMP_FILE="/tmp/${OBJ}.txt"

  oc get "${OBJ}" -o name > "${TMP_FILE}"

  while read -r obj
  do
    [ -z "${obj}" ] && return
    sed -i "/${obj##*/}$/d" "${TMP_FILE}"
  done < <(grep "${OBJ}" < "${DEFAULT_LIST}")
}

get_crs(){
  get_unwanted_obj crd "${OCP_DEFAULTS}"

  for obj in $(< "${TMP_FILE}")
  do
    CR=$(oc get "${obj}" -A -o go-template='{{range .items}}'"${obj}"'/{{.metadata.name}}{{if .metadata.namespace}} {{.metadata.namespace}}{{end}}{{"\n"}}{{end}}')
    [ -n "${CR// }" ] && echo "${CR}"
  done
}

reset_crs(){
  while read -r obj ns
  do
    k8s_null_finalizers "${obj}" "${ns}"
  done < <(get_crs)
}

reset_webhooks(){
  get_unwanted_obj validatingwebhookconfiguration "${OCP_DEFAULTS}"
  delete_list "${TMP_FILE}"

  get_unwanted_obj mutatingwebhookconfiguration "${OCP_DEFAULTS}"
  delete_list "${TMP_FILE}"
}

reset_misc(){
  k8s_null_finalizers knativeservings.operator.knative.dev/knative-serving knative-serving
  oc -n knative-serving delete knativeservings.operator.knative.dev knative-serving
  
  oc -n openshift-operators delete deploy devworkspace-webhook-server

  oc delete consoleplugin console-plugin-nvidia-gpu
}

reset_namespaces(){
  get_unwanted_obj namespace "${OCP_DEFAULTS}"
  delete_list "${TMP_FILE}"
}

reset_csvs(){

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

  reset_webhooks
  reset_crs
  reset_csvs
  reset_misc
  reset_machine_sets

  # oc delete --ignore-not-found=true --timeout=0s --force -k https://github.com/adrezni/cluster-jump-start/demos/default

  delete_crds
  reset_namespaces

  echo "end: uninstall"
}

get_ocp_defaults(){
  OCP_DEFAULTS=${OCP_DEFAULTS:-ocp-defaults-${OCP_VER:-4.16}.txt}
  oc get crd -o name | sort -u > "${OCP_DEFAULTS}"
  oc get csv -o name -A | sort -u >> "${OCP_DEFAULTS}"
  oc get ns -o name | sort -u >> "${OCP_DEFAULTS}"
  oc get validatingwebhookconfiguration,mutatingwebhookconfiguration -o name | sort -u >> "${OCP_DEFAULTS}"

  sort -u "${OCP_DEFAULTS}" > tmp
  mv tmp "${OCP_DEFAULTS}"
}

# get_ocp_defaults
uninstall_demo
# self_destruct
