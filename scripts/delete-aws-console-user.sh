#!/bin/bash
# shellcheck disable=SC2086

# USAGE: ./delete-console-user.sh $GROUPNAME $USERNAME

aws iam delete-login-profile --user-name $2
aws iam detach-user-policy --user-name $2 --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'
aws iam remove-user-from-group --user-name $2 --group-name $1
aws iam delete-user --user-name $2
aws iam detach-group-policy --group-name $1 --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'
aws iam delete-group --group-name $1
ß