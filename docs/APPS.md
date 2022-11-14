# How to add objects to the cluster

## Sealed Secrets Quickstart

Convert an existing secret into a sealed-secret that can be commited in git

```
cat scratch/repo-secret.yml | kubeseal \
  --controller-namespace sealed-secrets \
  -o yaml > bootstrap/overlays/default/argocd-ssh-repo-ss.yaml 
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

[Sealed Secrets - Offical Docs](https://github.com/bitnami-labs/sealed-secrets)