# Operator Info

[Operator Catalogs](https://docs.openshift.com/container-platform/4.12/operators/understanding/olm-rh-catalogs.html#olm-rh-catalogs_olm-rh-catalogs)

```
# login to registry
podman login --authfile scratch/pull-secret.txt registry.redhat.io

# kludge: copy registry key to podman auth
DOCKER_CONFIG=~/.docker
oc -n openshift-config extract secret/pull-secret --keys=.dockerconfigjson
mkdir -p ~/.docker && mv .dockerconfigjson ~/.docker/config.json

# redhat-operators
INDEX=registry.redhat.io/redhat/redhat-operator-index:v4.12
oc mirror list operators --catalog ${INDEX}

oc mirror list operators --catalog ${INDEX} --package rhods-operator
```
