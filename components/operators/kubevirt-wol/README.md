# Kubevirt Wake on Lan

Install Kubevirt Wake on Lan.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [candidate-v0](operator/overlays/candidate-v0)
* [fast-v0](operator/overlays/fast-v0)
* [stable-v0](operator/overlays/stable-v0)

## Usage

If you have cloned the `gitops-catalog` repository, you can install Kubevirt Wake on Lan based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```sh
oc apply -k kubevirt-wol/operator/overlays/<channel>
```

Or, without cloning:

```sh
oc apply -k https://github.com/redhat-cop/gitops-catalog/kubevirt-wol/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/kubevirt-wol/operator/overlays/<channel>?ref=main
```
