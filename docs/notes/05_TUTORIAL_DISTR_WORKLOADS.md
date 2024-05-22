# Notes - Template

State your goal

## Checklist 

- [ ] Running Distributed Workloads
  - [ ] From Notebooks
    - [ ] Clone the CodeFlare SDK notebooks to the Fraud demo workbench
    - [ ] From the terminal, login into the cluster
    - [ ] Run a distributed workload job
  - [ ] From Pipelines

### Running distributed data science workloads from notebooks

To run a distributed data science workload from a notebook, launch a notebook (not code-server).

Clone in the CodeFlare SDK

`git clone https://github.com/project-codeflare/codeflare-sdk.git`

Go to demo-notebook > guided-demos

Login into OpenShift from the Terminal.
`oc login --insecure-skip-tls-verify=true --token=XXXX --server=XXXX`

Launch the notebook

- add a cell

```
import warnings
warnings.filterwarnings('ignore')
```

- set the login cell to Raw (do not run)
- update the cluster config (namespace and add the local_queue)

```
# Create and configure our cluster object
# The SDK will try to find the name of your default local queue based on the annotation "kueue.x-k8s.io/default-queue": "true" unless you specify the local queue manually below
cluster = Cluster(ClusterConfiguration(
    name='fraud-detection-ray',
    namespace='fraud-detection', # Update to your namespace,
    local_queue="local-queue-test",
    num_workers=2,
    min_cpus=1,
    max_cpus=1,
    min_memory=4,
    max_memory=4,
    num_gpus=0,
    image="quay.io/project-codeflare/ray:latest-py39-cu118",
    write_to_file=False, # When enabled Ray Cluster yaml files are written to /HOME/.codeflare/resources 
    # local_queue="local-queue-name" # Specify the local queue manually
))
```

### Running distributed data science workloads from data science pipelines

## Links

- [Docs - Link]()
- [Blog - Link]()

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
