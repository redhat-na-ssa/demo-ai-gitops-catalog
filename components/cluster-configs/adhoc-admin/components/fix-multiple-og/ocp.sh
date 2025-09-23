#!/bin/bash
# shellcheck disable=SC2120

# See https://github.com/redhat-na-ssa/demo-ai-gitops-catalog
# FUNCTIONS='
# ocp_fix_duplicate_operator_groups
# '

# for function in ${FUNCTIONS}
# do
#   function_extract $function scripts/library/ocp*.sh >> tmp
#   echo >> tmp
# done

ocp_fix_duplicate_operator_groups(){
  for ns in $(oc get og -A | awk '{print $1}' | uniq -d)
  do
    oc -n "${ns}" \
      get og -o name | \
        tail -n+2 | \
        xargs oc -n "${ns}" delete

    # oc -n "${ns}" \
    #   delete pod --all
  done
}
