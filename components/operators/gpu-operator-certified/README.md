# NVIDIA GPU Operator

Install NVIDIA GPU Operator.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [stable](operator/overlays/stable)
* [v1.10](operator/overlays/v1.10)
* [v1.11](operator/overlays/v1.11)
* [v22.9](operator/overlays/v22.9)
* [v23.3](operator/overlays/v23.3)
* [v23.6](operator/overlays/v23.6)
* [v23.9](operator/overlays/v23.9)
* [v24.3](operator/overlays/v24.3)
* [v24.6](operator/overlays/v24.6)

## Usage

If you have cloned the `gitops-catalog` repository, you can install NVIDIA GPU Operator based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```sh
oc apply -k gpu-operator-certified/operator/overlays/<channel>
```

Or, without cloning:

```sh
oc apply -k https://github.com/redhat-cop/gitops-catalog/gpu-operator-certified/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/gpu-operator-certified/operator/overlays/<channel>?ref=main
```
