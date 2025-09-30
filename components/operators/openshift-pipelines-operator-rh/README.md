# Red Hat OpenShift Pipelines

Install Red Hat OpenShift Pipelines.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [latest](operator/overlays/latest)
* [pipelines-1.14](operator/overlays/pipelines-1.14)
* [pipelines-1.15](operator/overlays/pipelines-1.15)
* [pipelines-1.16](operator/overlays/pipelines-1.16)
* [pipelines-1.17](operator/overlays/pipelines-1.17)
* [pipelines-1.18](operator/overlays/pipelines-1.18)
* [pipelines-1.19](operator/overlays/pipelines-1.19)
* [pipelines-1.20](operator/overlays/pipelines-1.20)

## Usage

If you have cloned the `gitops-catalog` repository, you can install Red Hat OpenShift Pipelines based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```sh
oc apply -k openshift-pipelines-operator-rh/operator/overlays/<channel>
```

Or, without cloning:

```sh
oc apply -k https://github.com/redhat-cop/gitops-catalog/openshift-pipelines-operator-rh/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/openshift-pipelines-operator-rh/operator/overlays/<channel>?ref=main
```
