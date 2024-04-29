#!/usr/bin/env bash

NS=${NS:-minio}
OBJECT=${OBJECT:-secret/minio-root-user}
SECRET_NAME=${OBJECT##*/}
# FORCE=true

if [ -n "$(oc -n "${NS}" get "${OBJECT}" 2>/dev/null)" ]; then
  echo "exists: ${OBJECT}"
  [ -z ${FORCE+x} ] && exit 0
  echo "create: ${OBJECT}"
fi

genpass(){
  < /dev/urandom LC_ALL=C tr -dc Aa-zZ0-9 | head -c "${1:-32}"
}

id=$(genpass 16)
secret=$(genpass)

cat << EOF | oc apply -f-
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
type: Opqaue
stringData:
  MINIO_ROOT_USER: ${id}
  MINIO_ROOT_PASSWORD: ${secret}
EOF