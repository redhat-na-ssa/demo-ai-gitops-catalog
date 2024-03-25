# OpenShift Data Foundation

Install OpenShift Data Foundation.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [stable-4.9](operator/overlays/stable-4.12)
* [stable-4.10](operator/overlays/stable-4.13)
* [stable-4.11](operator/overlays/stable-4.12)
* [stable-4.12](operator/overlays/stable-4.13)
* [stable-4.13](operator/overlays/stable-4.12)
* [stable-4.14](operator/overlays/stable-4.13)
* [stable-4.15](operator/overlays/stable-4.13)

## Usage

If you have cloned the `gitops-catalog` repository, you can install OpenShift Data Foundation based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```
oc apply -k odf-operator/operator/overlays/<channel>
```

Or, without cloning:

```
oc apply -k https://github.com/redhat-cop/gitops-catalog/odf-operator/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/odf-operator/operator/overlays/<channel>?ref=main
```
