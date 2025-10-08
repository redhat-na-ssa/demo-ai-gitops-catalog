#!/bin/bash

ocp_gcp_get_key(){
  which jq >/dev/null 2>&1 || return
  oc -n kube-system extract secret/gcp-credentials --keys=service_account.json --to=- | jq . > scratch/service_account.json
}

