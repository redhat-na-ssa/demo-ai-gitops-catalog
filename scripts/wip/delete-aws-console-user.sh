#!/bin/bash
# shellcheck disable=SC2086

# USAGE: ./delete-console-user.sh $USERNAME $GROUPNAME

USERNAME=${1:-admin}
GROUPNAME=${2:Admins}

aws iam delete-login-profile --user-name "${USERNAME}"
aws iam detach-user-policy --user-name "${USERNAME}" --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'
aws iam remove-user-from-group --user-name "${USERNAME}" --group-name "${GROUPNAME}"
aws iam delete-user --user-name "${USERNAME}"
aws iam detach-group-policy --group-name "${GROUPNAME}" --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'
aws iam delete-group --group-name "${GROUPNAME}"
