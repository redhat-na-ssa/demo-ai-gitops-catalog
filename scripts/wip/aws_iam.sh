#!/bin/bash
# shellcheck disable=SC2086

USER_NAME=${1:-admin}
GROUP_NAME=${2:-Admins}
PASSWORD=${3:-UseAB3ttrPass!}

which aws >/dev/null 2>&1 || { echo "AWS CLI not found. Please install AWS CLI."; return 1; }

# aws_iam_usage(){
# echo "
#   USAGE: $(basename $0) [username] [groupname] [password]
# "
# }

# aws_iam_delete_user
# [ "x$GROUP_NAME" != "x" ] && aws_iam_delete_group "${GROUP_NAME}"

aws_iam_create_user(){

  # create administrator group
  aws iam create-group \
    --group-name "${GROUP_NAME}"
  aws iam attach-group-policy \
    --group-name "${GROUP_NAME}" \
    --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'

  # create user and attach to AdministratorAccess policy
  aws iam create-user \
    --user-name "${USER_NAME}"
  aws iam create-login-profile \
    --user-name "${USER_NAME}" \
    --password "${PASSWORD}"
  aws iam add-user-to-group \
    --group-name "${GROUP_NAME}" \
    --user-name "${USER_NAME}"
  aws iam attach-user-policy \
    --user-name "${USER_NAME}" \
    --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'
}

aws_iam_display_signin_url(){
  # get AWS ID
  AWS_ID=$(aws iam list-users --out text | head -1 | cut -f2 | awk -F'::' '{print $2}' | cut -f1 -d:)

  echo
  echo SIGNIN URL:
  echo "https://${AWS_ID}.signin.aws.amazon.com/console"
}

aws_iam_delete_user(){
  aws iam delete-login-profile \
    --user-name "${USER_NAME}"

  aws iam detach-user-policy \
    --user-name "${USER_NAME}" \
    --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'

  aws iam delete-user \
    --user-name "${USER_NAME}"
}

aws_iam_delete_group(){
  aws iam remove-user-from-group \
    --user-name "${USER_NAME}" \
    --group-name "${GROUP_NAME}"

  aws iam detach-group-policy \
    --group-name "${GROUP_NAME}" \
    --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'
  
  aws iam delete-group \
    --group-name "${GROUP_NAME}"
}
