# OpenShift AI / ML GitOps Catalog

[![Spelling](https://github.com/codekow/demo-ai-gitops-catalog/actions/workflows/spellcheck.yaml/badge.svg)](https://github.com/codekow/demo-ai-gitops-catalog/actions/workflows/spellcheck.yaml)
[![Linting](https://github.com/codekow/demo-ai-gitops-catalog/actions/workflows/linting.yaml/badge.svg)](https://github.com/codekow/demo-ai-gitops-catalog/actions/workflows/linting.yaml)

This project is a catalog of configurations used to provision infrastructure, on
OpenShift, that supports machine learning (ML) and artificial intelligence (AI) workloads.

The intention of this repository is to help support practical use of OpenShift for AI / ML workloads.

Please look at the [GitOps Catalog](https://github.com/redhat-cop/gitops-catalog) if you only need to automate an operator install.

***This repo is currently subject to frequent, breaking changes!***

## Prerequisites

- OpenShift 4.8+

[Red Hat Demo Platform](https://demo.redhat.com) Options (Tested)

- [AWS with OpenShift Open Environment](https://demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-ocp.prod&utm_source=webapp&utm_medium=share-link)
  - 1 x Control Plane - `m5.4xlarge`
  - 0 x Workers - `m5.2xlarge`
- [MLOps Demo: Data Science & Edge Practice](https://demo.redhat.com/catalog?item=babylon-catalog-prod/community-content.com-mlops-wksp.prod&utm_source=webapp&utm_medium=share-link)
- [Red Hat OpenShift Container Platform 4 Demo](https://demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.ocp4-demo.prod&utm_source=webapp&utm_medium=share-link)

### Tools

The following cli tools are required:

- `bash`, `git`
- `oc` - Download [mac](https://formulae.brew.sh/formula/openshift-cli), [linux](https://mirror.openshift.com/pub/openshift-v4/clients/ocp), [windows](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-windows.zip)
- `kubectl` (optional) - Included in `oc` bundle
- `kustomize` (optional) - Download [mac](https://formulae.brew.sh/formula/kustomize), [linux](https://github.com/kubernetes-sigs/kustomize/releases)

NOTE: `bash`, `git`, and `oc` are available in the [OpenShift Web Terminal](https://docs.openshift.com/container-platform/4.12/web_console/web_terminal/installing-web-terminal.html)

## Bootstrapping a Cluster

1. Verify you are logged into your cluster using `oc`.
1. Clone this repository to your local environment.

```sh
oc whoami
git clone < repo url >
```

### Cluster Quick Start for OpenShift GitOps

Use the following script:

```sh
# load functions
. scripts/functions.sh

# setup an enhanced web terminal on a default cluster
# alt cmd: until oc apply -k bootstrap/web-terminal; do : ; done
apply_firmly bootstrap/web-terminal

# setup a basic instance of argocd managing a default cluster
apply_firmly bootstrap/argo-managed

# setup a default cluster w/o argocd managing it
apply_firmly cluster/default
```

Setup a demo

```sh
# setup a dev spaces demo /w gpu
apply_firmly demos/devspaces-nvidia-gpu-autoscale

# setup a rhods demo /w gpu
apply_firmly demos/rhods-nvidia-gpu-autoscale

# install all the things
demo_all
```

Many common operational tasks are provided in the [scripts library](scripts/library/). You can run individual [functions](scripts/functions.sh) in a `bash` shell:

These functions are available in an [enhanced web terminal](components/configs/cluster/web-terminal/overlays/enhanced/kustomization.yaml) (see above)

```sh
# load functions
. scripts/functions.sh

get_functions
```

The `bootstrap.sh` script will:

- Install the [OpenShift GitOps Operator](components/operators/openshift-gitops-operator)
- Create an [ArgoCD instance](components/operators/openshift-gitops-operator/instance/base/openshift-gitops-cr.yaml) in the `openshift-gitops` namespace

<!-- ### Sealed Secrets Bootstrap

`bootstrap.sh` will attempt to deploy sealed-secrets and requires a sealed secret master key to manage existing deployments.  

If managing an already bootstrapped cluster, the sealed-secrets key must be obtained from the initial bootstrap (ask the person who initially setup the cluster).

The sealed secret(s) for bootstrap should be located at:

```sh
bootstrap/sealed-secrets-secret.yaml
```

If this is the first time bootstrapping a cluster, `bootstrap.sh` will deploy a new sealed-secrets controller and obtain a new secret if it does not exist. -->

## Additional Configurations

### Sandbox Namespace

The `sandbox` [namespace](components/configs/cluster/namespaces/instance/sandbox/namespace.yaml) is useable by all [authenticated users](components/configs/cluster/namespaces/instance/sandbox/rolebinding-edit.yaml). All objects in the sandbox are [cleaned out weekly](components/configs/cluster/sandbox-cleanup/sandbox-cleanup-cj.yaml).

## Contributions

Please run the following before submitting a PR / commit

```sh
scripts/lint.sh
```

## Additional Info

- [Misc Docs](docs) - not everything fits in your head

## External Links

- [GitOps Catalog](https://github.com/redhat-cop/gitops-catalog)
- [ArgoCD - Example](https://github.com/gnunn-gitops/cluster-config)
- [ArgoCD - Patterns](https://github.com/gnunn-gitops/standards)
