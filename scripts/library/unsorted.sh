#!/bin/bash

# https://docs.openshift.com/container-platform/4.12/backup_and_restore/application_backup_and_restore/troubleshooting.html#velero-obtaining-by-accessing-binary_oadp-troubleshooting
alias velero='oc -n openshift-adp exec deployment/velero -c velero -it -- ./velero'

lint_wordlist_reset(){
  which pyspelling >/dev/null 2>&1 || return 0
  pyspelling | sort -u | grep -Ev ' |---|/|^$' > .wordlist-md
}

lint_wordlist_sort(){
  WORDLIST=${1:-.wordlist-md}
  LC_COLLATE=C sort -u < "${WORDLIST}" > tmp
  mv tmp "${WORDLIST}"
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

  oc get ns openshift-adp || return 0

  oc create secret generic \
    -n openshift-adp \
    "$(basename ${VELERO_SECRET})" \
    --from-file cloud="${VELERO_SECRET}"
}


registry_get_catalog(){
  REG_SRC=${1:-registry:5000}

  which jq > /dev/null || return

  curl -k -s -X GET https://"${REG_SRC}"/v2/_catalog \
    | jq '.repositories[]' \
    | sort -u

}

registry_mirror_repos(){
  REG_SRC=${1:-registry:5000}
  REG_DST=${2:-registry:5000}

  which skopeo > /dev/null || return

  registry_get_catalog "${REG_SRC}" \
    | xargs -I _ skopeo sync \
      --src docker --dest docker \
      --dest-tls-verify=false \
      "${REG_SRC}"/_ "${REG_DST}"/_
}
