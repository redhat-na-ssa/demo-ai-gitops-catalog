#!/bin/bash
set -euo pipefail

# OC_VERSION=$(oc version | sed -n 's/Server Version: //p')
BACKUP_TIME=$(date +%Y-%m-%d_%H.%M.%S)
BACKUP_INSTANCE=${CLUSTER_BACKUP_PATH:-/tmp}/etcd-backup-${OC_VERSION:-4.x}-${BACKUP_TIME}

list_backups(){
  find /backups -type d -name 'etcd-backup-*' | sort
}

prune_backups(){
  LIMIT=${1:-69}  # percent
  USE=$(df -h /backups | awk 'FNR == 2 {print $5}')

  while [ "${USE%?}" -gt "${LIMIT}" ]
  do
      echo "pruning: more than ${LIMIT}% used"
      LAST_BACKUP=$(list_backups | head -n 1)

      [ "${LAST_BACKUP}" == "" ] && break

      rm -rf "${LAST_BACKUP}"

      USE=$(df -h /backups | awk 'FNR == 2 {print $5}')
  done

  echo "List, Backup(s):"
  list_backups

  echo ""
  df -h /host
  df -h /backups
  echo ""
}

prune_backups 69

echo "Start, Backup:"
chroot /host sudo -E /usr/local/bin/cluster-backup.sh "${BACKUP_INSTANCE}"
gzip -9 /host/"${BACKUP_INSTANCE}"/*.db

mv -v /host/"${CLUSTER_BACKUP_PATH}"/etcd-backup-* /backups || true
