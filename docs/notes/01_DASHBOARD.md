# Notes - DASHBOARD

Deep dive into the Red Hat OpenShift AI 2.9 Dashboard

>     One of the most important concepts is the Data Science Project = OpenShift Project > Kubernetes namespace. A Kubernetes namespace is the central vehicle by which access to resources/objects for regular users is managed.

1. Applications
    1. Enabled (Jupyter) - a one-off notebook run in isolation
    1. Explore
1. Data Science Projects - a data science workflow
    1. Storage - 1:N persistent volumes provided by S3-compatible object storage buckets that retains the files and data you’re working on within a workbench
        1. Storage - bucket for storing your models and data
        1. Artifacts - bucket for your pipeline artifacts
    1. Data Connections - configuration parameters that are required to connect to a data source
        1. Object storage connection - To store pipeline artifacts. Must be S3 compatible
            1. Endpoint URL
            1. Access key
            1. Secret key
            1. Region
            1. Bucket name
        1. Database - To store pipeline data Use the default database to store data on your cluster, or connect to an external database.
            1. Use default database stored on your cluster
            1. Connect to external MySQL database
    1. Pipelines - data science pipelines that are executed within the project
        1. Pipeline server enables the creation, storing and management of pipelines
        1. Pipeline is the python code workflow or DAG that data scientists generate
    1. Workbenches - an isolated area where you can work with models in your preferred IDE, such as a Jupyter notebook, add accelerators and data connections, create pipelines, and add cluster storage in your workbench. [docs](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/working_on_data_science_projects/creating-and-importing-notebooks_notebooks#notebook-images-for-data-scientists_notebooks)
        1. IDE Images
            1. Minimal Python
            1. Standard Data Science
            1. CUDA
            1. TensorFlow
            1. TrustyAI
            1. HabanaAI
            1. code-server (Elyra-based pipelines are not available)
        1. Deployment Size
            1. Small 2CPU, 8Gi
            1. Medium 3CPU 24Gi
            1. Large 7CPU 56Gi
            1. X Large 15CPU 120Gi
        1. Accelerator Profiles
            1. NVIDIA GPUs
            1. Habana Gaudi HPUs
        1. Environment Variables
        1. Cluster Storage
        1. Data Connections
            1. Create new data connections
            1. Use existing data connections
    1. Models - enables a model servers per data science project serve a trained model for real-time inference
        1. The model serving type can be changed until the first model is deployed from this project. After that, if you want to use a different model serving type, you must create a new project.
    1. Permissions - which users and groups can access the project
1. Data Science Pipelines - platforms for building and deploying portable and scalable machine-learning (ML) workflows visually with Elyra or using kfp SDK.
    1. Run Types
        1. Once
        1. Period
        1. Cron
    1. Schedule
        1. Max concurrent runs
        1. Time frame
        1. Catchup if behind schedule
    1. Review the pipeline success
        1. Graph
        1. YAML
1. Distributed Workload Metrics - 
    1. Distributed Workloads - train complex machine-learning models or process data more quickly, by distributing  jobs on multiple worker nodes in parallel
        1. In 2.9 release of OpenShift AI, the only accelerators supported for distributed workloads are NVIDIA GPUs.
1. Model Serving - each project/workbench, you can specify only one model serving platform
    1. Single-model serving - Each model in the project is deployed on its own model server - suitable for large models or models that need dedicated resources.
    1. Multi-model serving - All models in the project are deployed on the same model server - suitable for sharing resources amongst deployed models.
1. Resources
1. Settings
    1. Notebook Images
    1. Cluster Settings
        1. Model serving platforms
            1. single-model serving platform
            1. multi-model serving platform
        1. PVC default sizes attached to notebooks from 1 GiB to 16384 GiB
        1. Stop idle notebooks between 10 minutes to 1000 hours
        1. Allow collection of usage data
        1. Notebook pod tolerations on tainted nodes
    1. Accelerator Profiles
        1. Details - An identifier is a unique string that names a specific hardware accelerator resource "nvidia.com/gpu" maps to 
        1. Tolerations - applied to pods and allow the scheduler to schedule pods with matching taints (key=nvidia-gpu-only) found on the MachineSets labels (cluster-api/accelerator=nvidia-gpu)
    1. Serving Runtimes - supports REST and gRPC API protocols
        1. Caikit TGIS ServingRuntimes for KServe for REST
            1. Serialized models:
                1. caitkit
        1. OpenVINO Model Server (single-model, multi-model) for REST 
            1. Serialized models:
                1. openvino v1
                1. onnx v1
                1. tensorflow v1, v2
                1. paddle v2
                1. pytorch v2
        1. TGIS Standalone ServingRuntime for KServe for gRPC
            1. Serialized models:
                1. pytorch
    1. User Management
        1. admin groups
        1. user groups


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
