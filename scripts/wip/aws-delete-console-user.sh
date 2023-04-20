#!/bin/bash
# shellcheck disable=SC2086

usage(){
echo "
  USAGE: ./delete-aws-console-user.sh [username] [groupname]
"
}

USERNAME=${1:-admin}
GROUPNAME=${2}

delete_user(){
  aws iam delete-login-profile --user-name "${USERNAME}"
  aws iam detach-user-policy --user-name "${USERNAME}" --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'
  aws iam delete-user --user-name "${USERNAME}"
}

delete_group(){
  aws iam remove-user-from-group --user-name "${USERNAME}" --group-name "${GROUPNAME}"

  aws iam detach-group-policy --group-name "${GROUPNAME}" --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'
  aws iam delete-group --group-name "${GROUPNAME}"
}

delete_user
[ "x$GROUPNAME" != "x" ] && delete_group "${GROUPNAME}"
