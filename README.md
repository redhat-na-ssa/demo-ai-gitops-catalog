# OpenShift AI / ML GitOps Catalog

[![Spelling](https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/actions/workflows/spellcheck.yaml/badge.svg)](https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/actions/workflows/spellcheck.yaml)
[![Linting](https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/actions/workflows/linting.yaml/badge.svg)](https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/actions/workflows/linting.yaml)

This project is a catalog of configurations used to provision infrastructure, on
OpenShift, that supports machine learning (ML) and artificial intelligence (AI) workloads.

The intention of this repository is to help support practical use of OpenShift for AI / ML workloads.

Please look at the [GitOps Catalog](https://github.com/redhat-cop/gitops-catalog) if you only need to automate an operator install.

In this repo, look at various [kustomized configs](components/configs) and [argo apps](components/argocd/apps) for ideas.

***This repo is currently subject to frequent, breaking changes!***

## Prerequisites

- OpenShift 4.8+
  - role: `cluster-admin` - for all [demo](demos) or [cluster](clusters) configs
  - role: `self-provisioner` - for namespaced components

[Red Hat Demo Platform](https://demo.redhat.com) Options (Tested)

- <a href="https://demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-ocp.prod&utm_source=webapp&utm_medium=share-link" target="_blank">AWS with OpenShift Open Environment</a>
  - 1 x Control Plane - `m6a.4xlarge`
  - 0 x Workers - `m6a.2xlarge`
- <a href="https://demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.ocp4-single-node.prod&utm_source=webapp&utm_medium=share-link" target="_blank">One Node OpenShift</a>
  - 1 x Control Plane - `m6a.4xlarge`
- <a href="https://demo.redhat.com/catalog?item=babylon-catalog-prod/community-content.com-mlops-wksp.prod&utm_source=webapp&utm_medium=share-link" target="_blank">MLOps Demo: Data Science & Edge Practice</a>

### Tools

The following cli tools are required:

- `bash`, `git`
- `oc` - Download [mac](https://formulae.brew.sh/formula/openshift-cli), [linux](https://mirror.openshift.com/pub/openshift-v4/clients/ocp), [windows](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-windows.zip)
- `kubectl` (optional) - Included in `oc` bundle
- `kustomize` (optional) - Download [mac](https://formulae.brew.sh/formula/kustomize), [linux](https://github.com/kubernetes-sigs/kustomize/releases)

NOTE: `bash`, `git`, and `oc` are available in the [OpenShift Web Terminal](https://docs.openshift.com/container-platform/4.12/web_console/web_terminal/installing-web-terminal.html)

The following are used to encrypt secrets and are optional:

- `age` - [Info](https://github.com/FiloSottile/age)
- `sops` - [Info](https://github.com/getsops/sops)

## Bootstrapping a Cluster

1. Verify you are logged into your cluster using `oc`.
1. Clone this repository

To a local environment

```sh
oc whoami
git clone < repo url >
```

Use an [OpenShift Web Terminal](https://docs.openshift.com/container-platform/4.12/web_console/web_terminal/installing-web-terminal.html)

NOTE: Due to a bug you may need to install the web terminal operator at version 1.7 and upgrade in order for it to work correctly.

```
YOLO_URL=https://raw.githubusercontent.com/redhat-na-ssa/demo-ai-gitops-catalog/main/scripts/library/term.sh
. <(curl -s "${YOLO_URL}")
term_init

# make custom web terminal persistent
apply_firmly bootstrap/web-terminal
```

NOTE: open a new terminal to activate new configuration

### Cluster Quick Start for OpenShift

Basic cluster config

```sh
# load functions
. scripts/functions.sh

# setup an enhanced web terminal on a default cluster
# alt cmd: until oc apply -k bootstrap/web-terminal; do : ; done
apply_firmly bootstrap/web-terminal

# setup a default cluster w/o argocd managing it
apply_firmly clusters/default
```

Setup a demo

```sh
# setup a dev spaces demo /w gpu
apply_firmly demos/devspaces-nvidia-gpu-autoscale

# setup a rhoai demo /w gpu
apply_firmly demos/rhoai-nvidia-gpu-autoscale
```

Setup an ArgoCD managed cluster

```sh
# setup a basic instance of argocd managing a default cluster
apply_firmly bootstrap/argo-managed
```

Many common operational tasks are provided in the [scripts library](scripts/library/). You can run individual [functions](scripts/functions.sh) in a `bash` shell:

These functions are available in an [enhanced web terminal](components/operators/web-terminal/instance/overlays/enhanced/kustomization.yaml) (see above)

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

### Workshops

This is currently under development

```sh
# load functions
. scripts/wip/workshop_functions.sh

# setup workshop with 25 users
workshop_setup 25
```

## Additional Configurations

### Sandbox Namespace

The `sandbox` [namespace](components/configs/cluster/namespaces/instance/sandbox/namespace.yaml) is useable by all [authenticated users](components/configs/cluster/namespaces/instance/sandbox/rolebinding-edit.yaml). All objects in the sandbox are [cleaned out weekly](components/configs/cluster/namespace-cleanup/overlays/sandbox/sandbox-cleanup-cj.yaml).

## Contributions

Please run the following before submitting a PR / commit

```sh
scripts/lint.sh
```

## Additional Info

- [Local Docs](docs)
- [Notes Dump](docs/notes/)

## External Links

- [GitOps Catalog](https://github.com/redhat-cop/gitops-catalog)
- [AI Pilot Gitops](https://github.com/redhat-na-stp-ai-practice/openshift-ai-pilot-gitops)
- [ArgoCD - Example](https://github.com/gnunn-gitops/cluster-config)
- [ArgoCD - Patterns](https://github.com/gnunn-gitops/standards)
