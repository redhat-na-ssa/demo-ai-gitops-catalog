#!/bin/bash

alias aws=aws_cli

aws_cli(){
  aws_check_cli && alias aws=aws
}

aws_check_cli(){
  aws --version || return
}

aws_get_all_ec2(){
  aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[].Instances[].InstanceId' --output text | sed 's/\t/ /g'
  aws ec2 describe-instances --filters Name=tag:Name,Values=bastion --query 'Reservations[].Instances[].InstanceId' --output text
}

aws_get_instances(){
  if [ "$#" -ne 0 ]; then
      AWS_TAGS="*$1*"
      echo "Setting AWS_TAGS = ${AWS_TAGS}"
  fi
  echo "AWS_PROFILE=${AWS_PROFILE}, AWS_REGION=${AWS_REGION}, AWS_TAGS=${AWS_TAGS}"
  # shellcheck disable=SC2016
  aws ec2 describe-instances --profile="${AWS_PROFILE}" --region="${AWS_REGION}" --filter Name=tag-value,Values="${AWS_TAGS}" --query 'Reservations[*].Instances[*].{Instance:InstanceId,State:State.Name,Name:Tags[?Key==`Name`]|[0].Value,DNS:PublicDnsName}' --output table
}

aws_start_instance(){
  if [ "$#" -ne 1 ]; then
    echo "Usage:
    $0 InstanceId"
    exit 1
  fi

  iid=$1
  
  read -p -r "Start instance ${iid}? <y/N> " prompt

  if [[ $prompt =~ [yY](es)* ]]
  then
  echo "Starting instance ${iid}"
  aws ec2 start-instances --profile="${AWS_PROFILE}" --region="${AWS_REGION}" --instance-ids="${iid}"
  fi 
}

aws_stop_instance(){
  if [ "$#" -ne 1 ]; then
    echo "Usage:
    $0 InstanceId"
    exit 1
  fi

  iid=$1
  
  read -r -p "Stop instance ${iid}? <y/N> " prompt

  if [[ $prompt =~ [yY](es)* ]]; then
    echo "Stopping instance ${iid}"
    aws ec2 stop-instances --profile="${AWS_PROFILE}" --region="${AWS_REGION}" --instance-ids="${iid}"
  fi 
}

aws_setup_ack_system(){
  NAMESPACE=ack-system

  setup_namespace ${NAMESPACE}

  oc apply -k "${GIT_ROOT}"/components/operators/${NAMESPACE}/aggregate/popular

  for type in ec2 ecr iam s3 sagemaker
  do
    oc apply -k "${GIT_ROOT}"/components/operators/ack-${type}-controller/operator/overlays/alpha

    < "${GIT_ROOT}"/components/operators/ack-${type}-controller/operator/overlays/alpha/user-secrets-secret.yaml \
      sed "s@UPDATE_AWS_ACCESS_KEY_ID@${AWS_ACCESS_KEY_ID}@; s@UPDATE_AWS_SECRET_ACCESS_KEY@${AWS_SECRET_ACCESS_KEY}@" | \
      oc -n ${NAMESPACE} apply -f -
  done
}
