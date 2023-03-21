# Cluster Bootstrap

[![Spelling](https://github.com/redhat-manufacturing/osdu-lab-gitops/actions/workflows/spellcheck.yaml/badge.svg)](https://github.com/redhat-manufacturing/osdu-lab-gitops/actions/workflows/spellcheck.yaml)
[![Linting](https://github.com/redhat-manufacturing/osdu-lab-gitops/actions/workflows/linting.yaml/badge.svg)](https://github.com/redhat-manufacturing/osdu-lab-gitops/actions/workflows/linting.yaml)

This project is designed to bootstrap an OpenShift cluster using ArgoCD.

This repo is subject to frequent breaking changes while we all learn patterns to use as a team.

## Prerequisites

### Client

In order to bootstrap this repository you must have the following cli tools:

- `oc` - Download [mac](https://formulae.brew.sh/formula/openshift-cli), [linux](https://mirror.openshift.com/pub/openshift-v4/clients)
- `kustomize` (optional) - Download [mac](https://formulae.brew.sh/formula/kustomize), [linux](https://github.com/kubernetes-sigs/kustomize/releases)

## Bootstrapping a Cluster

1. Verify you are logged into your cluster using `oc`.
1. Clone this repository to your local environment.

```
oc whoami
git clone <repo>
```

### Quick Start

Execute the following script:

```sh
./scripts/bootstrap.sh
```

The `bootstrap.sh` script will:

- Install the OpenShift GitOps Operator
- Create an ArgoCD instance in the `openshift-gitops` namespace
- Bootstrap a set of ArgoCD applications to configure the cluster

### Sealed Secrets Bootstrap

`bootstrap.sh` will attempt to deploy sealed-secrets and requires a sealed secret master key to manage existing deployments.  

If managing an already bootstrapped cluster, the sealed-secrets key must be obtained from the initial bootstrap (ask the person who initially setup the cluster).

The sealed secret(s) for bootstrap should be located at:

```sh
bootstrap/base/sealed-secrets-secret.yaml
```

If this is the first time bootstrapping a cluster, `bootstrap.sh` will deploy a new sealed-secrets controller and obtain a new secret if it does not exist.

## Additional Configurations

### Sandbox Namespace

The `sandbox` [namespace](components/configs/namespaces/instance/sandbox/sandbox-namespace.yaml) is useable by all [authenticated users](components/configs/namespaces/instance/sandbox/sandbox-edit-rolebinding.yaml). All objects in the sandbox are [cleaned out weekly](components/configs/simple/sandbox-cleanup/sandbox-cleanup-cj.yml).

## Additional Info

- [Kludges Script](scripts/kludges.sh) - Making things work since 1970-01-01
- [Using this repo effectively](docs/APPS.md)
- [Fix GitHub Oauth](docs/IDM.md)
- [ArgoCD - Repo Specific](docs/ARGOCD.md)

## External Links

- [ArgoCD - Example](https://github.com/gnunn-gitops/cluster-config)
- [ArgoCD - Patterns](https://github.com/gnunn-gitops/standards)
