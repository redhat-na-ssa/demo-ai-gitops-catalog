# vault-secrets-operator

The Vault Secrets Operator (VSO) allows Pods to consume Vault secrets
natively from Kubernetes Secrets.

## Overview

The Vault Secrets Operator operates by watching for changes to its supported set of Custom Resource Definitions (CRD).
Each CRD provides the specification required to allow the *Operator* to synchronize a Vault Secrets to a Kubernetes Secret.
The *Operator* writes the *source* Vault secret data directly to the *destination* Kubernetes Secret, ensuring that any
changes made to the *source* are replicated to the *destination* over its lifetime. In this way, an application only needs
to have access to the *destination* secret in order to make use of the secret data contained within.

See the developer docs for more info [here](https://developer.hashicorp.com/vault/docs/platform/k8s/vso), including
[examples](https://developer.hashicorp.com/vault/docs/platform/k8s/vso/examples) and a
[tutorial](https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator)
for getting started.