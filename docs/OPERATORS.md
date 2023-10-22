# Operator Info

[Operator Catalogs](https://docs.openshift.com/container-platform/4.12/operators/understanding/olm-rh-catalogs.html#olm-rh-catalogs_olm-rh-catalogs)

```
# login to registry
podman login --authfile scratch/pull-secret.txt registry.redhat.io

# copy registry key to podman auth
cp scratch/pull-secret.txt ${XDG_RUNTIME_DIR}/containers/auth.json

# redhat-operators
INDEX=registry.redhat.io/redhat/redhat-operator-index:v4.12
oc mirror list operators --catalog ${INDEX}

oc mirror list operators --catalog ${INDEX} --package rhods-operator
```