# Notes - Template

Demonstrate Distributed Workloads

## Checklist 

- [ ] Running Distributed Workloads
  - [ ] From Notebooks
    - [ ] Clone the CodeFlare SDK notebooks to the Fraud demo workbench
    - [ ] From the terminal, login into the cluster
    - [ ] Run a distributed workload job
  - [ ] From Pipelines

### Running distributed data science workloads from notebooks
(source)[https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/working_with_distributed_workloads/running-distributed-workloads_distributed-workloads]

Access the RHOAI Dashboard

Create a data science project that contains a workbench that is running one of the default notebook images, for example, the Standard Data Science notebook. (not code-server)

In the JupyterLab interface, click Git > Clone a Repository

In the "Clone a repo" dialog, enter `https://github.com/project-codeflare/codeflare-sdk.git`

In the JupyterLab interface, in the left navigation pane, double-click codeflare-sdk.

Double-click demo-notebooks.

Double-click guided-demos.

#### Update each example demo notebook as follows: 

Update the import section to import the generate_cert
```python
# Import pieces from codeflare-sdk
from codeflare_sdk import Cluster, ClusterConfiguration, TokenAuthentication, generate_cert
```

Update the following values from your `oc login` command values
`oc login --token=<YOUR_TOKEN> --server=<YOUR_API_URL>`

```python
# Create authentication object for user permissions
# IF unused, SDK will automatically check for default kubeconfig, then in-cluster config
# KubeConfigFileAuthentication can also be used to specify kubeconfig path manually
auth = TokenAuthentication(
    token = "XXXXX",  # replace with <YOUR_TOKEN>
    server = "XXXXX", # replace with <YOUR_API_URL>
    skip_tls=False    # change to True to bypass certificate
)
auth.login()
```

![IMPORTANT]
You can also login into OpenShift from the Workbench Terminal and bypass running the above steps in the notebooks
`oc login --insecure-skip-tls-verify=true --token=XXXX --server=XXXX`

![NOTE]
It may also be helpful to ignore the warnings Jupyter displays
```python
import warnings
warnings.filterwarnings('ignore')
```


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
