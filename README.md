# OpenShift AI / ML GitOps Catalog

[![Spelling](https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/actions/workflows/spellcheck.yaml/badge.svg)](https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/actions/workflows/spellcheck.yaml)
[![Linting](https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/actions/workflows/linting.yaml/badge.svg)](https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/actions/workflows/linting.yaml)

This project is a catalog of configurations used to provision infrastructure, on
OpenShift, that supports machine learning (ML) and artificial intelligence (AI) workloads.

The intention of this repository is to help support practical use of OpenShift for AI / ML workloads and provide a catalog of configurations / demos / workshops.

Please look at the [GitOps Catalog](https://github.com/redhat-cop/gitops-catalog) if you only need to automate an operator install.

In this repo, look at various [kustomized configs](components/cluster-configs) and [argo apps](components/argocd/apps) for ideas.

For issues with `oc apply -k` see the [known issues](#known-issues) section below.

## Prerequisites - Get a cluster

- OpenShift 4.14+
  - role: `cluster-admin` - for all [demo](demos) or [cluster](clusters) configs
  - role: `self-provisioner` - for namespaced components

[Red Hat Demo Platform](https://demo.redhat.com) Options (Tested)

NOTE: The node sizes below are the **recommended minimum** to select for provisioning

- <a href="https://demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.sandbox-ocp.prod&utm_source=webapp&utm_medium=share-link" target="_blank">AWS with OpenShift Open Environment</a>
  - 1 x Control Plane - `m6a.2xlarge`
  - 0 x Workers - `m6a.2xlarge`
- <a href="https://demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.ocp4-single-node.prod&utm_source=webapp&utm_medium=share-link" target="_blank">One Node OpenShift</a>
  - 1 x Control Plane - `m6a.2xlarge`
- <a href="https://demo.redhat.com/catalog?item=babylon-catalog-prod/community-content.com-mlops-wksp.prod&utm_source=webapp&utm_medium=share-link" target="_blank">MLOps Demo: Data Science & Edge Practice</a>

## Getting Started

### Install the [OpenShift Web Terminal](https://docs.openshift.com/container-platform/4.12/web_console/web_terminal/installing-web-terminal.html)

The following icon should appear in the top right of the OpenShift web console after you have installed the operator. Clicking this icon launches the web terminal.

![Web Terminal](docs/images/web-terminal.png "Web Terminal")

NOTE: Reload the page in your browser if you do not see the icon after installing the operator.

```sh
# bootstrap the enhanced web terminal
YOLO_URL=https://raw.githubusercontent.com/redhat-na-ssa/demo-ai-gitops-catalog/main/scripts/library/term.sh

. <(curl -s "${YOLO_URL}")

term_init
```

NOTE: open a new terminal to full activate the new configuration

---

### ALTERNATIVE - Use a local environment / shell

1. Verify you are logged into your cluster using `oc`.
1. Clone this repository

NOTE: See the [tools section below](#tools) for more info

```sh
# verify oc login
oc whoami

# git clone this repo
git clone https://github.com/redhat-na-ssa/demo-ai-gitops-catalog
cd demo-ai-gitops-catalog

# load functions into a bash shell
. scripts/functions.sh
```

## Apply Configurations / Demos

Setup basic cluster config

```sh
# load functions
. scripts/functions.sh

# setup a persistent enhanced web terminal on a default cluster
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

### Alternative - running `bootstrap.sh`

Running `scripts/bootstrap.sh` will allow you to select common options. This is a work in progress.

This script handles configurations that are not fully declarative, require imperative steps, or require user interaction.

## Cherry Picking Configurations

Various [kustomized configs](components/cluster-configs) can be applied individually.

[Operator installs](components/operators/) can be done quickly via `oc` - similar to the [GitOps Catalog](https://github.com/redhat-cop/gitops-catalog).

`oc apply -k` and `apply_firmly` can be used interchangeably in the examples below:

```sh
# setup htpasswd based login
oc apply -k components/cluster-configs/login/overlays/htpasswd

# disable self provisioner in cluster
oc apply -k components/cluster-configs/rbac/overlays/no-self-provisioner

# install minio w/ minio namespace
oc apply -k components/kustomized/minio/overlays/with-namespace

# install the nfs provisioner
oc apply -k components/kustomized/nfs-provisioner/overlays/default
```

Examples with operators that require CRDs

```sh
# setup serverless w/ instance
apply_firmly components/operators/serverless-operator/aggregate/default

# setup acs with a minimal configuration
apply_firmly components/operators/rhacs-operator/aggregate/minimal
```

## Common functions

Common operational tasks are provided in the [scripts library](scripts/library/). You can run individual [functions](scripts/functions.sh) in a `bash` shell:

NOTE: These functions are available in an [enhanced web terminal](components/operators/web-terminal/instance/overlays/enhanced/kustomization.yaml) - see [install above](#install-the-openshift-web-terminal)

```sh
# load functions
. scripts/functions.sh

get_functions
```

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

## Known Issues

`oc apply -k` commands may fail on the first try.

This is inherent to how Kubernetes handles [custom resources (CR)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) - A CR must be created **after it has been defined** via a [custom resource definition (CRD)](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions).

The solution... re-run the command until it succeeds.

The function `apply_firmly` is interchangeable with `oc apply -k` and is similar to the following shell command:

```sh
until oc apply -k < path to kustomization.yaml >; do : ; done
```

### Referencing this Catalog

***This repo is currently subject to frequent, breaking changes!***

Always reference with a commit hash or tag

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://github.com/redhat-na-ssa/demo-ai-gitops-catalog/components/kustomized/nvidia-gpu-verification/overlays/toleration-replicas-6?ref=v0.04
```

## Development

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

### Contributing

Please run the following before submitting a PR / commit

```sh
scripts/lint.sh
```

## Additional Info

<!-- ### Sandbox Namespace

If you have deployed a default cluster the `sandbox` [namespace](components/cluster-configs/namespaces/instance/sandbox/namespace.yaml) is useable by all [authenticated users](components/cluster-configs/namespaces/instance/sandbox/rolebinding-edit.yaml). All objects in the sandbox are [cleaned out weekly](components/cluster-configs/namespace-cleanup/overlays/sandbox/sandbox-cleanup-cj.yaml). -->

### Internal Docs

- [Local Docs](docs)
- [Notes Dump](docs/notes/)

## External Links

- [GitOps Catalog](https://github.com/redhat-cop/gitops-catalog)
- [Enhanced Web Terminal Container](https://github.com/redhat-na-ssa/ocp-web-terminal-enhanced)
- [AI Pilot Gitops](https://github.com/redhat-na-stp-ai-practice/openshift-ai-pilot-gitops)
- [ArgoCD - Example](https://github.com/gnunn-gitops/cluster-config)
- [ArgoCD - Patterns](https://github.com/gnunn-gitops/standards)
