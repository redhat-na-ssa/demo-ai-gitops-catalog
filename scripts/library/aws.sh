#!/bin/sh

aws_check_cli(){
  aws --version || return
}

aws_get_all_ec2(){
  aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[].Instances[].InstanceId' --output text | sed 's/\t/ /g'
  aws ec2 describe-instances --filters Name=tag:Name,Values=bastion --query 'Reservations[].Instances[].InstanceId' --output text
}
