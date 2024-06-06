#!/bin/bash

WORKSHOP_USER=${WORKSHOP_USER:-user}
WORKSHOP_PASS=${WORKSHOP_PASS:-openshift}
WORKSHOP_NUM=${WORKSHOP_NUM:-50}
WORKSHOP_HTPASSWD=htpasswd-workshop-secret

GROUP_ADMINS=workshop-admins
# GROUP_USERS=workshop-users

TMP_DIR=scratch

workshop_create_user_htpasswd(){
  FILE="${TMP_DIR}/${WORKSHOP_HTPASSWD}"
  touch "${FILE}"

  which htpasswd || return

  echo "# ${WORKSHOP_USER}x: ${WORKSHOP_PASS}" > "${FILE}"

  for ((i=1;i<=WORKSHOP_NUM;i++))
  do
    htpasswd -bB "${FILE}" "${WORKSHOP_USER}${i}" "${WORKSHOP_PASS}"
  done

  echo "created: ${FILE}" 
  oc -n openshift-config create secret generic htpasswd --from-file="${FILE}"
  oc -n openshift-config set data secret/htpasswd --from-file="${FILE}"
  oc apply -f gitops/02-components/oauth.yaml

}

workshop_create_user_ns(){
  OBJ_DIR=${TMP_DIR}/users
  
  [ -e ${OBJ_DIR} ] && rm -rf ${OBJ_DIR}
  [ ! -d ${OBJ_DIR} ] && mkdir -p ${OBJ_DIR}

  for ((i=1;i<=WORKSHOP_NUM;i++))
  do

# create ns
cat << YAML >> "${OBJ_DIR}/${WORKSHOP_USER}${i}-ns.yaml"
---
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/display-name: Start Here - ${WORKSHOP_USER}${i}
  labels:
    workshop: user
  name: ${WORKSHOP_USER}${i}
YAML

  oc apply -f "${OBJ_DIR}/${WORKSHOP_USER}${i}-ns.yaml"

# create rolebinding
cat << YAML >> "${OBJ_DIR}/${WORKSHOP_USER}${i}-admin-rb.yaml"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    workshop: user
  name: ${WORKSHOP_USER}${i}-admin
  namespace: ${WORKSHOP_USER}${i}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: ${WORKSHOP_USER}${i}
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: ${GROUP_ADMINS}
YAML
  done

  # apply objects created in scratch dir
  oc apply -f "${OBJ_DIR}"

}

# shellcheck disable=SC2120
workshop_create_user_load(){
  LOAD_IMAGE=${1:-quay.io/devfile/universal-developer-image:ubi8-latest}
  LOAD_CPU=${2:-400m}
  LOAD_MEM=${3:-1Gi}

  for ((i=1;i<=WORKSHOP_NUM;i++))
  do

echo "---
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: load-test
  # name: ${WORKSHOP_USER}${i}
  name: load-test
  namespace: ${WORKSHOP_USER}${i}
spec:
  containers:
  - name: test
    image: ${LOAD_IMAGE}
    command:
      - sleep
      - infinity
    resources:
      requests:
        cpu: ${LOAD_CPU}
        memory: ${LOAD_MEM}
  restartPolicy: Always
" | oc apply -f -
  done
}

workshop_load_test(){
  workshop_create_user_ns
  workshop_create_user_load
}

workshop_load_test_clean(){
  oc delete pod -l run=load-test -A
}

workshop_clean_user_ns(){
  oc delete project -l workshop=user
}

workshop_setup(){
  workshop_create_user_htpasswd
  workshop_create_user_ns
}

workshop_clean(){
  echo "Workshop: Remove User Namespaces"
  echo "Press CTRL + C to abort..."
  sleep 8
  workshop_clean_user_ns
}

workshop_reset(){
  echo "Workshop: Reset"
  workshop_clean
  sleep 8
  workshop_setup
}
