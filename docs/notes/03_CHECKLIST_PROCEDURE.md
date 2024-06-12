# Installing the Red Hat OpenShift AI Operator

Login to cluster via terminal
`oc login <openshift_cluster_url> -u <admin_username> -p <password>`

(optional) Configure bash completion - requires `oc` and `bash-completion` packages installed

`source <(oc completion zsh)`

## Adding administrative users for OpenShift Container Platform
[Section 2.2 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install#adding-administrative-users-for-openshift-container-platform_install)

Create an htpasswd file to store the user and password information

`htpasswd -c -B -b users.htpasswd <username> <password>`

Create a secret to represent the htpasswd file

`oc create secret generic htpass-secret --from-file=htpasswd=htpasswd/users.htpasswd -n openshift-config`

Define the custom resource for htpasswd

```yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
    # This provider name is prefixed to provider user names to form an identity name.
  - name: my_htpasswd_provider
    # Controls how mappings are established between this provider’s identities and User objects.
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        # An existing secret containing a file generated using htpasswd.
        name: htpass-secret
```

Apply the resource to the default OAuth configuration to add the identity provider

`oc apply -f docs/notes/configs/htpass-cr.yaml`

> You will have to a few minutes for the account to resolve.

As kubeadmin, assign the cluster-admin role to perform administrator level tasks.

`oc adm policy add-cluster-role-to-user cluster-admin <user>`

Log in to the cluster as a user from your identity provider, entering the password when prompted

`oc login --insecure-skip-tls-verify=true -u <username> -p <password>`

## Installing the Red Hat OpenShift AI Operator by using the CLI
[Section 2.3 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install#installing-the-openshift-data-science-operator_operator-install)

Create a namespace YAML file, for example, rhoai-operator-ns.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: redhat-ods-operator
```

Create the namespace in your OpenShift Container Platform cluster

`oc create -f docs/notes/configs/rhoai-operator-ns.yaml`

Create an OperatorGroup object custom resource (CR) file, for example, rhoai-operator-group.yaml

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: rhods-operator
  namespace: redhat-ods-operator 
```

Create the OperatorGroup in your OpenShift Container Platform cluster

`oc create -f docs/notes/configs/rhoai-operator-group.yaml`

Create a Subscription object CR file, for example, rhoai-operator-subscription.yaml

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhods-operator
  namespace: redhat-ods-operator 
spec:
  name: rhods-operator
  channel:  
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

Create the Subscription object in your OpenShift Container Platform cluster 

`oc create -f docs/notes/configs/rhoai-operator-subscription.yaml`

Verification

Check the installed operators for `rhods-operator.redhat-ods-operator`
`oc get operators`

Check the created projects `redhat-ods-applications|redhat-ods-monitoring|redhat-ods-operator`
`oc get projects | grep -i redhat-ods`

## Installing and managing Red Hat OpenShift AI components
[Section 2.4 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install#installing-openshift-ai-components-using-cli_component-install)

Create a DataScienceCluster object custom resource (CR) file, for example, rhoai-operator-dsc.yaml

```yaml
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
spec:
  components:
    dashboard:
      managementState: Managed
    workbenches:
      managementState: Managed
    datasciencepipelines:
      managementState: Managed
    kueue:
      managementState: Managed
    codeflare:
      managementState: Managed
    ray:
      managementState: Managed
    modelmeshserving:
      managementState: Managed
    kserve:
      managementState: Managed
      serving:
        ingressGateway:
          certificate:
            secretName: knative-serving-cert
            type: SelfSigned
        managementState: Unmanaged
        name: knative-serving       
```

Apply the DSC object

`oc create -f docs/notes/configs/rhoai-operator-dcs.yaml`

### Installing KServe dependencies
[Section 3.3.1 source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#manually-installing-kserve_serving-large-models)

Create the required namespace for Red Hat OpenShift Service Mesh.

`oc create ns istio-system`

Define the required subscription for the Red Hat OpenShift Service Mesh Operator

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: servicemeshoperator
  namespace: openshift-operators
spec:
  channel: stable 
  installPlanApproval: Automatic
  name: servicemeshoperator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  ```

Apply the Service Mesh subscription to install the operator

`oc create -f docs/notes/configs/servicemesh-subscription.yaml`

Define a ServiceMeshControlPlane object in a YAML file for example, servicemesh-subscription.yaml

```yaml
apiVersion: maistra.io/v2
kind: ServiceMeshControlPlane
metadata:
  name: minimal
  namespace: istio-system
spec:
  tracing:
    type: None
  addons:
    grafana:
      enabled: false
    kiali:
      name: kiali
      enabled: false
    prometheus:
      enabled: false
    jaeger:
      name: jaeger
  security:
    dataPlane:
      mtls: true
    identity:
      type: ThirdParty
  techPreview:
    meshConfig:
      defaultConfig:
        terminationDrainDuration: 35s
  gateways:
    ingress:
      service:
        metadata:
          labels:
            knative: ingressgateway
  proxy:
    networking:
      trafficControl:
        inbound:
          excludedPorts:
            - 8444
            - 8022
```

[Service Mesh configuration definition](https://docs.openshift.com/container-platform/4.15/service_mesh/v2x/ossm-reference-smcp.html)

Apply the servicemesh control plane object

`oc create -f docs/notes/configs/servicemesh-scmp.yaml`

Verify the pods are running for the service mesh control plane, ingress gateway, and egress gateway

`oc get pods -n istio-system`

Expected output

```
istio-egressgateway-f9b5cf49c-c7fst    1/1     Running   0          59s
istio-ingressgateway-c69849d49-fjswg   1/1     Running   0          59s
istiod-minimal-5c68bf675d-whrns        1/1     Running   0          68s
```

#### Creating a Knative Serving instance
[Section 3.3.1.2 source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#creating-a-knative-serving-instance_serving-large-models)

Install the Serverless Operator

`oc create -f docs/notes/configs/serverless-operator.yaml`

Define a ServiceMeshMember object in a YAML file called serverless-smm.yaml

```yaml
apiVersion: maistra.io/v1
kind: ServiceMeshMember
metadata:
  name: default
  namespace: knative-serving
spec:
  controlPlaneRef:
    namespace: istio-system
    name: minimal
```

Apply the ServiceMeshMember object in the istio-system namespace

`oc project -n istio-system && oc apply -f docs/notes/configs/serverless-smm.yaml`

Define a KnativeServing object in a YAML file called serverless-istio.yaml

>adds the following actions to each of the activator and autoscaler pods:
1. Injects an Istio sidecar to the pod. This makes the pod part of the service mesh.
1. Enables the Istio sidecar to rewrite the HTTP liveness and readiness probes for the pod.

```yaml
apiVersion: operator.knative.dev/v1beta1
kind: KnativeServing
metadata:
  name: knative-serving
  namespace: knative-serving
  annotations:
    serverless.openshift.io/default-enable-http2: "true"
spec:
  workloads:
    - name: net-istio-controller
      env:
        - container: controller
          envVars:
            - name: ENABLE_SECRET_INFORMER_FILTERING_BY_CERT_UID
              value: 'true'
    - annotations:
        sidecar.istio.io/inject: "true" 
        sidecar.istio.io/rewriteAppHTTPProbers: "true" 
      name: activator
    - annotations:
        sidecar.istio.io/inject: "true"
        sidecar.istio.io/rewriteAppHTTPProbers: "true"
      name: autoscaler
  ingress:
    istio:
      enabled: true
  config:
    features:
      kubernetes.podspec-affinity: enabled
      kubernetes.podspec-nodeselector: enabled
      kubernetes.podspec-tolerations: enabled
```

Create the KnativeServing object in the specified knative-serving namespace

`oc create -f docs/notes/configs/serverless-istio.yaml`

TODO use a TLS certificate to secure the mapped service from [source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#creating-a-knative-serving-instance_serving-large-models)

Review the default ServiceMeshMemberRoll object in the istio-system namespace and confirm that it includes the knative-serving namespace.
`oc describe smmr default -n istio-system`

`oc get smmr default -n istio-system -o jsonpath='{.status.memberStatuses}'`

Verify creation of the Knative Serving instance
`oc get pods -n knative-serving`

#### Creating secure gateways for Knative Serving
[Section 3.3.1.3 source]()
TODO Update

Why? To secure traffic between your Knative Serving instance and the service mesh, you must create secure gateways for your Knative Serving instance.

Set environment variables to define base directories for generation of a wildcard certificate and key for the gateways.
```yaml
export BASE_DIR=/tmp/kserve
export BASE_CERT_DIR=${BASE_DIR}/certs
```

Set an environment variable to define the common name used by the ingress controller of your OpenShift cluster.
`export COMMON_NAME=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' | awk -F'.' '{print $(NF-1)"."$NF}')`

Create the required base directories for the certificate generation, based on the environment variables that you previously set.
```shell
mkdir ${BASE_DIR}
mkdir ${BASE_CERT_DIR}
```

Create the OpenSSL configuration for generation of a wildcard certificate
```shell
cat <<EOF> ${BASE_DIR}/openssl-san.config
[ req ]
distinguished_name = req
[ san ]
subjectAltName = DNS:*.${DOMAIN_NAME}
EOF
```

Generate a root certificate
```shell
openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 \
-subj "/O=Example Inc./CN=${COMMON_NAME}" \
-keyout $BASE_DIR/root.key \
-out $BASE_DIR/root.crt
```

Generate a wildcard certificate signed by the root certificate
```shell
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

Verify the wildcard certificate
`openssl verify -CAfile ${BASE_DIR}/root.crt ${BASE_DIR}/wildcard.crt`

Export the wildcard key and certificate that were created by the script to new environment variables
```shell
export TARGET_CUSTOM_CERT=${BASE_CERT_DIR}/wildcard.crt
export TARGET_CUSTOM_KEY=${BASE_CERT_DIR}/wildcard.key
```

Create a TLS secret in the istio-system namespace using the environment variables that you set for the wildcard certificate and key
`oc create secret tls wildcard-certs --cert=${TARGET_CUSTOM_CERT} --key=${TARGET_CUSTOM_KEY} -n istio-system`

Create a serverless-gateways.yaml YAML file with the following contents
>Defines a service in the istio-system namespace for the Knative local gateway.
Defines an ingress gateway in the knative-serving namespace. The gateway uses the TLS secret you created earlier in this procedure. The ingress gateway handles external traffic to Knative.
Defines a local gateway for Knative in the knative-serving namespace.

```yaml
apiVersion: v1
kind: Service 
metadata:
  labels:
    experimental.istio.io/disable-gateway-port-translation: "true"
  name: knative-local-gateway
  namespace: istio-system
spec:
  ports:
    - name: http2
      port: 80
      protocol: TCP
      targetPort: 8081
  selector:
    knative: ingressgateway
  type: ClusterIP
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: knative-ingress-gateway 
  namespace: knative-serving
spec:
  selector:
    knative: ingressgateway
  servers:
    - hosts:
        - '*'
      port:
        name: https
        number: 443
        protocol: HTTPS
      tls:
        credentialName: wildcard-certs
        mode: SIMPLE
---
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
 name: knative-local-gateway 
 namespace: knative-serving
spec:
 selector:
   knative: ingressgateway
 servers:
   - port:
       number: 8081
       name: https
       protocol: HTTPS
     tls:
       mode: ISTIO_MUTUAL
     hosts:
       - "*"
```

Apply the serverless-gateways.yaml file to create the defined resources
`oc apply -f docs/notes/configs/serverless-gateways.yaml`

Review the gateways that you created
`oc get gateway --all-namespaces`

### Manually adding an authorization provider
[Section 3.3.3 source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#manually-adding-an-authorization-provider_serving-large-models)

Why? Adding an authorization provider allows you to enable token authorization for models that you deploy on the platform, which ensures that only authorized parties can make inference requests to the models.

Create subscription for the Authorino Operator
```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: authorino-operator
  namespace: openshift-operators
spec:
  channel: managed-services
  installPlanApproval: Automatic
  name: authorino-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  startingCSV: authorino-operator.v1.0.1
```

Apply the Authorino operator
`oc create -f docs/notes/configs/authorino-subscription.yaml`

Create a namespace to install the Authorino instance
`oc create ns redhat-ods-applications-auth-provider`

Enroll the new namespace for the Authorino instance in your existing OpenShift Service Mesh instance, create a new YAML file authorino-smm.yaml with the following contents
```yaml
  apiVersion: maistra.io/v1
  kind: ServiceMeshMember
  metadata:
    name: default
    namespace: redhat-ods-applications-auth-provider
  spec:
    controlPlaneRef:
      namespace: istio-system
      name: minimal
```

Create the ServiceMeshMember resource on your cluster
`oc create -f docs/notes/configs/authorino-smm.yaml`

Configure an Authorino instance, create a new YAML file as shown
```yaml
  apiVersion: operator.authorino.kuadrant.io/v1beta1
  kind: Authorino
  metadata:
    name: authorino
    namespace: redhat-ods-applications-auth-provider
  spec:
    authConfigLabelSelectors: security.opendatahub.io/authorization-group=default
    clusterWide: true
    listener:
      tls:
        enabled: false
    oidcServer:
      tls:
        enabled: false
```

Create the Authorino resource on your cluster.
`oc create -f docs/notes/configs/authorino-instance.yaml`

Patch the Authorino deployment to inject an Istio sidecar, which makes the Authorino instance part of your OpenShift Service Mesh instance
`oc patch deployment authorino -n redhat-ods-applications-auth-provider -p '{"spec": {"template":{"metadata":{"labels":{"sidecar.istio.io/inject":"true"}}}} }'`

Check the pods (and containers) that are running in the namespace that you created for the Authorino instance, as shown in the following example
`oc get pods -n redhat-ods-applications-auth-provider -o="custom-columns=NAME:.metadata.name,STATUS:.status.phase,CONTAINERS:.spec.containers[*].name"`

#### Configuring an OpenShift Service Mesh instance to use Authorino
[Section 3.3.3.3 source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#configuring-service-mesh-instance-to-use-authorino_serving-large-models)

Why? you must configure your OpenShift Service Mesh instance to use Authorino as an authorization provider

Create a new YAML file with the following contents `servicemesh-smcp-patch.yaml`
```yaml
spec:
 techPreview:
   meshConfig:
     extensionProviders:
     - name: redhat-ods-applications-auth-provider
       envoyExtAuthzGrpc:
         service: <name_of_authorino_instance>-authorino-authorization.<namespace_for_authorino_instance>.svc.cluster.local
         port: 50051
```

Use the oc patch command to apply the YAML file to your OpenShift Service Mesh instance

`oc patch smcp minimal --type merge -n istio-system --patch-file docs/notes/configs/servicemesh-smcp-patch.yaml`

Inspect the ConfigMap object for your OpenShift Service Mesh instance
`oc get configmap istio-minimal -n istio-system --output=jsonpath={.data.mesh}`

Confirm that you see output similar to the following example, which shows that the Authorino instance has been successfully added as an extension provider

#### Configuring authorization for KServe

[Section 3.3.3.4 source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#configuring-authorization-for-kserve_serving-large-models)

why? you must create a global AuthorizationPolicy resource that is applied to the KServe predictor pods that are created when you deploy a model. In addition, to account for the multiple network hops that occur when you make an inference request to a model, you must create an EnvoyFilter resource that continually resets the HTTP host header to the one initially included in the inference request.

Create a new YAML file with the following contents:

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: kserve-predictor
spec:
  action: CUSTOM
  provider:
     name: redhat-ods-applications-auth-provider 
  rules:
     - to:
          - operation:
               notPaths:
                  - /healthz
                  - /debug/pprof/
                  - /metrics
                  - /wait-for-drain
  selector:
     matchLabels:
        component: predictor
```
Create the AuthorizationPolicy resource in the namespace for your OpenShift Service Mesh instance
`oc create -n istio-system -f docs/notes/configs/servicemesh-authorization-policy.yaml`

Create another new YAML file with the following contents:
The EnvoyFilter resource shown continually resets the HTTP host header to the one initially included in any inference request.
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: activator-host-header
spec:
  priority: 20
  workloadSelector:
    labels:
      component: predictor
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      listener:
        filterChain:
          filter:
            name: envoy.filters.network.http_connection_manager
    patch:
      operation: INSERT_BEFORE
      value:
        name: envoy.filters.http.lua
        typed_config:
          '@type': type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua
          inlineCode: |
           function envoy_on_request(request_handle)
              local headers = request_handle:headers()
              if not headers then
                return
              end
              local original_host = headers:get("k-original-host")
              if original_host then
                port_seperator = string.find(original_host, ":", 7)
                if port_seperator then
                  original_host = string.sub(original_host, 0, port_seperator-1)
                end
                headers:replace('host', original_host)
              end
            end
```

Create the EnvoyFilter resource in the namespace for your OpenShift Service Mesh instance
`oc create -n istio-system -f docs/notes/configs/servicemesh-envoyfilter.yaml`

Check that the AuthorizationPolicy resource was successfully created.
`oc get authorizationpolicies -n istio-system`

Check that the EnvoyFilter resource was successfully created.
`oc get envoyfilter -n istio-system`

## Adding a CA bundle
[Section 3.2 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/working-with-certificates_certs#adding-a-ca-bundle_certs)

TODO

## Enabling GPU support in OpenShift AI
[Section 5 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/enabling-gpu-support_install)

### Adding a GPU node to an existing OpenShift Container Platform cluster
(source)[https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/machine_management/managing-compute-machines-with-the-machine-api#nvidia-gpu-aws-adding-a-gpu-node_creating-machineset-aws]

View the existing nodes
`oc get nodes`

View the machines and machine sets that exist in the openshift-machine-api namespace
`oc get machinesets -n openshift-machine-api`

View the machines that exist in the openshift-machine-api namespace 
`oc get machines -n openshift-machine-api | grep worker`

Make a copy of one of the existing compute MachineSet definitions and output the result to a JSON file
```shell
# get your machineset names
oc get machineset -n openshift-machine-api

# make a copy of an existing machineset definition
oc get machineset <your-machineset-name> -n openshift-machine-api -o json > <output-file.json>
```

Update the following fields:
- [ ] `.metadata.name` to a name containing `gpu`.
- [ ] `.spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"]` to match the new `.metadata.name`.
- [ ] `.spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"]` to match the new `.metadata.name`.
- [ ] `.spec.template.spec.providerSpec.value.instanceType` to `g4dn.xlarge`.

Apply the configuration to create the gpu machine
`oc apply -f docs/notes/configs/ocp-machineset.json`

Verify the gpu machineset you created is running
`oc -n openshift-machine-api get machinesets | grep gpu`

View the Machine object that the machine set created 
`oc -n openshift-machine-api get machines | grep gpu`


### Deploying the Node Feature Discovery Operator
(source)[https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/machine_management/managing-compute-machines-with-the-machine-api#nvidia-gpu-aws-deploying-the-node-feature-discovery-operator_creating-machineset-aws]

List the available operators for installation searching for Node Feature Discovery (NFD) 
`oc get packagemanifests -n openshift-marketplace | grep nfd`

Create a Namespace object YAML file
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-nfd
```

Apply the Namespace object
`oc apply -f docs/notes/configs/nfd-operator-ns.yaml`


Create an OperatorGroup object YAML file
```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: nfd
  namespace: openshift-nfd
```

Apply the OperatorGroup object
```yaml
oc apply -f docs/notes/configs/nfd-operator-group.yaml
```

Create a Subscription object YAML file to subscribe a namespace to an Operator

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: nfd
  namespace: openshift-nfd
spec:
  channel: stable
  name: nfd
  source: redhat-operators 
  sourceNamespace: openshift-marketplace 
  installPlanApproval: Automatic
```

Apply the Subscription object
`oc apply -f docs/configs/notes/ndf-operator-sub.yaml`

Verify the operator is installed and running
`oc get pods -n openshift-nfd`

Create an NodeFeatureDiscovery instance
```yaml
kind: NodeFeatureDiscovery
apiVersion: nfd.openshift.io/v1
metadata:
  name: nfd-instance
  namespace: openshift-nfd
spec:
  customConfig:
    configData: 
  operand:
    image: 'registry.redhat.io/openshift4/ose-node-feature-discovery-rhel9@sha256:a98a205e5541550dfd46caaf52147f078101a6c6e7221b7fb7cefb9581761dcb'
    servicePort: 12000
  workerConfig:
    configData: |
      core:
        sleepInterval: 60s
      sources:
        pci:
          deviceClassWhitelist:
            - "0200"
            - "03"
            - "12"
          deviceLabelFields:
            - "vendor"
```

![IMPORTANT]
The NFD Operator uses vendor PCI IDs to identify hardware in a node. NVIDIA uses the PCI ID 10de.

Verify the NFD pods are running on the cluster nodes polling for devices
`oc get pods -n openshift-nfd` 

Verify the NVIDIA GPU is discovered
```shell
# list your nodes
oc get nodes

# display the role feature list of a gpu node
oc describe node <NODE_NAME> | egrep 'Roles|pci'
```

10de appears in the node feature list for the GPU-enabled node. This mean the NFD Operator correctly identified the node from the GPU-enabled MachineSet.

### Installing the NVIDIA GPU Operator
(source)[https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/install-gpu-ocp.html#installing-the-nvidia-gpu-operator-using-the-cli]

List the available operators for installation searching for Node Feature Discovery (NFD) 
`oc get packagemanifests -n openshift-marketplace | grep gpu`

Create a Namespace custom resource (CR) that defines the nvidia-gpu-operator namespace
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nvidia-gpu-operator
```

Apply the Namepsace object YAML file 
`oc apply -f docs/notes/configs/nvidia-gpu-operator-ns.yaml`

Create an OperatorGroup CR
```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: nvidia-gpu-operator-group
  namespace: nvidia-gpu-operator
spec:
 targetNamespaces:
 - nvidia-gpu-operator
 ```

Apply the OperatorGroup YAML file
```yaml
oc apply -f docs/notes/configs/nvidia-gpu-operator-group.yaml 
```

Run the following command to get the channel value required
`CHANNEL=$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')`

Run the following commands to get the startingCSV value
`oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -ojson | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV'`

Create the following Subscription CR and save the YAML
Update the `channel` and `startingCSV` fields with the information returned
```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: gpu-operator-certified
  namespace: nvidia-gpu-operator
spec:
  channel: "v24.3"
  installPlanApproval: Automatic
  name: gpu-operator-certified
  source: certified-operators
  sourceNamespace: openshift-marketplace
  startingCSV: "gpu-operator-certified.v24.3.0"
```

Apply the Subscription CR
`oc apply -f docs/notes/configs/nvidia-gpu-operator-subscription.yaml`

Verify an install plan has been created
`oc get installplan -n nvidia-gpu-operator`

(Optional) Approve the install plan if not `Automatic`
`INSTALL_PLAN=$(oc get installplan -n nvidia-gpu-operator -oname)`

Create the cluster policy
`oc get csv -n nvidia-gpu-operator gpu-operator-certified.v24.3.0 -o jsonpath='{.metadata.annotations.alm-examples}' | jq '.[0]' > docs/notes/configs/nvidia-gpu-clusterpolicy.json`

Apply the clusterpolicy
`oc apply -f docs/notes/configs/nvidia-gpu-clusterpolicy.json`

At this point, the GPU Operator proceeds and installs all the required components to set up the NVIDIA GPUs in the OpenShift 4 cluster. Wait at least 10-20 minutes before digging deeper into any form of troubleshooting because this may take a period of time to finish.

Verify the successful installation of the NVIDIA GPU Operator
`oc get pods,daemonset -n nvidia-gpu-operator`

### (Optional) Running a sample GPU Application
Run a simple CUDA VectorAdd sample, which adds two vectors together to ensure the GPUs have bootstrapped correctly

```shell
apiVersion: v1
kind: Pod
metadata:
  name: cuda-vectoradd
spec:
 restartPolicy: OnFailure
 containers:
 - name: cuda-vectoradd
   image: "nvidia/samples:vectoradd-cuda11.2.1"
   resources:
     limits:
       nvidia.com/gpu: 1
```

Create the sample app
`oc create -f docs/notes/configs/nvidia-gpu-sample-app.yaml` 

Check the logs of the container
`oc logs cuda-vectoradd`

Get information about the GPU
`oc project nvidia-gpu-operator`

View the new pods
`oc get pod -owide -lopenshift.driver-toolkit=true`

With the Pod and node name, run the nvidia-smi on the correct node.
`oc exec -it nvidia-driver-daemonset-410.84.202203290245-0-xxgdv -- nvidia-smi`

1. The first table reflects the information about all available GPUs (the example shows one GPU). 
1. The second table provides details on the processes using the GPUs.

## Configuring distributed workloads
[Section 2 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/working_with_distributed_workloads/configuring-distributed-workloads_distributed-workloads)

### Components required for Distributed Workloads
1. dashboard
1. workbenches
1. datasciencepipelines
1. codeflare
1. kueue
1. ray

Verify the necessary pods are running - When the status of the codeflare-operator-manager-<pod-id>, kuberay-operator-<pod-id>, and kueue-controller-manager-<pod-id> pods is Running, the pods are ready to use.
`oc get pods | grep -E 'codeflare|kuberay|kueue'`

#### Configuring quota management for distributed workloads

Create an empty Kueue resource flavor
Why? Resources in a cluster are typically not homogeneous. A ResourceFlavor is an object that represents these resource variations and allows you to associate them with cluster nodes through labels, taints and tolerations (i.e. gpus).

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ResourceFlavor
metadata:
  name: default-flavor
```

Apply the configuration to create the `default-flavor`
`oc apply -f docs/notes/configs/rhoai-kueue-default-flavor.yaml`

Create a cluster queue to manage the empty Kueue resource flavor
Why? A ClusterQueue is a cluster-scoped object that governs a pool of resources such as pods, CPU, memory, and hardware accelerators. Only batch administrators should create ClusterQueue objects.

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ClusterQueue
metadata:
  name: "cluster-queue"
spec:
  namespaceSelector: {}  # match all.
  resourceGroups:
  - coveredResources: ["cpu", "memory", "nvidia.com/gpu"]
    flavors:
    - name: "default-flavor"
      resources:
      - name: "cpu"
        nominalQuota: 9
      - name: "memory"
        nominalQuota: 36Gi
      - name: "nvidia.com/gpu"
        nominalQuota: 5
```

What is this cluster-queue doing? This ClusterQueue admits Workloads if and only if:
- The sum of the CPU requests is less than or equal to 9.
- The sum of the memory requests is less than or equal to 36Gi.
- The total number of pods is less than or equal to 5.

![IMPORTANT] 
Replace the example quota values (9 CPUs, 36 GiB memory, and 5 NVIDIA GPUs) with the appropriate values for your cluster queue. The cluster queue will start a distributed workload only if the total required resources are within these quota limits. Only homogenous NVIDIA GPUs are supported.


Apply the configuration to create the `cluster-queue`
`oc apply -f docs/notes/configs/rhoai-kueue-cluster-queue.yaml`

Create a local queue that points to your cluster queue
Why? A LocalQueue is a namespaced object that groups closely related Workloads that belong to a single namespace. Users submit jobs to a LocalQueue, instead of to a ClusterQueue directly.
```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: LocalQueue
metadata:
  namespace: sandbox
  name: local-queue-test
  annotations:
    kueue.x-k8s.io/default-queue: 'true'
spec:
  clusterQueue: cluster-queue
```

![NOTE] 
Update the name value accordingly.

Apply the configuration to create the local-queue object
`oc apply -f docs/notes/configs/rhoai-kueue-local-queue.yaml`

How do users known what queues they can submit jobs to? Users submit jobs to a LocalQueue, instead of to a ClusterQueue directly. Tenants can discover which queues they can submit jobs to by listing the local queues in their namespace.

Verify the local queue is created
`oc get -n sandbox queues`

### Configuring the CodeFlare Operator
Get the `codeflare-operator-config` configmap
`oc get cm codeflare-operator-config -n redhat-ods-applications -o yaml`

In the `codeflare-operator-config`, data:config.yaml:kuberay section, you can patch the (following)[https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/working_with_distributed_workloads/configuring-distributed-workloads_distributed-workloads#configuring-the-codeflare-operator_distributed-workloads]

```yaml
kuberay:
  rayDashboardOAuthEnabled: false
  ingressDomain: "kind"
  mTLSEnabled: false
  certGeneratorImage: quay.io/project-codeflare/ray:latest-py39-cu118
```

TODO test mTLS

Apply the configuration to update the object
`oc apply -f docs/notes/configs/rhoai-codeflare-operator-config.yaml`

![IMPORTANT] 
This does not change the values, but it does illustrate where you would enable mTLS in Ray cluster. If mTLS is enabled you must also add and execute the following code in your notebook after you define your `cluster`

(Optional - if you enabled mTLS)
```python
from codeflare_sdk import generate_cert

generate_cert.generate_tls_cert(cluster.config.name, cluster.config.namespace)
generate_cert.export_env(cluster.config.name, cluster.config.namespace)

ray.init(cluster.cluster_uri())
```


source:
- https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install#installing-openshift-data-science-operator-using-cli_operator-install 