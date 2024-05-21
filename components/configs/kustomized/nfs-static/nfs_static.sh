#!/bin/bash

TARGET_DIR=${TARGET_DIR:-scratch/nfs-static}
NFS_SERVER=${NFS_PATH:-pi.hou}
NFS_PATH=${NFS_PATH:-k8s-data}


nfs_static_init(){
  mkdir -p "${TARGET_DIR}"
}

nfs_static_create_pv(){
  PV_NAME=${1:-nfs-static-00}
  NFS_PATH=${2:-k8s-data}
  NFS_SERVER=${3:-pi.hou}
  [ -e base/pv.yaml ] || return

  sed '
    s@nfs-static-00@'"${PV_NAME}"'@
    s@k8s-data@'"${NFS_PATH}"'@
    s@pi.hou@'"${NFS_SERVER}"'@
  ' base/pv.yaml > "${TARGET_DIR}/${PV_NAME}.yaml"
}

nfs_static_create_range(){
  NUM=${1:-50}
  PV_NAME=${1:-nfs-static-00}
  NFS_PATH=${2:-k8s-data}

  for ((i=1;i<=NUM;i++))
  do
    nfs_static_create_pv pv-"${i}"
  done
}

nfs_static_init
# nfs_static_create_pv pv-00 'k8s-nfs/here' server.test
nfs_static_create_range 3

