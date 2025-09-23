#!/usr/bin/bash
set -e

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
