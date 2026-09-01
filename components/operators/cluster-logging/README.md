# Red Hat OpenShift Logging

Install Red Hat OpenShift Logging.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [stable-6.2](operator/overlays/stable-6.2)
* [stable-6.3](operator/overlays/stable-6.3)
* [stable-6.4](operator/overlays/stable-6.4)
* [stable-6.5](operator/overlays/stable-6.5)

## Usage

If you have cloned the `gitops-catalog` repository, you can install Red Hat OpenShift Logging based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```sh
oc apply -k cluster-logging/operator/overlays/<channel>
```

Or, without cloning:

```sh
oc apply -k https://github.com/redhat-cop/gitops-catalog/cluster-logging/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/cluster-logging/operator/overlays/<channel>?ref=main
```
