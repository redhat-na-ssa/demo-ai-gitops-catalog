# Migration Toolkit for Virtualization Operator

Install Migration Toolkit for Virtualization Operator.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [release-v2.10](operator/overlays/release-v2.10)
* [release-v2.7](operator/overlays/release-v2.7)
* [release-v2.8](operator/overlays/release-v2.8)

## Usage

If you have cloned the `gitops-catalog` repository, you can install Migration Toolkit for Virtualization Operator based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```sh
oc apply -k mtv-operator/operator/overlays/<channel>
```

Or, without cloning:

```sh
oc apply -k https://github.com/redhat-cop/gitops-catalog/mtv-operator/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/mtv-operator/operator/overlays/<channel>?ref=main
```
