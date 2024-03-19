# Node Maintenance Operator - Community Edition

Install Node Maintenance Operator - Community Edition.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [4.12-eus](operator/overlays/4.12-eus)
* [4.14-eus](operator/overlays/4.14-eus)
* [stable](operator/overlays/stable)

## Usage

If you have cloned the `gitops-catalog` repository, you can install Node Maintenance Operator - Community Edition based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```
oc apply -k node-maintenance-operator/operator/overlays/<channel>
```

Or, without cloning:

```
oc apply -k https://github.com/redhat-cop/gitops-catalog/node-maintenance-operator/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/node-maintenance-operator/operator/overlays/<channel>?ref=main
```
