# How to add objects to the cluster

## Sealed Secrets Quick Start

Convert an existing secret into a sealed-secret that can be committed in git

Dump current sealed secret cert

```
SEALED_SECRETS_SECRET=bootstrap/base/sealed-secrets-secret.yaml

oc -n sealed-secrets -o yaml \
  get secret \
  -l sealedsecrets.bitnami.com/sealed-secrets-key=active \
  > ${SEALED_SECRETS_SECRET}
```

Convert a secret local file to a sealed-secret

```
cat scratch/repo-secret.yml | kubeseal \
  --controller-namespace sealed-secrets \
  -o yaml > bootstrap/overlays/default/argocd-ssh-repo-ss.yaml
```

```
cat scratch/htpasswd-secret.yaml | kubeseal \
  --controller-namespace sealed-secrets \
  -o yaml > components/configs/login/overlays/rhdp/htpasswd-secret-ss.yaml
```

Convert a secret in OpenShift to a sealed-secret

```
oc -n openshift-config \
  -o yaml \
  get secret htpasswd-secret \
    | kubeseal \
      -o yaml \
      --controller-namespace sealed-secrets
```
  
Add the following annotations to the sealed secret

```
spec:
  template:
    metadata:
      annotations:
        managed-by: argocd.argoproj.io
        sealedsecrets.bitnami.com/managed: "true"
```

```
oc -n openshift-config \
  -o yaml \
  annotate secret/htpasswd-secret \
  "sealedsecrets.bitnami.com/managed=true"
```

[Sealed Secrets - Official Docs](https://github.com/bitnami-labs/sealed-secrets)

## ROSA Clusters

In ROSA clusters you are not actually `cluster-admin` when you are the `cluster-admin` user. We need to review the actual permissions needed to run the argocd scripts.

```
# hack
oc --as=backplane-cluster-admin \
  adm policy \
  add-cluster-role-to-user cluster-admin cluster-admin
```
