#!/bin/bash

# https://docs.openshift.com/container-platform/4.12/backup_and_restore/application_backup_and_restore/troubleshooting.html#velero-obtaining-by-accessing-binary_oadp-troubleshooting
alias velero='oc -n openshift-adp exec deployment/velero -c velero -it -- ./velero'

genpass(){
  < /dev/urandom LC_ALL=C tr -dc _A-Z-a-z-0-9 | head -c "${1:-32}"
}

create_kubeadmin(){
  PASS=${1:-$(genpass 5 )-$(genpass 5 )-$(genpass 5 )-$(genpass 5 )}

  which htpasswd >/dev/null || return

  HTPASSWD=$(htpasswd -nbB -C10 null "${PASS}")
  HASH=${HTPASSWD##*:}

  echo "
  PASSWORD: ${PASS}
  HASH:     ${HASH}

  oc apply -f scratch/kubeadmin.yaml
  "

cat << YAML > scratch/kubeadmin.yaml
kind: Secret
apiVersion: v1
metadata:
  name: kubeadmin
  namespace: kube-system
stringData:
  kubeadmin: ${HASH}
  password: ${PASS}
type: Opaque
YAML
}

apply_firmly(){
  if [ ! -f "${1}/kustomization.yaml" ]; then
    echo "Please provide a dir with \"kustomization.yaml\""
    return 1
  fi

  # kludge
  until oc kustomize "${1}" --enable-helm | oc apply -f- 2>/dev/null
  do
    echo "again..."
    sleep 20
  done
  # until_true oc apply -k "${1}" 2>/dev/null
}

until_true(){
  echo "Running:" "${@}"
  until "${@}" 1>&2
  do
    echo "again..."
    sleep 20
  done

  echo "[OK]"
}
