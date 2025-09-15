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

  echo -n 'Waiting for RHOAI operator.'
  until oc get -n redhat-ods-operator deployment/rhods-operator -o name 2>/dev/null
  do
    echo -n .
    sleep 5
  done; echo

  oc -n redhat-ods-operator \
    scale deployment/rhods-operator \
    --replicas=1
}

scale_down_operator_madness
slow_restart_pods
