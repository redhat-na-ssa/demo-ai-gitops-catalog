#!/bin/bash

# https://docs.openshift.com/container-platform/4.12/backup_and_restore/application_backup_and_restore/troubleshooting.html#velero-obtaining-by-accessing-binary_oadp-troubleshooting
alias velero='oc -n openshift-adp exec deployment/velero -c velero -it -- ./velero'

_run_all_functions(){
  get_functions | grep -E -v 'argo' > /tmp/test
  
  for i in $(cat /tmp/test)
  do $i
  done
}

select_folder(){
  FOLDER="${1:-options}"
  PS3="Select by number: "
  
  [ -d "${FOLDER}" ] || return

  echo "Options"

  pushd "${FOLDER}" >/dev/null || return
  
  select selected_folder in */
  do
    [ -d "${selected_folder}" ] && break
    echo ">>> Invalid Selection <<<";
  done

  if [ -n "${selected_folder}" ]; then
    echo "Selected: ${selected_folder}"
  else
    select_folder "${FOLDER}"
  fi

  popd >/dev/null || return
}

setup_namespace(){
  NAMESPACE=${1}

  oc new-project "${NAMESPACE}" 2>/dev/null || \
    oc project "${NAMESPACE}"
}

ocp_gcp_get_key(){
  # get gcp creds
  oc -n kube-system extract secret/gcp-credentials --keys=service_account.json --to=- | jq . > scratch/service_account.json
}

lint_wordlist_reset(){
  pyspelling | sort -u | grep -Ev ' |---|/|^$' > .wordlist-md
}

lint_wordlist_sort(){
  LC_COLLATE=C sort -u < .wordlist-md > tmp
  mv tmp .wordlist-md
}

velero_create_secret(){
  VELERO_SECRET=scratch/credentials-velero

cat << YAML > "${VELERO_SECRET}"
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

[backupStorage]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}

[volumeSnapshot]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
YAML

  oc create secret generic \
    -n openshift-adp \
    "$(basename ${VELERO_SECRET})" \
    --from-file cloud="${VELERO_SECRET}"
}
