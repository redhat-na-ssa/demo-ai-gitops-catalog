# rhacs-operator

## Why use Red Hat Advanced Cluster Security for Kubernetes?

Protecting cloud-native applications requires significant changes in how we approach security—we must apply controls earlier in the application development life cycle, use the infrastructure itself to apply controls, and keep up with increasingly rapid release schedules.


Red Hat® Advanced Cluster Security for Kubernetes, powered by StackRox technology, protects your vital applications across build, deploy, and runtime. Our software deploys in your infrastructure and integrates with your DevOps tooling and workflows to deliver better security and compliance. The policy engine includes hundreds of built-in controls to enforce DevOps and security best practices, industry standards such as CIS Benchmarks and National Institute of Standards Technology (NIST) guidelines, configuration management of both containers and Kubernetes, and runtime security.

Red Hat Advanced Cluster Security for Kubernetes provides a Kubernetes-native architecture for container security, enabling DevOps and InfoSec teams to operationalize security.

## Features and Benefits

**Kubernetes-native security:**
1. Increases protection.
1. Eliminates blind spots, providing staff with insights into critical vulnerabilities and threat vectors.
1. Reduces time and costs.
1. Reduces the time and effort needed to implement security and streamlines security analysis, investigation, and remediation using the rich context Kubernetes provides.
1. Increases scalability and portability.
1. Provides scalability and resiliency native to Kubernetes, avoiding operational conflict and complexity that can result from out-of-band security controls.

## Using the RHACS Operator

**RHACS comes with two custom resources:**

1. **Central Services** - Central is a deployment required on only one cluster in your environment. Users interact with RHACS via the user interface or APIs on Central. Central also sends notifications for violations and interacts with integrations. Users may select exposures for Central that best meet their environment.

2. **Secured Cluster Services** - Secured cluster services are placed on each cluster you manage and report back to Central. These services allow users to enforce policies and monitor your OpenShift and Kubernetes clusters. Secured Cluster Services come as two Deployments (Sensor and Admission Controller) and one DaemonSet (Collector).

### Central Services Explained

| Service                          | Deployment Type | Description     |
| :------------------------------- | :-------------- | :-------------- |
| Central                          | Deployment      | Users interact with Red Hat Advanced Cluster Security through the user interface or APIs on Central. Central also sends notifications for violations and interacts with integrations. |
| Scanner                          | Deployment      | Scanner is a Red Hat developed and certified image scanner. Scanner analyzes and reports vulnerabilities for images. Scanner uses HPA to scale the number of replicas based on workload. |
| Scanner DB                       | Deployment      | Scanner DB is a cache for vulnerability definitions to serve vulnerability scanning use cases throughout the software development life cycle. |

### Secured Cluster Services Explained

| Service                          | Deployment Type | Description     |
| :------------------------------- | :-------------- | :-------------- |
| Sensor                           | Deployment      | Sensor analyzes and monitors Kubernetes in secured clusters. |
| Collector                        | DaemonSet       | Analyzes and monitors container activity on Kubernetes nodes.|
| Admission Controller             | Deployment      | ValidatingWebhookConfiguration for enforcing policies in the deploy lifecycle. |

### Central Custom Resource

Central Services is the configuration template for RHACS Central deployment. For all customization options, please visit the RHACS documentation.

### SecuredCluster Custom Resource

SecuredCluster is the configuration template for the RHACS Secured Cluster services.

#### Installation Prerequisites

Before deploying a SecuredCluster resource, you need to create a cluster init bundle secret.

- **Through the RHACS UI:** To create a cluster init bundle secret through the RHACS UI, navigate to `Platform Configuration > Clusters`, and then click `Manage Tokens` in the top-right corner. Select `Cluster Init Bundle`, and click `Generate Bundle`. Select `Download Kubernetes secrets file`, and store the file under a name of your choice (for example, `cluster-init-secrets.yaml`).
- **Through the `roxctl` CLI:** To create a cluster init bundle secret through the `roxctl` command-line interface, run `roxctl central init-bundles generate <name> --output-secrets <file name>`. Choose any `name` and `file name` that you like.

Run `oc project` and check that it reports the correct namespace where you intend to deploy SecuredCluster. In case you want to install SecuredCluster to a different namespace, select it by running `oc project <namespace>`.
Then, run `oc create -f init-bundle.yaml`. If you have chosen a name other than `init-bundle.yaml`, specify that file name instead.

#### Required Fields

The following attributes are required to be specified. For all customization options, please visit the RHACS documentation.

| Parameter          | Description     |
| :----------------- | :-------------- |
| `clusterName`      | The name given to this secured cluster. The cluster will appear with this name in RHACS user interface. |
| `centralEndpoint`  | This field should specify the address of the Central endpoint, including the port number. `centralEndpoint` may be omitted if this SecuredCluster Custom Resource is in the same cluster and namespace as Central. |
