#!/bin/bash
# shellcheck disable=SC2086

usage(){
echo "
    USAGE: ./create-aws-console-user.sh [username] [groupname] [password]
"
}

USERNAME=${1:-admin}
GROUPNAME=${2:-Admins}
PASSWORD=${3:-UseAB3ttrPass!}

# Create administrator group
aws iam create-group --group-name "${GROUPNAME}"
aws iam attach-group-policy --group-name "${GROUPNAME}" --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'

# Create user and attach to AdministratorAccess policy

aws iam create-user --user-name "${USERNAME}"
aws iam create-login-profile --user-name "${USERNAME}" --password "${PASSWORD}"
aws iam add-user-to-group --group-name "${GROUPNAME}" --user-name "${USERNAME}"
aws iam attach-user-policy --user-name "${USERNAME}" --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'

# Grab account ID
ID=$(aws iam list-users --out text | head -1 | cut -f2 | awk -F'::' '{print $2}' | cut -f1 -d:)

echo
echo SIGNIN URL:
echo "https://${ID}.signin.aws.amazon.com/console"
