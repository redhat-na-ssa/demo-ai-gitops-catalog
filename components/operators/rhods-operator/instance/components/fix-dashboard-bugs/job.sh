#!/usr/bin/bash
set -e

TIMEOUT_SECONDS=60

restart_pods(){
  oc -n redhat-ods-applications \
    delete pods \
    -l deployment=rhods-dashboard
}

fix_dashboard_bugs(){
  sleep "${TIMEOUT_SECONDS}"
  restart_pods
}

scale_down_dashboard_madness(){
  oc -n redhat-ods-applications \
    scale deployment/rhods-dashboard \
    --replicas=2
}

scale_down_dashboard_madness
fix_dashboard_bugs
