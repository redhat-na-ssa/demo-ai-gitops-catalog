#!/usr/bin/bash
set -e

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
  
oc get csv \
  -n redhat-ods-operator \
  -l operators.coreos.com/rhods-operator.redhat-ods-operator \
  -o yaml | sed 's@replicas: 3@replicas: 1@' > /tmp/replace.yaml

oc replace -f /tmp/replace.yaml

}

scale_down_operator_madness
slow_restart_pods
