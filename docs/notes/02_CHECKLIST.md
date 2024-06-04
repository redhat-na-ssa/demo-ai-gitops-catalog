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
  - [ ] Create the ServiceMeshMember object in the istio-system namespace
  - [ ] Define a KnativeServing object in a YAML file 
  - [ ] Create the KnativeServing object in the specified knative-serving namespace
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
  - [ ] TODO Adding a CA bundle
    - [ ] TODO
  - [ ] TODO Enabling GPU support in OpenShift AI
      - [ ] Install NFD operator
      - [ ] Configure NFD operator
      - [ ] NVIDIA
        - [ ] Install NVIDIA GPU Operator
        - [ ] Configure operator
          - [ ] Time-slicing
          - [ ] MIG
          - [ ] Hybrid
      - [ ] Intel Gaudi
        - [ ] Install Habana Operator
        - [ ] Configure operator
          - [ ] 
      - [ ] AMD
        - [ ] Install AMD GPU Operator
        - [ ] Configure operator
            - [ ] Partitioning
  - [ ] TODO Configuring distributed workloads
    - [ ] TODO
  - [ ] Demonstrate Installation and Configuration Declarative Automation (Kustomize, Ansible, Bash, etc.)

## Administrative Configurations for RHOAI

- [ ] Create, push and import a custom notebook image
- [ ] Configure Cluster Settings
  - [ ] Model Serving Platforms
  - [ ] PVC Size
  - [ ] Stop Idle Notebooks
  - [ ] Usage Data Collection
  - [ ] Notebook Pod Toleration
- [ ] Add a new Accelerator Profile
- [ ] Add a new Serving Runtimes
- [ ] Configure User and Admin groups

## Tutorials

- [ ] Demonstrate Fraud Deteciton Demo
- [ ] Demonstrate Distributed Workloads Demo

source:

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
