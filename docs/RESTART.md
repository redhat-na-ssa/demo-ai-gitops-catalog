# Deleted Cluster Sadness Rehab

## Quickstart

```
# fix htpasswd-secret on demo env
oc annotate -n openshift-config secret/htpasswd-secret \
  sealedsecrets.bitnami.com/managed='true'

oc delete -n openshift-config secret/htpasswd-secret

# copy ack secrets into scratch
cp components/operators/ack-s3-controller/operator/overlays/alpha/user-secrets-secret.yaml generated/ack-s3-user-secrets.yaml
cp components/operators/ack-sagemaker-controller/operator/overlays/alpha/user-secrets-secret.yaml generated/ack-sagemaker-user-secrets.yaml

# copy pasta champion
echo "Did you edit the secrets? <CTRL> + C"
sleep 10

# reseal secrets
cat generated/ack-s3-user-secrets.yaml| kubeseal --controller-namespace sealed-secrets -o yaml > clusters/base/ack-s3-user-secrets-ss.yaml
cat generated/ack-sagemaker-user-secrets.yaml| kubeseal --controller-namespace sealed-secrets -o yaml > clusters/base/ack-sagemaker-user-secrets-ss.yaml

# commit to git
git status
git commit -m 'update: sealed secrets' -a
git push
```
