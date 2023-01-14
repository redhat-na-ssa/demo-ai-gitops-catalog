# Deleted Cluster Sadness Rehab

## Fix Issues

```
# TODO: ArgoCD Hooks
# fix htpasswd-secret on demo env
oc annotate -n openshift-config secret/htpasswd-secret \
  sealedsecrets.bitnami.com/managed='true'

oc delete -n openshift-config sealedsecret/htpasswd-secret
oc delete -n openshift-config secret/htpasswd-secret

# run work on masters
oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": true}}'

# scale down workers
oc scale $(oc -n openshift-machine-api get machineset -o name | grep worker) -n openshift-machine-api --replicas=0

# Create ack operator secrets with main creds
# NOTE: operators are in godmode, meh

# get aws creds
AWS_ACCESS_KEY_ID=$(oc -n kube-system extract secret/aws-creds --keys=aws_access_key_id --to=-)
AWS_SECRET_ACCESS_KEY=$(oc -n kube-system extract secret/aws-creds --keys=aws_secret_access_key --to=-)

# create secrets for ack controllers
NAMESPACE=ack-system
cat components/operators/ack-s3-controller/operator/overlays/alpha/user-secrets-secret.yaml | \
  sed "s/UPDATE_AWS_ACCESS_KEY_ID/${AWS_ACCESS_KEY_ID}/; s/UPDATE_AWS_SECRET_ACCESS_KEY/${AWS_SECRET_ACCESS_KEY}/" | \
  oc -n ${NAMESPACE} apply -f -
cat components/operators/ack-sagemaker-controller/operator/overlays/alpha/user-secrets-secret.yaml | \
  sed "s/UPDATE_AWS_ACCESS_KEY_ID/${AWS_ACCESS_KEY_ID}/; s/UPDATE_AWS_SECRET_ACCESS_KEY/${AWS_SECRET_ACCESS_KEY}/" | \
  oc -n ${NAMESPACE} apply -f -
```
