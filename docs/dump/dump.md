# Unsorted Notes

## Notes Dump

- Most people try to use the local shell
    - Mac - `zsh`
    - Win - `ps` *(who are we kidding, enterprise customers don't use powershell*)
- Users not clear what options are available for bootstrap
- The quick start is not easy to read
- The automation is too easy for users
    - need to be able to explain to a customer
    - need to be able to understand how it works on a basic level
- Explain what it means to setup a default cluster
- Tree defining the repo dir structure could help navigation

## Policy on k8s

- https://github.com/open-policy-agent/gatekeeper
- https://kyverno.io

## SOPS

https://github.com/getsops/sops

## AWS Machine Set storage

Patch `MachineSet` to add secondary storage

```sh
spec:
  template:
    spec:
      providerSpec:
        value:
          blockDevices:
            - ebs:
                encrypted: true
                iops: 0
                kmsKey:
                  arn: ''
                volumeSize: 100
                volumeType: gp3
            - deviceName: /dev/xvdb
              ebs:
                encrypted: true
                iops: 0
                kmsKey:
                  arn: ''
                volumeSize: 1000
                volumeType: gp3
```

## Sealed Secrets Quick Start

Convert an existing secret into a sealed-secret that can be committed in git

Dump current sealed secret cert

```sh
SEALED_SECRETS_SECRET=bootstrap/sealed-secrets-secret.yaml

oc -n sealed-secrets -o yaml \
  get secret \
  -l sealedsecrets.bitnami.com/sealed-secrets-key=active \
  > ${SEALED_SECRETS_SECRET}
```

Convert a secret local file to a sealed-secret

```sh
cat scratch/repo-secret.yml | kubeseal \
  --controller-namespace sealed-secrets \
  -o yaml > bootstrap/overlays/default/argocd-ssh-repo-ss.yaml
```

```sh
cat scratch/htpasswd-secret.yaml | kubeseal \
  --controller-namespace sealed-secrets \
  -o yaml > components/cluster-configs/login/overlays/rhdp/htpasswd-secret-ss.yaml
```

Convert a secret in OpenShift to a sealed-secret

```sh
oc -n openshift-config \
  -o yaml \
  get secret htpasswd-secret \
    | kubeseal \
      -o yaml \
      --controller-namespace sealed-secrets
```

Add the following annotations to the sealed secret

```sh
spec:
  template:
    metadata:
      annotations:
        managed-by: argocd.argoproj.io
        sealedsecrets.bitnami.com/managed: "true"
```

```sh
oc -n openshift-config \
  -o yaml \
  annotate secret/htpasswd-secret \
  "sealedsecrets.bitnami.com/managed=true"
```

[Sealed Secrets - Official Docs](https://github.com/bitnami-labs/sealed-secrets)

## ROSA Clusters

In ROSA clusters you are not actually `cluster-admin` when you are the `cluster-admin` user. We need to review the actual permissions needed to run the argocd scripts.

```sh
# hack
oc --as=backplane-cluster-admin \
  adm policy \
  add-cluster-role-to-user cluster-admin cluster-admin
```

## Operator Info

[Operator Catalogs](https://docs.openshift.com/container-platform/4.14/operators/understanding/olm-rh-catalogs.html#olm-rh-catalogs_olm-rh-catalogs)

```sh
# login to registry
podman login --authfile scratch/pull-secret.txt registry.redhat.io

# kludge: copy registry key to podman auth
DOCKER_CONFIG=~/.docker
oc -n openshift-config extract secret/pull-secret --keys=.dockerconfigjson
mkdir -p ~/.docker && mv .dockerconfigjson ~/.docker/config.json

# redhat-operators
INDEX=registry.redhat.io/redhat/redhat-operator-index:v4.14
oc mirror list operators --catalog ${INDEX}

oc mirror list operators --catalog ${INDEX} --package rhods-operator
```

## Airflow

### triggerer

```sh
oc patch statefulset/airflow-triggerer --patch '{"spec":{"template":{"spec":{"initContainers":[{"name":"git-sync-init","securityContext":null}]}}}}'

oc patch statefulset/airflow-triggerer --patch '{"spec":{"template":{"spec":{"containers":[{"name":"git-sync","securityContext":null}]}}}}'
```

### worker

```sh
oc patch statefulset/airflow-worker --patch '{"spec":{"template":{"spec":{"initContainers":[{"name":"git-sync-init","securityContext":null}]}}}}'

oc patch statefulset/airflow-worker --patch '{"spec":{"template":{"spec":{"containers":[{"name":"git-sync","securityContext":null}]}}}}'
```

## Resolve ingress / auth cert issues

```sh
oc -n openshift-config delete cm openshift-service-ca.crt
oc -n openshift-ingress delete cm service-ca-bundle
oc -n openshift-authentication delete cm v4-0-config-system-service-ca
oc -n openshift-authentication delete cm v4-0-config-system-trusted-ca-bundle
```

Label storage nodes to deploy odf

```sh
oc label node cluster.ocs.openshift.io/openshift-storage="" --all
# oc label nodes --selector='node-role.kubernetes.io/worker' cluster.ocs.openshift.io/openshift-storage="" --overwrite=true

oc annotate sc ocs-storagecluster-cephfs storageclass.kubernetes.io/is-default-class="true"
```

Setup image registry

```sh
# check storage class
oc get sc

# setup registry operator
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"RollingUpdate","replicas":2}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge -p '{"spec":{"managementState":"Managed"}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge -p '{"spec":{"storage":{"pvc":{"claim": null}}}}'
```

Expose image registry

```sh
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
```

## Helm Notes

Download helm chart locally and dump yaml

```sh
mkdir -p scratch/yaml
cd scratch

helm template rh-ecosystem-edge/console-plugin-nvidia-gpu
helm template --output-dir './yaml' rh-ecosystem-edge/console-plugin-nvidia-gpu

# helm < v3
helm fetch --untar --untardir . 'rh-ecosystem-edge/console-plugin-nvidia-gpu'
helm template --output-dir './yaml' './console-plugin-nvidia-gpu'
```

## GPU Test Pod

```sh
oc apply -f https://raw.githubusercontent.com/NVIDIA/gpu-operator/master/tests/gpu-pod.yaml
```

## OCP GPU Console Errors

Error

```sh
GPUOperatorReconciliationFailed
GPUOperatorReconciliationFailedNfdLabelsMissing NFD
```

Fix

```sh
oc -n nvidia-gpu-operator delete pod --all
```

Links

- https://cloud.redhat.com/blog/autoscaling-nvidia-gpus-on-red-hat-openshift

## Disconnected Notes

```sh
oc mirror -c scripts/wip/imageset-config.yaml --dry-run file://scratch/mirror_media
```

Links

- https://docs.openshift.com/container-platform/4.14/operators/admin/olm-managing-custom-catalogs.html
- https://github.com/rpardini/docker-registry-proxy
