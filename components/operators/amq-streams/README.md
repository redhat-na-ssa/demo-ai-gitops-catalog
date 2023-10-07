# Red Hat Integration - AMQ Streams

Install Red Hat Integration - AMQ Streams.

Do not use the `base` directory directly, as you will need to patch the `channel` based on the version of OpenShift you are using, or the version of the operator you want to use.

The current *overlays* available are for the following channels:

* [amq-streams-2.2.x](operator/overlays/amq-streams-2.2.x)
* [amq-streams-2.3.x](operator/overlays/amq-streams-2.3.x)
* [amq-streams-2.4.x](operator/overlays/amq-streams-2.4.x)
* [amq-streams-2.5.x](operator/overlays/amq-streams-2.5.x)
* [amq-streams-2.x](operator/overlays/amq-streams-2.x)
* [stable](operator/overlays/stable)

## Usage

If you have cloned the `gitops-catalog` repository, you can install Red Hat Integration - AMQ Streams based on the overlay of your choice by running from the root (`gitops-catalog`) directory.

```
oc apply -k amq-streams/operator/overlays/<channel>
```

Or, without cloning:

```
oc apply -k https://github.com/redhat-cop/gitops-catalog/amq-streams/operator/overlays/<channel>
```

As part of a different overlay in your own GitOps repo:

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-cop/gitops-catalog/amq-streams/operator/overlays/<channel>?ref=main
```
