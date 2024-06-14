# Installing the Red Hat OpenShift AI Operator

Login to cluster via terminal
`oc login <openshift_cluster_url> -u <admin_username> -p <password>`

(optional) Configure bash completion - requires `oc` and `bash-completion` packages installed

`source <(oc completion zsh)`

## Adding administrative users for OpenShift Container Platform (~8 min)

[Section 2.2 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install#adding-administrative-users-for-openshift-container-platform_install)

Create an htpasswd file to store the user and password information

`htpasswd -c -B -b users.htpasswd <username> <password>`

Create a secret to represent the htpasswd file

`oc create secret generic htpass-secret --from-file=htpasswd=scratch/users.htpasswd -n openshift-config`

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

## Installing the Red Hat OpenShift AI Operator by using the CLI (~3min)

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

## Installing and managing Red Hat OpenShift AI components (~1min)

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

## Adding a CA bundle (~5min)

[Section 3.2 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/working-with-certificates_certs#adding-a-ca-bundle_certs)

Set environment variables to define base directories for generation of a wildcard certificate and key for the gateways.

```shell
export BASE_DIR=/tmp/kserve
export BASE_CERT_DIR=${BASE_DIR}/certs
```

Set an environment variable to define the common name used by the ingress controller of your OpenShift cluster

```shell
export COMMON_NAME=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' | awk -F'.' '{print $(NF-1)"."$NF}')
```

Set an environment variable to define the domain name used by the ingress controller of your OpenShift cluster.

```shell
export DOMAIN_NAME=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
```

Create the required base directories for the certificate generation, based on the environment variables that you previously set.

```shell
mkdir ${BASE_DIR}
mkdir ${BASE_CERT_DIR}
```

Create the OpenSSL configuration for generation of a wildcard certificate.

```shell
cat <<EOF> ${BASE_DIR}/openssl-san.config
[ req ]
distinguished_name = req
[ san ]
subjectAltName = DNS:*.${DOMAIN_NAME}
EOF
```

Generate a root certificate.

```shell
openssl req -x509 -sha256 -nodes -days 3650 -newkey rsa:2048 \
-subj "/O=Example Inc./CN=${COMMON_NAME}" \
-keyout $BASE_DIR/root.key \
-out $BASE_DIR/root.crt
```

Generate a wildcard certificate signed by the root certificate.

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

Verify the wildcard certificate.

```shell
openssl verify -CAfile ${BASE_DIR}/root.crt ${BASE_DIR}/wildcard.crt
```

Open your dscinitialization object `default-dsci` via the CLI or terminal
`oc edit dscinitialization -n redhat-ods-applications`

In the spec section, add the custom root signed certificate to the customCABundle field for trustedCABundle, as shown in the following example:

```yaml
spec:
  trustedCABundle:
    customCABundle: |
      -----BEGIN CERTIFICATE-----
      examplebundle123
      -----END CERTIFICATE-----
    managementState: Managed
```

More info on managementState [source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/working-with-certificates_certs#managing-certificates_certs)

Verify the `odh-trusted-ca-bundle` configmap for your root signed cert in the `odh-ca-bundle.crt:` section
`oc get cm/odh-trusted-ca-bundle -o yaml -n redhat-ods-applications`

Run the following command to verify that all non-reserved namespaces contain the odh-trusted-ca-bundle ConfigMap
`oc get configmaps --all-namespaces -l app.kubernetes.io/part-of=opendatahub-operator | grep odh-trusted-ca-bundle`

### Installing KServe dependencies (~3min)

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

Define the Serverless operator ns, operatorgroup, and subscription

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    openshift.io/display-name: "Red Hat OpenShift Serverless"
  labels:
    openshift.io/cluster-monitoring: 'true'
  name: openshift-serverless
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: serverless-operators
  namespace: openshift-serverless
spec: {}
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: serverless-operator
  namespace: openshift-serverless
spec:
  channel: stable 
  name: serverless-operator 
  source: redhat-operators 
  sourceNamespace: openshift-marketplace 
```

Install the Serverless Operator objects

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

Apply the KnativeServing object in the specified knative-serving namespace

`oc create -f docs/notes/configs/serverless-istio.yaml`

(Optional) use a TLS certificate to secure the mapped service from [source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#creating-a-knative-serving-instance_serving-large-models)

Review the default ServiceMeshMemberRoll object in the istio-system namespace and confirm that it includes the knative-serving namespace.
`oc describe smmr default -n istio-system`

`oc get smmr default -n istio-system -o jsonpath='{.status.memberStatuses}'`

Verify creation of the Knative Serving instance
`oc get pods -n knative-serving`

#### Creating secure gateways for Knative Serving (4min)

[Section 3.3.1.3 source]()

Why? To secure traffic between your Knative Serving instance and the service mesh, you must create secure gateways for your Knative Serving instance.

The initial steps to generate a root signed certificate were completed previous

Verify the wildcard certificate
`openssl verify -CAfile ${BASE_DIR}/root.crt ${BASE_DIR}/wildcard.crt`

Export the wildcard key and certificate that were created by the script to new environment variables

```shell
export TARGET_CUSTOM_CERT=${BASE_DIR}/wildcard.crt
export TARGET_CUSTOM_KEY=${BASE_DIR}/wildcard.key
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
`oc apply -f docs/notes/configs/serverless-gateway.yaml`

Review the gateways that you created
`oc get gateway --all-namespaces`

### Manually adding an authorization provider (~4min)

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

#### Configuring an OpenShift Service Mesh instance to use Authorino (~6min)

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
         service: authorino-authorino-authorization.redhat-ods-applicatiions-auth-provider.svc.cluster.local
         port: 50051
```

Use the oc patch command to apply the YAML file to your OpenShift Service Mesh instance

`oc patch smcp minimal --type merge -n istio-system --patch-file docs/notes/configs/servicemesh-smcp-patch.yaml`

Inspect the ConfigMap object for your OpenShift Service Mesh instance
`oc get configmap istio-minimal -n istio-system --output=jsonpath={.data.mesh}`

Confirm that you see output that the Authorino instance has been successfully added as an extension provider

#### Configuring authorization for KServe (~3min)

[Section 3.3.3.4 source](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/serving_models/serving-large-models_serving-large-models#configuring-authorization-for-kserve_serving-large-models)

Why? you must create a global AuthorizationPolicy resource that is applied to the KServe predictor pods that are created when you deploy a model. In addition, to account for the multiple network hops that occur when you make an inference request to a model, you must create an EnvoyFilter resource that continually resets the HTTP host header to the one initially included in the inference request.

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

## Enabling GPU support in OpenShift AI

[Section 5 source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/enabling-gpu-support_install)

### Adding a GPU node to an existing OpenShift Container Platform cluster (12min)

[source](https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/machine_management/managing-compute-machines-with-the-machine-api#nvidia-gpu-aws-adding-a-gpu-node_creating-machineset-aws)

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
oc get machineset <your-machineset-name> -n openshift-machine-api -o json > scratch/machineset.json
```

Update the following fields:

- [ ] `.spec.replicas` from `0` to `2`
- [ ] `.metadata.name` to a name containing `gpu`.
- [ ] `.spec.selector.matchLabels["machine.openshift.io/cluster-api-machineset"]` to match the new `.metadata.name`.
- [ ] `.spec.template.metadata.labels["machine.openshift.io/cluster-api-machineset"]` to match the new `.metadata.name`.
- [ ] `.spec.template.spec.providerSpec.value.instanceType` to `g4dn.4xlarge`.

Apply the configuration to create the gpu machine
`oc apply -f scratch/machineset.json`

Verify the gpu machineset you created is running
`oc -n openshift-machine-api get machinesets | grep gpu`

Scale the machineset up

View the Machine object that the machine set created
`oc -n openshift-machine-api get machines | grep gpu`

### Deploying the Node Feature Discovery Operator (12-30min)

[source](https://docs.redhat.com/en/documentation/openshift_container_platform/4.15/html/machine_management/managing-compute-machines-with-the-machine-api#nvidia-gpu-aws-deploying-the-node-feature-discovery-operator_creating-machineset-aws)

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
`oc apply -f docs/notes/configs/nfd-operator-sub.yaml`

Verify the operator is installed and running
`oc get pods -n openshift-nfd`

Create an NodeFeatureDiscovery instance via the CLI or UI (recommended)

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

Create the nfd instance object
`oc apply -f docs/notes/configs/nfd-instance.yaml`

![IMPORTANT]
The NFD Operator uses vendor PCI IDs to identify hardware in a node. NVIDIA uses the PCI ID 10de.

Verify the NFD pods are `Running` on the cluster nodes polling for devices
`oc get pods -n openshift-nfd`

Verify the NVIDIA GPU is discovered

```shell
# list your nodes
oc get nodes

# display the role feature list of a gpu node
oc describe node <NODE_NAME> | egrep 'Roles|pci'
```

Verify the NVIDIA GPU is discovered
10de appears in the node feature list for the GPU-enabled node. This mean the NFD Operator correctly identified the node from the GPU-enabled MachineSet.

### Installing the NVIDIA GPU Operator (10min)

[source](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/install-gpu-ocp.html#installing-the-nvidia-gpu-operator-using-the-cli)

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

Run the following commands to get the startingCSV value
`oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -ojson | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV'`

Run the following command to get the channel value required
`CHANNEL=$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')`

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
`oc get csv -n nvidia-gpu-operator gpu-operator-certified.v24.3.0 -o jsonpath='{.metadata.annotations.alm-examples}' | jq '.[0]' > scratch/nvidia-gpu-clusterpolicy.json`

Apply the clusterpolicy
`oc apply -f scratch/nvidia-gpu-clusterpolicy.json`

At this point, the GPU Operator proceeds and installs all the required components to set up the NVIDIA GPUs in the OpenShift 4 cluster. Wait at least 10-20 minutes before digging deeper into any form of troubleshooting because this may take a period of time to finish.

Verify the successful installation of the NVIDIA GPU Operator
`oc get pods,daemonset -n nvidia-gpu-operator`

(Opinion) When the NVIDIA operator completes labeling the nodes, you can add a label to the GPU node Role as `gpu, worker` for readability
`oc label node -l nvidia.com/gpu.machine node-role.kubernetes.io/gpu=''`

In order to apply this label to new machines/nodes:

```shell
MACHINE_SET_TYPE=$(oc -n openshift-machine-api get machinesets.machine.openshift.io -o name | grep gpu | head -n1)

oc -n openshift-machine-api \
  patch "${MACHINE_SET_TYPE}" \
  --type=merge --patch '{"spec":{"template":{"spec":{"metadata":{"labels":{"node-role.kubernetes.io/gpu":""}}}}}}'
```

### (Optional) Running a sample GPU Application (1min)

[Sample App](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/install-gpu-ocp.html#running-a-sample-gpu-application)

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

Create a test project
`oc new-project sandbox`

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

### Enabling the GPU Monitoring Dashboard (3min)

[source](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/enable-gpu-monitoring-dashboard.html)

Download the latest NVIDIA DCGM Exporter Dashboard from the DCGM Exporter repository on GitHub:
`cd scratch && curl -LfO https://github.com/NVIDIA/dcgm-exporter/raw/main/grafana/dcgm-exporter-dashboard.json`

Create a config map from the downloaded file in the openshift-config-managed namespace

```shell
oc create configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed --from-file=docs/notes/configs/nvidia-dcgm-dashboard-cm.json
```

Label the config map to expose the dashboard in the Administrator perspective of the web console
`oc label configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed "console.openshift.io/dashboard=true"`

Optional: Label the config map to expose the dashboard in the Developer perspecitive of the web console:
`oc label configmap nvidia-dcgm-exporter-dashboard -n openshift-config-managed "console.openshift.io/odc-dashboard=true"`

View the created resource and verify the labels
`oc -n openshift-config-managed get cm nvidia-dcgm-exporter-dashboard --show-labels`

View the NVIDIA DCGM Exporter Dashboard from the OCP UI from Administrator and Developer

### Installing the NVIDIA GPU administration dashboard (5min)

[source](https://docs.openshift.com/container-platform/4.12/observability/monitoring/nvidia-gpu-admin-dashboard.html)

Add the Helm repository
`helm repo add rh-ecosystem-edge https://rh-ecosystem-edge.github.io/console-plugin-nvidia-gpu`

Helm update
`helm repo update`

Install the Helm chart in the default NVIDIA GPU operator namespace
`helm install -n nvidia-gpu-operator console-plugin-nvidia-gpu rh-ecosystem-edge/console-plugin-nvidia-gpu`

Check if a plugins field is specified
`oc get consoles.operator.openshift.io cluster --output=jsonpath="{.spec.plugins}"`

If not, then run the following to enable the plugin
`oc patch consoles.operator.openshift.io cluster --patch '[{"op": "add", "path": "/spec/plugins/-", "value": "console-plugin-nvidia-gpu" }]' --type=json`

add the required DCGM Exporter metrics ConfigMap to the existing NVIDIA operator ClusterPolicy CR
`oc patch clusterpolicies.nvidia.com gpu-cluster-policy --patch '{ "spec": { "dcgmExporter": { "config": { "name": "console-plugin-nvidia-gpu" } } } }' --type=merge`

The dashboard relies mostly on Prometheus metrics exposed by the NVIDIA DCGM Exporter, but the default exposed metrics are not enough for the dashboard to render the required gauges. Therefore, the DGCM exporter is configured to expose a custom set of metrics, as shown here.

```shell
oc get cm console-plugin-nvidia-gpu -n nvidia-gpu-operator -o yaml
```

View the deployed resources
`oc -n nvidia-gpu-operator get all -l app.kubernetes.io/name=console-plugin-nvidia-gpu`

### Configuring GPUs with time slicing (3min)

[source](https://docs.nvidia.com/datacenter/cloud-native/openshift/latest/time-slicing-gpus-in-openshift.html#configuring-gpus-with-time-slicing)

Enabling GPU Feature Discovery
The feature release on GPU Feature Discovery (GFD) exposes the GPU types as labels and allows users to create node selectors based on these labels to help the scheduler place the pods.

Create the slicing configurations
Before enabling a time slicing configuration, you need to tell the device plugin what are the possible configurations.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: device-plugin-config
  namespace: nvidia-gpu-operator
data:
  Tesla-T4: |-
    version: v1
    sharing:
      timeSlicing:
        resources:
          - name: nvidia.com/gpu
            replicas: 8
```

Apply the device plugin configuration
`oc apply -f docs/notes/configs/nvidia-gpu-deviceplugin-cm.yaml`

Tell the GPU Operator which ConfigMap to use for the device plugin configuration. You can simply patch the ClusterPolicy custom resource.

```shell
oc patch clusterpolicy gpu-cluster-policy \
    -n nvidia-gpu-operator --type merge \
    -p '{"spec": {"devicePlugin": {"config": {"name": "device-plugin-config"}}}}'
```

Apply the configuration to all the nodes you have with Tesla TA GPUs. GFD, labels the nodes with the GPU product, in this example Tesla-T4, so you can use a node selector to label all of the nodes at once.

```shell
oc label --overwrite node \
    --selector=nvidia.com/gpu.product=Tesla-T4 \
    nvidia.com/device-plugin.config=Tesla-T4
```

Patch the NVIDIA GPU Operator ClusterPolicy to use the timeslicing configuration by default.

```shell
oc patch clusterpolicy gpu-cluster-policy \
    -n nvidia-gpu-operator --type merge \
    -p '{"spec": {"devicePlugin": {"config": {"default": "Tesla-T4"}}}}'
```

The applied configuration creates eight replicas for Tesla T4 GPUs, so the nvidia.com/gpu external resource is set to 8

```shell
oc get node --selector=nvidia.com/gpu.product=Tesla-T4-SHARED -o json | jq '.items[0].status.capacity'
```

Verify that GFD labels have been added to indicate time-sharing.

```shell
oc get node --selector=nvidia.com/gpu.product=Tesla-T4-SHARED -o json \
 | jq '.items[0].metadata.labels' | grep nvidia
 ```

Look for the following

```shell
  "nvidia.com/gpu.product": "Tesla-T4-SHARED",
  "nvidia.com/gpu.replicas": "8",
```

### Configure Taints and Tolerations (3min)

Prevent non-GPU workloads from being scheduled on the GPU nodes.

Taint the GPU nodes with `nvidia-gpu-only`. This MUST match the Accelerator profile taint key you use (by default may be different, i.e. `nvidia.com/gpu`).

```shell
oc adm taint node -l node-role.kubernetes.io/gpu nvidia-gpu-only=:NoSchedule --overwrite
```

Update the `ClusterPolicy` in the NVIDIA GPU Operator under the `nvidia-gpu-operator` project. Add the below section to `.spec.daemonsets:`

```shell
  daemonsets:
    tolerations:
    - effect: NoSchedule
      operator: Exists
      key: nvidia-gpu-only
```

Cordon the GPU node, drain the GPU tained nodes and terminate workloads

```shell
oc adm drain -l node-role.kubernetes.io/gpu --ignore-daemonsets --delete-emptydir-data
```

Allow the GPU node to be scheduleable again per tolerations

```shell
oc adm uncordon -l node-role.kubernetes.io/gpu
```

Get the name of the gpu node

```shell
MACHINE_SET_TYPE=$(oc get machineset -n openshift-machine-api -o name |  egrep gpu)
```

Taint the machineset for any new nodes that get added to be tainted with `nvidia-gpu-only`

```shell
oc -n openshift-machine-api \
  patch "${MACHINE_SET_TYPE}" \
  --type=merge --patch '{"spec":{"template":{"spec":{"taints":[{"key":"nvidia-gpu-only","value":"","effect":"NoSchedule"}]}}}}'
```

Tolerations will be set in the RHOAI accelerator profiles that match the Taint key.

### (Optional) Configuring the cluster autoscaler

[source](https://docs.openshift.com/container-platform/4.15/machine_management/applying-autoscaling.html)

## Configuring distributed workloads

[source](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/working_with_distributed_workloads/configuring-distributed-workloads_distributed-workloads)

### Components required for Distributed Workloads

1. dashboard
1. workbenches
1. datasciencepipelines
1. codeflare
1. kueue
1. ray

Verify the necessary pods are running - When the status of the codeflare-operator-manager-<pod-id>, kuberay-operator-<pod-id>, and kueue-controller-manager-<pod-id> pods is Running, the pods are ready to use.
`oc get pods -n redhat-ods-applications | grep -E 'codeflare|kuberay|kueue'`

#### Configuring quota management for distributed workloads (~5min)

Create an empty Kueue resource flavor
Why? Resources in a cluster are typically not homogeneous. A ResourceFlavor is an object that represents these resource variations (i.e. Nvidia A100 versus T4 GPUs) and allows you to associate them with cluster nodes through labels, taints and tolerations.

```yaml
apiVersion: kueue.x-k8s.io/v1beta1
kind: ResourceFlavor
metadata:
  name: default-flavor
spec:
  tolerations:
  - effect: NoSchedule
    operator: Exists
    key: nvidia-gpu-only
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

### (Optional) Configuring the CodeFlare Operator (~5min)

Get the `codeflare-operator-config` configmap
`oc get cm codeflare-operator-config -n redhat-ods-applications -o yaml`

In the `codeflare-operator-config`, data:config.yaml:kuberay section, you can patch the [following](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2.9/html/working_with_distributed_workloads/configuring-distributed-workloads_distributed-workloads#configuring-the-codeflare-operator_distributed-workloads)

1. ingressDomain option is null (ingressDomain: "") by default.
1. mTLSEnabled option is enabled (mTLSEnabled: true) by default.
1. rayDashboardOauthEnabled option is enabled (rayDashboardOAuthEnabled: true) by default.

```yaml
kuberay:
  rayDashboardOAuthEnabled: true
  ingressDomain: ""
  mTLSEnabled: true
  #certGeneratorImage: quay.io/project-codeflare/ray:latest-py39-cu118
```

Recommended to keep default. If needed, apply the configuration to update the object
`oc apply -f docs/notes/configs/rhoai-codeflare-operator-config.yaml`

## Administrative Configurations for RHOAI

Access the RHOAI Dashboard > Settings.

1. Notebook Images

- Import new notebook images  

1. Cluster Settings

- Model serving platforms
- PVC size (see Backing up data)
- Stop idle notebooks
- Usage data collection
- Notebook pod tolerations

1. Accelerator Profiles

- Manage accelerator profile settings for users in your organization (see Add a new Accelerator Profile)

1. Serving Runtimes

- Single-model serving platform
  - Caikit TGIS ServingRuntime for KServe
  - OpenVINO Model Server
  - TGIS Standalone ServingRunetime for KServe
- Multi-model serving platform
  - OpenVINO Model Server

1. User Management

- Data scientists
- Administrators

### Backing up data

Refer to [A Guide to High Availability/Disaster Recovery for Applications on OpenShift](https://www.redhat.com/en/blog/a-guide-to-high-availability/disaster-recovery-for-applications-on-openshift)

#### Control plane backup and restore operations

You must [back up etcd](https://docs.openshift.com/container-platform/4.15/backup_and_restore/control_plane_backup_and_restore/backing-up-etcd.html#backup-etcd) data before shutting down a cluster; etcd is the key-value store for OpenShift Container Platform, which persists the state of all resource objects.

#### Application backup and restore operations

The OpenShift API for Data Protection (OADP) product safeguards customer applications on OpenShift Container Platform. It offers comprehensive disaster recovery protection, covering OpenShift Container Platform applications, application-related cluster resources, persistent volumes, and internal images. OADP is also capable of backing up both containerized applications and virtual machines (VMs).

However, OADP does not serve as a disaster recovery solution for [etcd](https://docs.openshift.com/container-platform/4.15/backup_and_restore/control_plane_backup_and_restore/backing-up-etcd.html#backup-etcd) or OpenShift Operators.

### Add a new Accelerator Profile (~3min)

[Enabling GPU support in OpenShift AI](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.9/html/installing_and_uninstalling_openshift_ai_self-managed/enabling-gpu-support_install)

Delete the migration-gpu-status ConfigMap
`oc delete cm migration-gpu-status -n redhat-ods-applications`

Restart the dashboard replicaset
`oc rollout restart deployment rhods-dashboard -n redhat-ods-applications`

Wait until the Status column indicates that all pods in the rollout have fully restarted
`oc get pods -n redhat-ods-applications | egrep rhods-dashboard`

Check the acceleratorprofiles
`oc get acceleratorprofile -n redhat-ods-applications`

Review the acceleratorprofile configuration
`oc describe acceleratorprofile -n redhat-ods-applications`

Verify the `taints` key set in your Node/MachineSets match your Accelerator Profile.