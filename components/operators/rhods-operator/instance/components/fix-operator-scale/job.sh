#!/usr/bin/bash
set -ex

TIMEOUT_SECONDS=60

restart_pods(){
  oc -n redhat-ods-operator \
    delete pods \
    -l name=rhods-operator
}

slow_restart_pods(){
  sleep "${TIMEOUT_SECONDS}"
  restart_pods
}

scale_down_operator_madness(){

  echo -n 'Waiting for RHOAI csv.'
  until oc get -n redhat-ods-operator -l operators.coreos.com/rhods-operator.redhat-ods-operator csv -o name 2>/dev/null
  do
    echo -n .
    sleep 5
  done; echo

cat << YAML > /tmp/patch.yaml
spec:
  install:
    spec:
      deployments:
        - name: rhods-operator
          spec:
            replicas: 1
            selector:
              matchLabels:
                name: rhods-operator
            template:
              metadata:
                annotations:
                  kubectl.kubernetes.io/default-container: rhods-operator
                labels:
                  name: rhods-operator
YAML

CSV=$(oc get -n redhat-ods-operator -l operators.coreos.com/rhods-operator.redhat-ods-operator csv -o name | head -n1)

  oc -n redhat-ods-operator \
    patch "${CSV}" \
    --type=merge --patch "$(cat /tmp/patch.yaml)"

}

scale_down_operator_madness
slow_restart_pods
