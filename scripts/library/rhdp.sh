#!/bin/bash

rhdp_get_uuid(){
  oc whoami || return 1
  UUID=$(oc whoami --show-server | sed 's@https://@@; s@:.*@@; s@api.*-@@; s@[.].*$@@')
  export UUID

  echo "OCP Cluster UUID: ${UUID}"
}

rhdp_fix_api_certs(){
   echo "
  issue: RHDP can not start cluster due to ca.crt change

  NOTICE: ssh to the RHDP bastion host and run the following commands:

    # user: lab-user
    sed -i.bak '/certificate-authority-data/d' ~/.kube/config

    # user: ec2-user
    sudo su ec2-user /bin/bash -c 'id; sed -i.bak '/certificate-authority-data/d' ~/.kube/config'

    # user: root
    sudo su root /bin/bash -c 'id; sed -i.bak '/certificate-authority-data/d' ~/.kube/config'
  "

  CERT_NAME=$(oc -n openshift-ingress-operator get ingresscontrollers default --template='{{.spec.defaultCertificate.name}}')
  # API_HOST_NAME=$(oc -n openshift-console extract cm/console-config --to=- | sed -n '/masterPublicURL/ s/.*:\/\///; s/:6443//p')
  # API_HOST_NAME=$(oc whoami --show-server | sed 's@https://@@; s@:.*@@')
  API_HOST_NAME=api.$(oc -n openshift-ingress-operator get dns cluster --template='{{.spec.baseDomain}}')

  oc -n openshift-ingress get secret "${CERT_NAME}" -o yaml | \
    sed 's/namespace: .*/namespace: openshift-config/' | \
    oc -n openshift-config apply -f-

  oc patch apiserver cluster --type=merge -p '{"spec":{"servingCerts": {"namedCertificates": [{"names": ["'"${API_HOST_NAME}"'"], "servingCertificate": {"name": "'"${CERT_NAME}"'"}}]}}}'  
}


rhdp_aws_stop_all_ec2(){
  RUNNING_IDS=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[].Instances[].InstanceId' --output text | sed 's/\t/ /g')
  BASTION_ID=$(aws ec2 describe-instances --filters Name=tag:Name,Values=bastion --query 'Reservations[].Instances[].InstanceId' --output text)

  echo "BASTION_ID: ${BASTION_ID}"
  aws ec2 stop-instances \
    --instance-ids \
    "${RUNNING_IDS}" \
    --output text >/dev/null
}

rhdp_aws_start_ocp4_cluster(){
  CLUSTER_IDS=$(aws ec2 describe-instances --filters Name=tag:env_type,Values=ocp4-cluster --query 'Reservations[].Instances[].InstanceId' --output text | sed 's/\t/ /g')

  aws ec2 start-instances \
    --instance-ids \
    "${CLUSTER_IDS}" \
    --output text >/dev/null
}
