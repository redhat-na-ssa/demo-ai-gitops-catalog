# AI / ML GitOps Catalog

[![Spelling](https://github.com/codekow/demo-ai-gitops-catalog/actions/workflows/spellcheck.yaml/badge.svg)](https://github.com/codekow/demo-ai-gitops-catalog/actions/workflows/spellcheck.yaml)
[![Linting](https://github.com/codekow/demo-ai-gitops-catalog/actions/workflows/linting.yaml/badge.svg)](https://github.com/codekow/demo-ai-gitops-catalog/actions/workflows/linting.yaml)

This project is a catalog of configurations used to provision infrastructure, on 
OpenShift, that supports machine learning (ML) and artificial intelligence (AI) workloads.

NOTICE: This repo is subject to frequent breaking changes

## Prerequisites

- OpenShift 4.8+

### Tools

The following cli tools are required:

- `oc` - Download [mac](https://formulae.brew.sh/formula/openshift-cli), [linux](https://mirror.openshift.com/pub/openshift-v4/clients)
  - `kubectl` (optional) - Included in above bundle
- `kustomize` (optional) - Download [mac](https://formulae.brew.sh/formula/kustomize), [linux](https://github.com/kubernetes-sigs/kustomize/releases)
