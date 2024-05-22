# Notes - OVERVIEW

Overview of the features in Red Hat OpenShift 2.9 with dependencies.

|Component            |Purpose     |Dependency   |Resources          |Description      |
|---------------------|------------|-------------|-------------------|-----------------|
|operator             |            |             |                   |                 |
|dashboard            |management  |             |                   |                 |
|workbenches          |train       |             |                   |                 |
|datasciencepipelines |train       |S3 Store     |                   |                 |
|distributed workloads|train       |             |1.6 vCPU and 2 GiB |                 |
|                     |            |CodeFlare    |                   |Secures deployed Ray clusters and grants access to their URLs |
|                     |            |CodeFlare SDK|                   |controls the remote distributed compute jobs and infrastructure for any Python-based env|
|                     |            |Kuberay      |                   |KubeRay manages remote Ray clusters on OCP for running distributed workloads|
|                     |            |Kueue        |                   |Manages quotas, queuing and how distributed workloads consume them |
|modelmeshserving     |inference   |S3 Store     |                   |                 |
|kserve               |inference   |             |4 CPUs and 16 GB   |each model is deployed on a model server|
|                     |            |ServiceMesh  |4 CPUs and 16 GB   |                 |
|                     |            |Serverless   |4 CPUs and 16 GB   |                 |
|                     |            |Authorino    |                   |enable token authorization for models|

1. Central Dashboard for Development and Operations
1. Curated Workbench Images (incl CUDA, PyTorch, Tensorflow, code-server)
    1. Ability to add Custom Images
    1. Ability to leverage accelerators (such as NVIDIA GPU)
1. Data Science Pipelines (including Elyra notebook interface) (Kubeflow pipelines)
1. Model Serving using ModelMesh and Kserve.
    1. Ability to use Serverless and Event Driven Applications as wells as configure secure gateways (Knative, OpenSSL)
    1. Ability to manages traffic flow and enforce access policies
    1. Ability to use other runtimes for serving (TGIS, Caikit-TGIS, OpenVino)
    1. Ability to enable token authorization for models that you deploy on the platform, which ensures that only authorized parties can make inference requests to the models (Authorino)
1. Model Monitoring
1. Distributed workloads (CodeFlare Operator, CodeFlare SDK, KubeRay, Kueue)
    1. You can run distributed workloads from data science pipelines, from Jupyter notebooks, or from Microsoft Visual Studio Code files.
    1. Ability to deploy Ray clusters with mTLS default
    1. Ability to control the remote distributed compute jobs and infrastructure
    1. Ability to manage remote Ray clusters on OpenShift
    1. Ability to run distributed workloads from data science pipelines, from Jupyter notebooks, or from Microsoft Visual Studio Code files.

## Links

- [Docs - Link]()
- [Blog - Link]()

## Checklist

- [ ] Step 1
  - [ ] Step 1.a

## Details / Notes

```sh
# run shell commands

```

### Issues

[Reference](ISSUES.md) - [Jira](linktojira)

### Kustomized Code

[Code](../../components/configs/kustomized/rhods-config/)

### Rollback / Uninstall

```sh
oc delete -k components/configs/kustomized/rhods-config
```
