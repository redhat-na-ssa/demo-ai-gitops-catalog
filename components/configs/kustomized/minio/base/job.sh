#!/usr/bin/env bash

# FORCE=true

if [ -n "$(oc get secret minio-root-user -o name 2>/dev/null)" ]; then
  echo "Secret already exists."
  [ -z ${FORCE+x} ] && exit 0
  echo "Forcing creation."
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