#!/bin/bash
# shellcheck disable=SC2068
# shellcheck disable=SC2317

TMP_DIR=scratch

# ===================================

# shellcheck disable=SC2120
genpass(){
  < /dev/urandom LC_ALL=C tr -dc _A-Z-a-z-0-9 | head -c "${1:-32}"
}

create_kubeadmin_yaml(){
  PASS=${1:-$(genpass 5 )-$(genpass 5 )-$(genpass 5 )-$(genpass 5 )}

  which htpasswd >/dev/null || return

  HTPASSWD=$(htpasswd -nbB -C10 null "${PASS}")
  HASH=${HTPASSWD##*:}

  echo "
  PASSWORD: ${PASS}
  HASH:     ${HASH}

  oc apply -f ${TMP_DIR}/kubeadmin.yaml
  "

cat << YAML > "${TMP_DIR}"/kubeadmin.yaml
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

  until_true oc apply -k "${1}" 2>/dev/null
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

htpasswd_add_user(){
  TMP_DIR=${TMP_DIR:-scratch}
  USERNAME=${1:-admin}
  PASSWORD=${2:-$(genpass 16)}
  HTPASSWD=${3:-${TMP_DIR}/htpasswd-local}

  echo "
    USERNAME: ${USERNAME}
    PASSWORD: ${PASSWORD}
  "

  touch "${HTPASSWD}"
  echo "# ${USERNAME} - ${PASSWORD}" >> "${HTPASSWD}"
  htpasswd -bB -C 10 "${HTPASSWD}" "${USERNAME}" "${PASSWORD}"
}

htpasswd_get_file(){
  HTPASSWD=${1:-"${TMP_DIR}/htpasswd-local"}

  oc -n openshift-config \
    extract secret/"${HTPASSWD##*/}" \
    --keys=htpasswd \
    --to=- > "${HTPASSWD}"
}

htpasswd_set_file(){
  HTPASSWD=${1:-"${TMP_DIR}/htpasswd-local"}

  oc -n openshift-config \
    set data secret/"${HTPASSWD##*/}" \
    --from-file=htpasswd="${HTPASSWD}"
}

# ===================================

WORKSHOP_USER=${WORKSHOP_USER:-user}
WORKSHOP_PASS=${WORKSHOP_PASS:-openshift}
WORKSHOP_NUM=${WORKSHOP_NUM:-50}
WORKSHOP_HTPASSWD=htpasswd-workshop

GROUP_ADMINS=workshop-admins
# GROUP_USERS=workshop-users

OBJ_DIR=${TMP_DIR}/workshop

HTPASSWD_FILE=${OBJ_DIR}/htpasswd-workshop

workshop_usage(){
  echo ""
  echo "Usage: workshop_[setup,clean,reset] [number of users]
  "
}

workshop_init(){
  # do you have oc
  which oc || return 1

  # do you have htpasswd
  which htpasswd || return 1

  # create generated folder
  [ ! -d "${OBJ_DIR}" ] && mkdir -p "${OBJ_DIR}"

  # create htpasswd files
  [ -e "${TMP_DIR}/htpasswd-local" ] || htpasswd_get_file "${TMP_DIR}/htpasswd-local"
  [ -e "${TMP_DIR}/workshop/htpasswd-workshop" ] || htpasswd_get_file "${TMP_DIR}/workshop/htpasswd-workshop"

  echo "Workshop: Functions Loaded"
  workshop_usage
}

workshop_create_group(){
  OCP_GROUP=${1:-workshop-users}

cat << YAML | oc apply -f -
kind: Group
apiVersion: user.openshift.io/v1
metadata:
  name: ${OCP_GROUP}
users: []
YAML
}

workshop_add_user_to_group(){
  USER=${1:-user0}
  OCP_GROUP=${2:-workshop-users}

  if ! oc get group "${OCP_GROUP}" > /dev/null; then
    workshop_create_group "${OCP_GROUP}"
  fi

  oc adm groups add-users \
    "${OCP_GROUP}" "${USER}"
}

workshop_create_users(){
  TOTAL=${1:-25}
  LIST=$(eval echo "{0..${TOTAL}}")

  for i in ${LIST[@]}
  do

    # create login things
    htpasswd_add_user "${DEFAULT_USER}${i}" "${DEFAULT_PASS}${i}" "${HTPASSWD_FILE}"
    workshop_add_user_to_group "${DEFAULT_USER}${i}" "${DEFAULT_GROUP}"

    # create users objs from template
    cp -a workshop/instance "${OBJ_DIR}/${DEFAULT_USER}${i}"
    sed -i 's/user0/'"${DEFAULT_USER}${i}"'/g' "${OBJ_DIR}/${DEFAULT_USER}${i}/"*.yaml
    # oc apply -f "${OBJ_DIR}/${DEFAULT_USER}${i}/user-ns.yaml"
    oc apply -k "${OBJ_DIR}/${DEFAULT_USER}${i}"
  done

  # update htpasswd in cluster
  htpasswd_set_file "${HTPASSWD_FILE}"

}

workshop_stop_active_notebooks(){
  # stop notebooks
  oc annotate notebooks kubeflow-resource-stopped='now' --all -A

  # oc -n rhods-notebooks \
  #   delete po -l app=jupyterhub
}

workshop_clean_jobs(){
  oc delete jobs -l owner=workshop -A
}

workshop_clean_users(){
  oc delete project -l owner=workshop
  oc delete group "${DEFAULT_GROUP}"
  oc delete identities,users --all
}

# shellcheck disable=SC2120
workshop_setup(){
  TOTAL=${1:-10}
  echo "Workshop: Setup"

  workshop_init
  apply_firmly workshop/overlays/default

  htpasswd_set_file
  workshop_create_users "${TOTAL}"
}

workshop_clean(){
  echo "Workshop: Clean"
  [ -n  "${OBJ_DIR}" ] && rm -rf "${OBJ_DIR}"

  workshop_stop_active_notebooks
  workshop_clean_users
}

workshop_reset(){
  echo "Workshop: Reset"
  workshop_clean
  sleep 10
  workshop_setup
}

workshop_init


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
