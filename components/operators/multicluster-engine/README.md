# multicluster engine for Kubernetes

Install multicluster engine for Kubernetes.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [stable-2.3](operator/overlays/stable-2.3)
* [stable-2.4](operator/overlays/stable-2.4)
* [stable-2.5](operator/overlays/stable-2.5)
* [stable-2.6](operator/overlays/stable-2.6)
* [stable-2.7](operator/overlays/stable-2.7)

## Usage

If you have cloned the `gitops-catalog` repository, you can install multicluster engine for Kubernetes based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```sh
oc apply -k multicluster-engine/operator/overlays/<channel>
```

Or, without cloning:

```sh
oc apply -k https://github.com/redhat-cop/gitops-catalog/multicluster-engine/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/multicluster-engine/operator/overlays/<channel>?ref=main
```
