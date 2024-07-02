# openshift-pipelines-operator-rh

Red Hat OpenShift Pipelines is a cloud-native continuous integration and delivery
(CI/CD) solution for building pipelines using [Tekton](https://tekton.dev).
Tekton is a flexible Kubernetes-native open-source CI/CD framework, which
enables automating deployments across multiple platforms (Kubernetes,
serverless, VMs, etc) by abstracting away the underlying details.

## Features

* Standard CI/CD pipelines definition
* Build images with Kubernetes tools such as S2I, Buildah, Buildpacks, Kaniko, etc
* Deploy applications to multiple platforms such as Kubernetes, serverless and VMs
* Easy to extend and integrate with existing tools
* Scale pipelines on-demand
* Portable across any Kubernetes platform
* Designed for microservices and decentralized team
* Integrated with OpenShift Developer Console

## Installation

_Red Hat OpenShift Pipelines Operator_ gets installed into a single namespace (openshift-operators) which would then install _Red Hat OpenShift Pipelines_ into the openshift-pipelines namespace. _Red Hat OpenShift Pipelines_ is however cluster-wide and can run pipelines created in any namespace.

### Components

- Tekton Pipelines: v0.59.1
- Tekton Triggers: v0.27.0
- Pipelines as Code: v0.27.1
- Tekton Chains: v0.20.1
- Tekton Hub (tech-preview): v1.17.0
- Tekton Results (tech-preview): v0.10.0
- Manual Approval Gate (tech-preview): v0.2.2

## Getting Started

In order to get familiar with _OpenShift Pipelines_ concepts and create your first pipeline, follow the [OpenShift Pipelines Docs](https://docs.openshift.com/pipelines/1.15/create/creating-applications-with-cicd-pipelines.html).

## CLI (tkn)

Tekton Pipelines cli project provides a CLI (tkn) for interacting with OpenShift Pipelines.

[Download tkn](/command-line-tools) (links will be available on `command line tools` page after this operator is installed).
