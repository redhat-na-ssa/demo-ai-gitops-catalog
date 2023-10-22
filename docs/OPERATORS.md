# Operator Info



```
# login to registry
podman login --authfile scratch/pull-secret.txt registry.redhat.io

DOCKER_CONFIG=$(pwd)/scratch/pull-secret.txt

oc mirror list operators --catalog registry.redhat.io/redhat/redhat-operator-index:v4.12 --package rhods-operator
```