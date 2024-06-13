# Notes 

This is checklist of the technical steps needed to complete the installation of Red Hat OpenShift 2.9

## Installing the Red Hat OpenShift AI "RHOAI" Operator

- [ ] Adding administrative users 
  - [ ] Create an htpasswd file to store the user and password information
  - [ ] Create a secret to represent the htpasswd file
  - [ ] Define the custom resource for htpasswd
  - [ ] Apply the resource to the default OAuth configuration to add the identity provider
  - [ ] As kubeadmin, assign the cluster-admin role to perform administrator level tasks
  - [ ] Log in to the cluster as a user from your identity provider, entering the password when prompted
- [ ] Installing the Red Hat OpenShift AI Operator by using the CLI
  - [ ] Create a namespace YAML file
  - [ ] Apply the namespace object
  - [ ] Create an OperatorGroup object custom resource (CR) file
  - [ ] Apply the OperatorGroup object
  - [ ] Create a Subscription object CR file
  - [ ] Apply the Subscription object
  - [ ] Verification
    - [ ] Check the installed operators
    - [ ] Check the created projects
- [ ] Installing and managing Red Hat OpenShift AI components
  - [ ] Create a DataScienceCluster object custom resource (CR) file
  - [ ] Apply the DSC object
- [ ] Adding a BA bundle
  - [ ] Set environment variables
  - [ ] Create an OpenSSL config
  - [ ] Generate a root certificate
  - [ ] Verify the wildcard certificate
  - [ ] Add the custom root signed certificate to the customCABundle
  - [ ] Verify the configuration
- [ ] Installing KServe dependencies
  - [ ] Create the required namespace for Red Hat OpenShift Service Mesh
  - [ ] Define the required subscription for the Red Hat OpenShift Service Mesh Operator
  - [ ] Create the Service Mesh subscription to install the operator
  - [ ] Define a ServiceMeshControlPlane object in a YAML file 
  - [ ] Create the servicemesh control plane object
  - [ ] Verify the pods are running for the service mesh control plane, ingress gateway, and egress gateway
  - [ ] Creating a Knative Serving instance
  - [ ] Install the Serverless Operator
  - [ ] Define a ServiceMeshMember object in a YAML file
  - [ ] Apply the ServiceMeshMember object in the istio-system namespace
  - [ ] Define a KnativeServing object in a YAML file 
  - [ ] Apply the KnativeServing object in the specified knative-serving namespace
  - [ ] TODO use a TLS certificate to secure the mapped service 
  - [ ] Verification
    - [ ] Review the default ServiceMeshMemberRoll object in the istio-system namespace and confirm that it includes the knative-serving namespace
    - [ ] Verify creation of the Knative Serving instance
  - [ ] Creating secure gateways for Knative Serving
    - [ ] Set environment variables to define base directories for generation of a wildcard certificate and key for the gateways.
    - [ ] Set an environment variable to define the common name used by the ingress controller of your OpenShift cluster
    - [ ] Create the required base directories for the certificate generation, based on the environment variables that you previously set
    - [ ] Create the OpenSSL configuration for generation of a wildcard certificate
    - [ ] Generate a root certificate
    - [ ] Generate a wildcard certificate signed by the root certificate
    - [ ] Verify the wildcard certificate
    - [ ] Export the wildcard key and certificate that were created by the script to new environment variables
    - [ ] Create a TLS secret in the istio-system namespace using the environment variables that you set for the wildcard certificate and key
    - [ ] Create a serverless-gateways.yaml YAML file 
    - [ ] Apply the serverless-gateways.yaml file to create the defined resources
    - [ ] Review the gateways that you created
  - [ ] Manually adding an authorization provider
    - [ ] Create subscription for the Authorino Operator
    - [ ] Install the Authorino operator
    - [ ] Create a namespace to install the Authorino instance
    - [ ] Enroll the new namespace for the Authorino instance in your existing OpenShift Service Mesh instance
    - [ ] Create the ServiceMeshMember resource on your cluster
    - [ ] Configure an Authorino instance, create a new YAML file as shown
    - [ ] Create the Authorino resource on your cluster
    - [ ] Patch the Authorino deployment to inject an Istio sidecar, which makes the Authorino instance part of your OpenShift Service Mesh instance
    - [ ] Check the pods (and containers) that are running in the namespace that you created for the Authorino instance, as shown in the following example
    - [ ] Configure the OpenShift Service Mesh instance to use Authorino
      - [ ] Create a new YAML file to patch the SM Control Plane
      - [ ] Use the oc patch command to apply the YAML file to your OpenShift Service Mesh instance   
      - [ ] Verification
        - [ ] Inspect the ConfigMap object for your OpenShift Service Mesh instance
    - [ ] Configuring authorization for KServe
      - [ ] Create a new YAML file for
      - [ ] Create the AuthorizationPolicy resource in the namespace for your OpenShift Service Mesh instance
      - [ ] Create another new YAML file with the following contents:
      - [ ] Create the EnvoyFilter resource in the namespace for your OpenShift Service Mesh instance
      - [ ] Check that the AuthorizationPolicy resource was successfully created
      - [ ] Check that the EnvoyFilter resource was successfully created
  - [ ] Enabling GPU support in OpenShift AI
    - [ ] Adding a GPU node to an existing OpenShift Container Platform cluster
      - [ ] View the machines and machine sets that exist in the openshift-machine-api namespace
      - [ ] Make a copy of one of the existing compute MachineSet definitions 
      - [ ] Update the necessary fields and save the file
      - [ ] Apply the configuration to create the gpu machine
      - [ ] Verify the gpu machineset you created is running
      - [ ] View the Machine object that the machine set created 
      - [ ] Deploy the Node Feature Discovery Operator
        - [ ] List the available operators for installation
        - [ ] Create a Namespace object YAML file
        - [ ] Apply the Namespace object
        - [ ] Create an OperatorGroup object YAML file
        - [ ] Apply the OperatorGroup object
        - [ ] Create a Subscription object YAML file
        - [ ] Apply the Subscription object
        - [ ] Verify the operator is installed and running
        - [ ] Create an NodeFeatureDiscovery instance
        - [ ] Verify the NFD pods are running
        - [ ] Verify the NVIDIA GPU is discovered
      - [ ] Install NVIDIA GPU Operator
        - [ ] List the available operators for installation
        - [ ] Create a Namespace CR
        - [ ] Apply the Namepsace object YAML file 
        - [ ] Create an OperatorGroup CR
        - [ ] Apply the OperatorGroup YAML file
        - [ ] Run the following command to get the channel value required
        - [ ] Run the following commands to get the startingCSV value
        - [ ] Create the following Subscription CR 
        - [ ] Apply the Subscription CR
        - [ ] Verify an install plan has been created
        - [ ] Create the cluster policy
        - [ ] Apply the clusterpolicy
        - [ ] Verify the successful installation 
      - [ ] (Optional) Running a sample GPU Application
        - [ ] Create the sample app
        - [ ] Check the logs of the container
        - [ ] Get information about the GPU
        - [ ] View the new pods
        - [ ] Run the nvidia-smi
      - [ ] Download the latest NVIDIA DCGM Exporter Dashboard
        - [ ] Download the NVIDIA DCGM Exporter Dashboard
        - [ ] Create a configmap
        - [ ] Label the config map to expose the Admin dashboard
        - [ ] Label the config map to expose the Developer dashboard
        - [ ] View the created resource and verify the labels
      - [ ] Configuring GPUs with time slicing
        - [ ] Create the slicing configurations
        - [ ] Apply the device plugin configuration
        - [ ] Patch the GPU Operator ConfigMap
        - [ ] Label all nodes with GPU
        - [ ] Verify the labels configured
      - [ ] Configure Taints and Tolerations
        - [ ] Taint the GPU nodes
        - [ ] Drain the nodes
        - [ ] Allow the node to be scheduleable 
        - [ ] Taint the machinesetsde
      - [ ] (Optional) Configuring the cluster autoscaler
  - [ ] Configuring distributed workloads
    - [ ] Verify necessary pods are running
    - [ ] Configure quota management for distributed workloads
      - [ ] Create an empty Kueue resource flavor default-flavor
      - [ ] Apply the configuration
      - [ ] Create a cluster queue to manage the empty Kueue resource flavor
      - [ ] Apply the configuration
      - [ ] Create a local queue that points to your cluster queue
      - [ ] Apply the configuration
      - [ ] Verify the local queue is created
    - [ ] Review the CodeFlare operator configurations
      - [ ] Review/Patch the kuberay configuration options
  - [ ] Demonstrate Installation and Configuration Declarative Automation (Kustomize, Ansible, Bash, etc.)

## Administrative Configurations for RHOAI

- [ ] Create, push and import a custom notebook image
- [ ] Configure Cluster Settings
  - [ ] Model Serving Platforms
  - [ ] PVC Size
  - [ ] Stop Idle Notebooks
  - [ ] Usage Data Collection
  - [ ] Notebook Pod Toleration
- [ ] Add an Accelerator Profile
  - [ ] Delete the migration-gpu-status ConfigMap
  - [ ] Restart the dashboard replicaset
  - [ ] Check the acceleratorprofiles
- [ ] Add a new Serving Runtimes
- [ ] Configure User and Admin groups

## Tutorials

- [ ] Demonstrate Fraud Detection Demo
- [ ] Demonstrate Distributed Workloads Demo
  - [ ] Access the RHOAI Dashboard
  - [ ] Create a workbench
  - [ ] Clone in the codeflare-sdk github repo
  - [ ] Navigate to the guided-demos
  - [ ] Update the notebook import, auth, cluster values
  - [ ] Access the RayCluster Dashboard
  - [ ] complete the `0_basic_ray.ipynb`
  - [ ] complete the `1_cluster_job_client.ipynb`
  - [ ] complete the `2_basic_interactive.ipynb`

## Links

- [Install RHOAI Self-Managed - Link](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install#installing-openshift-data-science-operator-using-cli_operator-install )
- [Blog - Link]()

### Issues

[Reference](ISSUES.md) - [Jira](linktojira)

### Kustomized Code

[Code](../../components/configs/kustomized/rhods-config/)

### Rollback / Uninstall

```sh
oc delete -k components/configs/kustomized/rhods-config
```
