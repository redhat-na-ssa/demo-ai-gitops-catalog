# Operator Info



```
# login to registry
podman login --authfile scratch/pull-secret.txt registry.redhat.io

# copy registry key to podman auth
cp scratch/pull-secret.txt ${XDG_RUNTIME_DIR}/containers/auth.json

oc mirror list operators --catalog registry.redhat.io/redhat/redhat-operator-index:v4.12 --package rhods-operator
```