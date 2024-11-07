# Advanced Cluster Security for Kubernetes

Install Advanced Cluster Security for Kubernetes.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [latest](operator/overlays/latest)
* [rhacs-3.62](operator/overlays/rhacs-3.62)
* [rhacs-3.64](operator/overlays/rhacs-3.64)
* [rhacs-3.65](operator/overlays/rhacs-3.65)
* [rhacs-3.66](operator/overlays/rhacs-3.66)
* [rhacs-3.67](operator/overlays/rhacs-3.67)
* [rhacs-3.68](operator/overlays/rhacs-3.68)
* [rhacs-3.69](operator/overlays/rhacs-3.69)
* [rhacs-3.70](operator/overlays/rhacs-3.70)
* [rhacs-3.71](operator/overlays/rhacs-3.71)
* [rhacs-3.72](operator/overlays/rhacs-3.72)
* [rhacs-3.73](operator/overlays/rhacs-3.73)
* [rhacs-3.74](operator/overlays/rhacs-3.74)
* [rhacs-4.0](operator/overlays/rhacs-4.0)
* [rhacs-4.1](operator/overlays/rhacs-4.1)
* [rhacs-4.2](operator/overlays/rhacs-4.2)
* [rhacs-4.3](operator/overlays/rhacs-4.3)
* [rhacs-4.4](operator/overlays/rhacs-4.4)
* [rhacs-4.5](operator/overlays/rhacs-4.5)
* [stable](operator/overlays/stable)

## Usage

If you have cloned the `gitops-catalog` repository, you can install Advanced Cluster Security for Kubernetes based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```sh
oc apply -k rhacs-operator/operator/overlays/<channel>
```

Or, without cloning:

```sh
oc apply -k https://github.com/redhat-cop/gitops-catalog/rhacs-operator/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/rhacs-operator/operator/overlays/<channel>?ref=main
```
