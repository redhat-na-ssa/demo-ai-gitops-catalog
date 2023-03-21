#!/bin/bash
# shellcheck disable=SC2086
# http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_cliwpsapi

usage(){
echo "
    USAGE: ./create-aws-console-user.sh $GROUPNAME $USERNAME $PASSWORD
"
}


# Create administrator group

aws iam create-group --group-name $1
aws iam attach-group-policy --group-name $1 --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'

# Create user and attach to AdministratorAccess policy

aws iam create-user --user-name $2
aws iam create-login-profile --user-name $2 --password $3
aws iam add-user-to-group --group-name $1 --user-name $2
aws iam attach-user-policy --user-name $2 --policy-arn 'arn:aws:iam::aws:policy/AdministratorAccess'

# Grab account ID
ID=$(aws iam list-users --out text | head -1 | cut -f2 | awk -F'::' '{print $2}' | cut -f1 -d:)

echo
echo SIGNIN URL:
echo "https://$ID.signin.aws.amazon.com/console/"
