# Notes - Template

These are the imperative steps to install and configure Red Hat OpenShift AI 2.9

# Deploy RHOAI using the CLI

## Login

1. grab your login command

```
oc login --token=<YOUR_TOKEN> --server=https://api.<YOUR_CLUSTER>.com:6443
```

## Admin user

Create `cluster-admin`
[Supported Identity Providers](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.15/html-single/authentication_and_authorization/index#supported-identity-providers)

To define an [htpasswd](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.13/html-single/authentication_and_authorization/index#configuring-htpasswd-identity-provider) identity provider, perform the following tasks:

### Create an htpasswd file to store the user and password information

`htpasswd -c -B -b users.htpasswd <username> <password>`

### (optional) Configure bash completion

You must have `oc` and `bash-completion` packages installed

`source <(oc completion zsh)`

### Create a secret to represent the htpasswd file

`oc create secret generic htpass-secret --from-file=htpasswd=htpasswd/users.htpasswd -n openshift-config`

### Define an htpasswd identity provider resource that references the secret

see the htpasswd/htpass-cr.yaml in this repo

### Apply the resource to the default OAuth configuration to add the identity provider

`oc apply -f htpasswd/htpass-cr.yaml`

You will have to a few minutes for the account to resolve.

### Log in to the cluster as a user from your identity provider, entering the password when prompted

`oc login -u <username>`

### Updating users for htpasswd identity provider

[source](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.13/html-single/authentication_and_authorization/index#identity-provider-htpasswd-update-users_configuring-htpasswd-identity-provider)

### Creating a cluster admin

The [cluster-admin](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.15/html/authentication_and_authorization/using-rbac#creating-cluster-admin_using-rbac) role is required to perform administrator level tasks.

`oc adm policy add-cluster-role-to-user cluster-admin <user>`

## Installing the Red Hat OpenShift AI Operator

### Login with cluster-admin user

`oc login -u admin`

Enter password when prompted

### Create the namespace in your OpenShift Container Platform cluster

`oc create -f Operators/redhat-openshift-ai/namespace.yaml`

### Create an operator group for installation of the Operator

`oc create -f Operators/redhat-openshift-ai/operator-group.yaml`

### Create a subscription for installation of the Operator

See definitions for [channels](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install#installing-openshift-data-science-operator-using-cli_operator-install)
`oc create -f Operators/redhat-openshift-ai/subscription.yaml`

#### Verify installation

Check the installed operators for `rhods-operator.redhat-ods-operator`
`oc get operators`

Check the created projects `redhat-ods-applications|redhat-ods-monitoring|redhat-ods-operator`
`oc get projects | grep -i redhat-ods`

#### Missing Operator reported by default-dcsi

```
2 errors occurred:
* failed to find the pre-requisite Service Mesh Operator subscription, please ensure Service Mesh Operator is installed. failed to find the pre-requisite operator subscription "servicemeshoperator", please ensure operator is installed. missing operator "servicemeshoperator"
* failed to find the pre-requisite Service Mesh Operator subscription, please ensure Service Mesh Operator is installed. failed to find the pre-requisite operator subscription "servicemeshoperator", please ensure operator is installed. missing
```

## Installing and managing Red Hat OpenShift AI components

Create and configure a DataScienceCluster (dsc) object to install Red Hat OpenShift AI components as part of a new installation.

### Create a DataScienceCluster object custom resource (CR) file

Set the value of the managementState field to either Managed or Removed.

`oc create -f Components/redhat-openshift-ai/rhods-operator-dsc.yaml `

[!NOTE]

- Managed: The Operator actively manages the component, installs it, and tries to keep it active. The Operator will upgrade the component only if it is safe to do so.
- Removed: The Operator actively manages the component but does not install it. If the component is already installed, the Operator will try to remove it.
- After installing OpenShift AI, the Red Hat OpenShift AI Operator automatically creates an empty odh-trusted-ca-bundle configuration file (ConfigMap)

## KServe component dependencies

To fully install the KServe component, which is used by the single-model serving platform to serve large models, you must install Operators for Red Hat OpenShift Service Mesh and Red Hat OpenShift Serverless and perform additional configuration.

1. kserve: orchestrates model serving for all types of models
1. serverless allows for serverless deployments of models
1. service mesh networking layer that manages traffic flows and enforces access policies
1. authorino (optional) allows you to enable token authorization for models

[source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#model_serving_runtimes)

### Monitoring

Prometheus scrapes metrics for each of the pre-installed model-serving runtimes

### Authorino

[Authorino](https://github.com/kuadrant/authorino) ensures that only authorized parties can make inference requests to the models. It is a Kubernetes-native authorization service for tailor-made Zero Trust API security.

### Install Options

1. [Automated](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#configuring-automated-installation-of-kserve_serving-large-models)

#### Install KServe dependencies - ServiceMesh

Verify/create the istio-system namespace

`oc create -f Components/redhat-servicemesh/namespace.yaml`

![NOTE] The RHOAI operator may create the istio-system namespace

Install the operator

`oc create -f Operators/redhat-servicemesh/subscription.yaml`

After you install the operator you have 3 configurations: ControlPlane, Member, MemberRole
Control Plane

`oc create -f Components/redhat-servicemesh/smcp.yaml`

Verify the pods are running for the service mesh control plane, ingress gateway, and egress gateway

`oc get pods -n istio-system`

Expected output

```
istio-egressgateway-f9b5cf49c-c7fst    1/1     Running   0          59s
istio-ingressgateway-c69849d49-fjswg   1/1     Running   0          59s
istiod-minimal-5c68bf675d-whrns        1/1     Running   0          68s
```

This should clear the errors thrown by the default-dcsi mentioned above.

#### Create the Knative Serving instance

[source](https://docs.openshift.com/serverless/1.32/install/install-serverless-operator.html?extIdCarryOver=true&intcmp=701f2000001OMHaAAO&sc_cid=701f2000001Css5AAC#serverless-install-cli_install-serverless-operator)

Install the operator

`oc apply -f Operators/redhat-serverless/serverless-subscription.yaml`

Verify the success

`oc get csv`

This will create 2 projects `knative-serving` and `knative-eventing`

Create the ServiceMeshMember object for knative-serving in istio-system

`oc create -f Components/redhat-servicemesh/default-smm.yaml`

Create a KnativeServing object knativeserving

The custom resource file defines a custom resource (CR) for a KnativeServing object. The CR also adds the following actions to each of the activator and autoscaler pods:

1. Injects an Istio sidecar to the pod. This makes the pod part of the service mesh.
1. Enables the Istio sidecar to rewrite the HTTP liveness and readiness probes for the pod.

`oc create -f Components/redhat-servicemesh/knativeserving-istio.yaml`

Verify the ServiceMeshMemberRoll object in the istio-system project. 

`oc describe smmr default -n istio-system`

In the description of the ServiceMeshMemberRoll object, locate the Status.Members field and confirm that it includes the knative-serving namespace.

Verify the pods running in the knative-serving project

`oc get pods -n knative-serving`

Confirm that there are numerous running pods: activator, autoscaler, controller, domain-mapping, istio-controller

#### Creating secure gateways for Knative Serving

Set environment variables to define base directories for generation of a wildcard certificate and key for the gateways.

```
export BASE_DIR=/tmp/kserve
export BASE_CERT_DIR=${BASE_DIR}/certs
```

Set an environment variable to define the common name used by the ingress controller of your OpenShift cluster

```
export COMMON_NAME=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' | awk -F'.' '{print $(NF-1)"."$NF}')
```

Set an environment variable to define the domain name used by the ingress controller of your OpenShift cluster.

```
export DOMAIN_NAME=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
```

Create the required base directories for the certificate generation, based on the environment variables that you previously set.

```
mkdir ${BASE_DIR}
mkdir ${BASE_CERT_DIR}
```

Create the OpenSSL configuration for generation of a wildcard certificate.

```
$ cat <<EOF> ${BASE_DIR}/openssl-san.config
[ req ]
distinguished_name = req
[ san ]
subjectAltName = DNS:*.${DOMAIN_NAME}
EOF
```

Generate a root certificate.

```
openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 \
-subj "/O=Example Inc./CN=${COMMON_NAME}" \
-keyout $BASE_DIR/root.key \
-out $BASE_DIR/root.crt
```

Generate a wildcard certificate signed by the root certificate.

```
openssl req -x509 -newkey rsa:2048 \
-sha256 -days 3560 -nodes \
-subj "/CN=${COMMON_NAME}/O=Example Inc." \
-extensions san -config ${BASE_DIR}/openssl-san.config \
-CA $BASE_DIR/root.crt \
-CAkey $BASE_DIR/root.key \
-keyout $BASE_DIR/wildcard.key  \
-out $BASE_DIR/wildcard.crt

openssl x509 -in ${BASE_DIR}/wildcard.crt -text
```

Verify the wildcard certificate.

```
openssl verify -CAfile ${BASE_DIR}/root.crt ${BASE_DIR}/wildcard.crt
```

Export the wildcard key and certificate that were created by the script to new environment variables.

```
export TARGET_CUSTOM_CERT=${BASE_CERT_DIR}/wildcard.crt
export TARGET_CUSTOM_KEY=${BASE_CERT_DIR}/wildcard.key
```

Create a TLS secret in the istio-system namespace using the environment variables that you set for the wildcard certificate and key.

```
oc create secret tls wildcard-certs --cert=${TARGET_CUSTOM_CERT} --key=${TARGET_CUSTOM_KEY} -n istio-system

# or run

oc create secret tls wildcard-certs --cert=/tmp/kserve/wildcard.crt --key=/tmp/kserve/wildcard.key -n istio-system
```

![NOTE]error: Cannot read file /tmp/kserve/certs/wildcard.crt, open /tmp/kserve/certs/wildcard.crt: no such file or directory - run the direct path not variable

Create a gateways.yaml YAML file with the following contents:

```
oc apply -f Secure/gateways.yaml
```

Verify the gateways

`oc get gateway --all-namespaces`

Confirm that you see the local and ingress gateways that you created in the knative-serving namespace

```
knative-serving   knative-ingress-gateway   26s
knative-serving   knative-local-gateway     26s
```

### Installing KServe

In the default-dcsi.yaml, change th service mesh to Un-managed

```
spec:
 serviceMesh:
   managementState: Unmanaged
```

In the default-dcs.yaml, change the Kserve serving component to Un-managed

```
spec:
 components:
   kserve:
     managementState: Managed
     serving:
       managementState: Unmanaged
```

## Install Authorino

Authorino is Red Hat's Kubernetes-native lightweight external authorization service for tailor-made Zero Trust API security.

`oc apply -f Operators/redhat-authorino/subscription.yaml`

### Create Authorino Instance

The automated process creates a project `redhat-ods-applications-auth-provider`

create the namespace in the same namespace for the manual process

`oc create -f Components/redhat-authorino/namespace.yaml`

enroll the new namespace for the Authorino instance in your existing OpenShift Service Mesh instance

`oc create -f Components/redhat-authorino/smm.yaml`

Request an instance of the external authorization service by creating an Authorino custom resource using a minimal namespaced example. Namespaced instances only watch auth resources (AuthConfig and Secrets) created in the same namespace as the Authorino service. Use this mode for dedicated instances that do not require elevated privileges.

Patch the Authorino deployment to inject an Istio sidecar, which makes the Authorino instance part of your OpenShift Service Mesh instance

`oc patch deployment authorino -n redhat-ods-applications-auth-provider -p '{"spec": {"template":{"metadata":{"labels":{"sidecar.istio.io/inject":"true"}}}} }'`

```
# original
  template:
    metadata:
      creationTimestamp: null
      labels:
        authorino-resource: authorino
        control-plane: controller-manager
    spec:

# patched
  template:
    metadata:
      creationTimestamp: null
      labels:
        authorino-resource: authorino
        control-plane: controller-manager
        sidecar.istio.io/inject: "true"
    spec:
```

Verify the authorino instance is running
`oc get pods -n redhat-ods-applications-auth-provider -o="custom-columns=NAME:.metadata.name,STATUS:.status.phase,CONTAINERS:.spec.containers[*].name"`

Expected output

```
NAME                         STATUS    CONTAINERS
authorino-59888d5766-z9bvn   Running   authorino,istio-proxy
```

### Configuring an OpenShift Service Mesh instance to use Authorino

You must configure your OpenShift Service Mesh instance to use Authorino as an authorization provider

Because the smcp already has other extension providers configured, you have to manually edit the ServiceMeshControlPlane to add the config

```
  techPreview:
    meshConfig:
      defaultConfig:
        terminationDrainDuration: 35s
      # add the below configurations
      extensionProviders:
      - name: redhat-ods-applications-auth-provider
        envoyExtAuthzGrpc:
          service: authorino-authorino-authorization.redhat-ods-applications-auth-provider.svc.cluster.local
          port: 50051
```

Verify Authorino instance hs been added as an extension provider in service mesh

`oc get configmap istio-minimal -n istio-system --output=jsonpath={.data.mesh}`

Confirm that you see output similar to the following example, which shows that the Authorino instance has been successfully added as an extension provider

```
- envoyExtAuthzGrpc:
    port: 50051
    service: authorino-authorino-authorization.redhat-ods-applications-auth-provider.svc.cluster.local
  name: redhat-ods-applications-auth-provider
ingressControllerMode: "OFF"
rootNamespace: istio-system
```

### Configuring authorization for KServe

configure the single-model serving platform to use Authorino, you must create a global AuthorizationPolicy resource that is applied to the KServe predictor pods that are created when you deploy a model.

to account for the multiple network hops that occur when you make an inference request to a model, you must create an EnvoyFilter resource that continually resets the HTTP host header to the one initially included in the inference request.

Create the AuthorizationPolicy resource in the namespace for your OpenShift Service Mesh instance.

`oc create -n istio-system -f Components/redhat-authorino/authorization-policy.yaml`

The EnvoyFilter resource shown continually resets the HTTP host header to the one initially included in any inference request

Create the EnvoyFilter resource in the namespace for your OpenShift Service Mesh instance

`oc create -n istio-system -f Components/redhat-authorino/envoy-filter.yaml`

Verify the AuthorizationPolicy was created

`oc get authorizationpolicies -n istio-system`

Expected output

```
NAME               AGE
kserve-predictor   28h
```

Verify the EnvoyFilter was created

`oc get envoyfilter -n istio-system`

Expected output

```
NAME                                AGE
activator-host-header               95s
```

## Certificates

Certificates are used by various components in OpenShift Container Platform to validate access to the cluster

- the Red Hat OpenShift AI Operator automatically creates an empty odh-trusted-ca-bundle configuration file (ConfigMap)
- RHOAI Operator adds it to all new and existing non-reserved namespaces in the cluster
- RHOAI Operator automatically updates it if any changes are made to the CA bundle
- the Cluster Network Operator (CNO) injects the cluster-wide CA bundle into the odh-trusted-ca-bundle configMap with the label "config.openshift.io/inject-trusted-cabundle"
- the CNO updates the ConfigMap with the ca-bundle.crt file containing the certificates
- components deployed in the affected namespaces are responsible for mounting this configMap as a volume in the deployment pods
- The RHOAI Operator manages the odh-trusted-ca-bundle ConfigMap via the trustedCABundle property in the Operator’s DSC Initialization (DSCI) object

### Adding a CA Bundle

1. a cluster-wide CA bundle
1. a custom CA bundle

use self-signed certificates in a custom CA bundle (odh-ca-bundle.crt) that is separate from the cluster-wide bundle

In the default-dcsi.yaml, add the custom certificate to the customCABundle field for trustedCABundle

```
spec:
  trustedCABundle:
    managementState: Managed
    customCABundle: |
      -----BEGIN CERTIFICATE-----
      examplebundle123
      -----END CERTIFICATE-----
```

## Enabling the single-model serving platform

You can use the Red Hat OpenShift AI dashboard to enable the single-model serving platform

## Create an Accelerator Profile

Tolerations:

1. NoSchedule - New pods that do not match the taint are not scheduled onto that node. Existing pods on the node remain.
1. PreferNoSchedule - New pods that do not match the taint might be scheduled onto that node, but the scheduler tries not to. Existing pods on the node remain.
1. NoExecute - New pods that do not match the taint cannot be scheduled onto that node. Existing pods on the node that do not have a matching toleration are removed.

```
apiVersion: dashboard.opendatahub.io/v1
kind: AcceleratorProfile
metadata:
  annotations:
    # opendatahub.io/modified-date: '2024-02-14T00:57:22.878Z'
  name: nvidia
  namespace: redhat-ods-applications
spec:
  description: Default Nvidia GPU Profile
  displayName: Nvidia
  enabled: true
  identifier: nvidia.com/gpu
  tolerations:
    - effect: NoSchedule
      operator: Equal
      key: nvidia-gpu-only
      value: ""
```

## Distributed workloads

### Configuring distrubited workloads components

Check the status of the pods

`oc get pods | grep -E 'codeflare-operator|kuberay-operator|kueue-controller-manager'`

Expected output

```
codeflare-operator-manager-7544cc8fd-2vcmv                        1/1     Running   6               45h
kuberay-operator-f9f7b7dc9-rb72q                                  1/1     Running   9               45h
kueue-controller-manager-665778777b-6gm5t                         1/1     Running   1               20h
```

### Configuring quotas management of distributed workloads

Create an empty Kueue resource flavor and apply it

`oc apply -f Components/redhat-openshift-ai/default_flavor.yaml`

Create a cluster queue to manage the empty Kueue resource flavor

- The cluster queue allocates the resources to run distributed workloads in the local queue.

`oc apply -f Components/redhat-openshift-ai/cluster_queue.yaml`

Create a local queue that points to your cluster queue

- The kueue.x-k8s.io/default-queue: 'true' annotation defines this queue as the default queue. 

- Distributed workloads are submitted to this queue if no local_queue value is specified in the ClusterConfiguration section of the data science pipeline or Jupyter notebook or Microsoft Visual Studio Code file.

- If you do not create a default local queue, you must specify a local queue in each notebook.

`oc apply -f Components/redhat-openshift-ai/local_queue.yaml`

Verify the status of the local queue in a project

`oc get LocalQueue -A`

Expected output

```
NAMESPACE                 NAME               CLUSTERQUEUE    PENDING WORKLOADS   ADMITTED WORKLOADS
redhat-ods-applications   local-queue-test   cluster-queue   0                   0
```

[!IMPORTANT]
In this release of OpenShift AI, the only accelerators supported for distributed workloads are NVIDIA GPUs.

### Configure the CodeFlare Operator

If you want to change the default configuration of the CodeFlare Operator for distributed workloads in OpenShift AI, you can edit the associated config map

`oc get cm codeflare-operator-config -n redhat-ods-applications -o yaml`

- ingressDomain -  Do not change this option unless the Ingress Controller is not running on OpenShift. 
- mTLSEnabled - the Ray Cluster pods create certificates that are used for mutual Transport Layer Security (mTLS), a form of mutual authentication, between Ray Cluster nodes. 
- rayDashboardOauthEnabled - OpenShift AI places an OpenShift OAuth proxy in front of the Ray Cluster head node. Users must then authenticate by using their OpenShift cluster login credentials when accessing the Ray Dashboard through the browser.



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
