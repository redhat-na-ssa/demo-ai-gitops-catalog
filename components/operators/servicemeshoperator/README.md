# Red Hat OpenShift Service Mesh 2

Install Red Hat OpenShift Service Mesh 2.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [1.0](operator/overlays/1.0)
* [stable](operator/overlays/stable)

## Usage

If you have cloned the `gitops-catalog` repository, you can install Red Hat OpenShift Service Mesh 2 based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```sh
oc apply -k servicemeshoperator/operator/overlays/<channel>
```

Or, without cloning:

```sh
oc apply -k https://github.com/redhat-cop/gitops-catalog/servicemeshoperator/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/servicemeshoperator/operator/overlays/<channel>?ref=main
```
