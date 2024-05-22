# Notes - Template

This is checklist of the technical steps needed to complete the installation of Red Hat OpenShift 2.9

- [ ] create cluster-admin, because 'kubeadmin' account is not permitted by name
  - [ ] create cluster-admin via htpass
  - [ ] create secret for htpass
  - [ ] create and apply htpass custom resource
  - [ ] test login as cluster-admin
  - [ ] as Kubeadmin, add cluster-admin role
  - [ ] login as cluster-admin
- [ ] install the operator
  - [ ] create project redhat-ods-operator
  - [ ] create operator-group for redhat-operator
  - [ ] create a subscription for the redhat-ods-operator
- [ ] install the components
  - [ ] identify components
    - [ ] all
    - [ ] train-only
    - [ ] infer-only
  - [ ] ServiceMesh
    - [ ] verify/create istio-system project
    - [ ] install the servicemesh operator
    - [ ] create a ServiceMeshControlPlane
  - [ ] Serverless
    - [ ] install the operator
    - [ ] create knative-serving project for openshift-serverless
    - [ ] create the operator-group for openshift-serverless
    - [ ] create the subscription for serverless-operator
    - [ ] create the ServiceMeshMember object for knative-serving
    - [ ] create the knativeserving custom resource to inject and enable the istio side car
    - [ ] create a secure gateway for knative-serving with OpenSSL
      - [ ] create dir for wildcard certs and keys
      - [ ] create the OpenSSL configuration the wildcard certificate
      - [ ] generate a root certificate
      - [ ] generate a wildcard certificate signed by the root certificate
    - [ ] create a TLS secret in the istio-system namespace
            - [ ] create a gateways.yaml to define the service and ingress gateway w/ TLS secret
            - [ ] verify the the local and ingress gateways 
  - [ ] install the components
    - [ ] configure servicemesh, servleress and authorino to manual
      - [ ] change servicemesh to unmanaged in the default-dsci
      - [ ] change the kserve to managed in the default-dsc
      - [ ] change the kserve serving to unmanaged in the default-dcs
  - [ ] install authorino
    - [ ] apply the authorino subscription
    - [ ] create an authorino instance
      - [ ] create the redhat-ods-applications-auth-provider project
      - [ ] enroll the authorino project with service mesh
      - [ ] create an authorino instance 
      - [ ] patch the deployment to inject the istio sidecar to include apart of service mesh
      - [ ] Configure an Service Mesh instance to use Authorino as an extension provider
      - [ ] Create the AuthorizationPolicy resource in the namespace for your OpenShift Service Mesh instance
      - [ ] Create the EnvoyFilter resource in the namespace for your OpenShift Service Mesh instance
  - [ ] add a CA bundle
    - [ ] use self-signed certificates in a custom CA bundle separate from a cluster-wide bundle
  - [ ] Enabling the single-model serving platform via the Dashboard
  - [ ] Enabling GPU support
    - [ ] Creating Accelerator Profiles
    - [ ] Configuring accelerators for Notebook Images
    - [ ] Configuring accelerators for Serving Runtimes
- [ ] Distributed Workloads - per [docs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/working_with_distributed_workloads)
  - [ ] verify the status of the following pods in the redhat-ods-applications project:   
    - [ ] codeflare-operator-manager
    - [ ] kuberay-operator
    - [ ] kueue-controller-manager
  - [ ] configure quota management
    - [ ] Create an empty Kueue resource flavor
    - [ ] Create a cluster queue to manage the empty Kueue resource flavor
      - [ ] Adjust the values per cluster
    - [ ] Create a local queue that points to your cluster queue
      - [ ] Configure the local_queue.yaml to cover all namespaces
      - [ ] Verify the status of the local queue
    - [ ] Configure the CodeFlare Operator
      - [ ] install the codeflare-cli
      - [ ] review the codeflare-operator-config configmap:
        - [ ] ingressDomain
        - [ ] mTLSEnabled
        - [ ] rayDashboardOauthEnabled
  - [ ] configure the Ray job specification to set submissionMode=HTTPMode only


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
