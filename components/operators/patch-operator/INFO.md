# patch-operator

The patch operator helps with defining patches in a declarative way. This operator has two main features:

1. [ability to patch an object at creation time via a mutating webhook](#creation-time-patch-injection)
2. [ability to enforce patches on one or more objects via a controller](#runtime-patch-enforcement)

## Creation-time patch injection

Why apply a patch at creation time when you could directly create the correct object? The reason is that sometime the correct value depends on configuration set on the specific cluster in which the object is being deployed. For example, an ingress/route hostname might depend on the specific cluster. Consider the following example based on cert-manager:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-issuer
spec:
  acme:
    server: 'https://acme-v02.api.letsencrypt.org/directory'
    email: {{ .Values.letsencrypt.email }}
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:  
    - dns01:
        route53:
          accessKeyID: << access_key >>
          secretAccessKeySecretRef:
            name: cert-manager-dns-credentials
            key: aws_secret_access_key
          region: << region >>
          hostedZoneID: << hosted_zone_id >>
```

In this example the fields: `<< access_key >>`, `<< region >>` and `<< hosted_zone_id >>` are dependent on the specific region in which the cluster is being deployed and in many cases they are discoverable from other configurations already present in the cluster. If you want to deploy the above Cluster Issuer object with a gitops approach, then there is no easy way to discover those values. The solution so far is to manually discover those values and create a different gitops configuration for each cluster. But consider if you could look up values at deploy time based on the cluster you are deploying to. Here is how this object might look:

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-issuer
  namespace: {{ .Release.Namespace }}
  annotations:
    "redhat-cop.redhat.io/patch": |
      spec:
        acme:
        - dns01:
            route53:
              accessKeyID: {{ (lookup "v1" "Secret" .metadata.namespace "cert-manager-dns-credentials").data.aws_access_key_id | b64dec }}
              secretAccessKeySecretRef:
                name: cert-manager-dns-credentials
                key: aws_secret_access_key
              region: {{ (lookup "config.openshift.io/v1" "Infrastructure" "" "cluster").status.platformStatus.aws.region }}
              hostedZoneID: {{ (lookup "config.openshift.io/v1" "DNS" "" "cluster").spec.publicZone.id }} 
spec:
  acme:
    server: 'https://acme-v02.api.letsencrypt.org/directory'
    email: {{ .Values.letsencrypt.email }}
    privateKeySecretRef:
      name: letsencrypt-staging
    solvers:  
    - dns01:
        route53:
          accessKeyID: << access_key >>
          secretAccessKeySecretRef:
            name: cert-manager-dns-credentials
            key: aws_secret_access_key
          region: << region >>
          hostedZoneID: << hosted_zone_id >>
```

The annotation specifies a patch that will be applied by a [MutatingWebhook](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/), as you can see the three values are now looked up from different configurations in the cluster.

Two annotations influences the behavior of this MutatingWebhook

1. "redhat-cop.redhat.io/patch" : this is the patch itself. The patch is evaluated as a template with the object itself as it's only parameter. The template is expressed in golang template notation and supports the same functions as helm template including the [lookup](https://helm.sh/docs/chart_template_guide/functions_and_pipelines/#using-the-lookup-function) function which plays a major role here. The patch must be expressed in yaml for readability. It will be converted to json by the webhook logic.
2. "redhat-cop.redhat.io/patch-type" : this is the type of json patch. The possible values are: `application/json-patch+json`, `application/merge-patch+json` and `application/strategic-merge-patch+json`. If this annotation is omitted it defaults to strategic merge.

### Security Considerations

The lookup function, if used by the template, is executed with a client which impersonates the user issuing the object creation/update request. This should prevent security permission leakage.

### Installing the creation time webhook

The creation time webhook is not installed by the operator. This is because there is no way to know which specific object type should be intercepted and intercepting all of the types would be too inefficient. It's up to the administrator then to install the webhook. Here is some guidance.

If you installed the operator via OLM, use the following webhook template:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: patch-operator-inject
  annotations:
    service.beta.openshift.io/inject-cabundle: "true"
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    service:
      name: patch-operator-webhook-service
      namespace: patch-operator
      path: /inject
  failurePolicy: Fail
  name: patch-operator-inject.redhatcop.redhat.io
  rules:
  - << add your intercepted objects here >>
  sideEffects: None
```

If you installed the operator via the Helm chart and are using cert-manager, use the following webhook template:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: patch-operator-inject
  annotations:
    cert-manager.io/inject-ca-from: '{{ .Release.Namespace }}/webhook-server-cert'
webhooks:
- admissionReviewVersions:
  - v1
  clientConfig:
    service:
      name: patch-operator-webhook-service
      namespace: patch-operator
      path: /inject
  failurePolicy: Fail
  name: patch-operator-inject.redhatcop.redhat.io
  rules:
  - << add your intercepted objects here >>
  sideEffects: None
```  

You should need to enable the webhook only for `CREATE` operations. So for example to enable the webhook on configmaps:

```yaml
  rules:
  - apiGroups:
    - ""
    apiVersions:
    - v1
    operations:
    - CREATE
    resources:
    - configmaps
```

## Runtime patch enforcement

There are situations when we need to patch pre-existing objects. Again this is a use case that is hard to model with gitops operators which will work only on object that they own. Especially with sophisticated Kubernetes distributions, it is not uncommon that a Kubernetes instance, at installation time, is configured with some default settings. Changing those configurations means patching those objects. For example, let's take the case of OpenShift Oauth configuration. This object is present by default and it is expected to be patched with any newly enabled authentication mechanism. This is how it looks like after installation:

```yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
  ownerReferences:
    - apiVersion: config.openshift.io/v1
      kind: ClusterVersion
      name: version
      uid: 9a9d450b-3076-4e30-ac05-a889d6341fc3
  resourceVersion: '20405124'
spec: []
```

If we need to patch it we can use the patch controller and the `Patch` object as follows:

```yaml
apiVersion: redhatcop.redhat.io/v1alpha1
kind: Patch
metadata:
  name: gitlab-ocp-oauth-provider
  namespace: openshift-config
spec:
  serviceAccountRef:
    name: default
  patches:
    gitlab-ocp-oauth-provider:
      targetObjectRef:
        apiVersion: config.openshift.io/v1
        kind: OAuth
        name: cluster
      patchTemplate: |
        spec:
          identityProviders:
          - name: my-github 
            mappingMethod: claim 
            type: GitHub
            github:
              clientID: "{{ (index . 1).data.client_id | b64dec }}" 
              clientSecret: 
                name: ocp-github-app-credentials
              organizations: 
              - my-org
              teams: []            
      patchType: application/merge-patch+json
      sourceObjectRefs:
      - apiVersion: v1
        kind: Secret
        name: ocp-github-app-credentials
        namespace: openshift-config
```

This will cause the OAuth object to be patched and the patch to be enforced. That means that if anything changes on the secret that we use a parameter (which may be rotated) or in Oauth object itself, the patch will be reapplied. In this case we are adding a gitlab authentication provider.

A `patch` has the following fields:

`targetObjectRef` this refers to the object(s) receiving the patch. Mutliple object can be selected based on the following rules:

| Namespaced Type | Namespace | Name | Selection type |
| --- | --- | --- | --- |
| yes | null | null | multiple selection across namespaces |
| yes | null | not null | multiple selection across namespaces where the name corresponds to the passed name |
| yes | not null | null | multiple selection within a namespace |
| yes | not null | not nul | single selection |
| no | N/A | null | multiple selection  |
| no | N/A | not null | single selection |

Selection can be further narrowed down by filtering by labels and/or annotations using the `labelSelector` and `annotationSelector` fields. The patch will be applied to all of the selected instances.

`sourceObjectRefs` these are the objects that will be watched and become part of the parameters of the patch template. Name and Namespace of sourceRefObjects are interpreted as golang templates with the current target instance and the only parameter. This allows to select different source object for each target object.

So, for example, with this patch:

```yaml
apiVersion: redhatcop.redhat.io/v1alpha1
kind: Patch
metadata:
  name: multiple-namespaced-targets-patch
spec:
  serviceAccountRef:
    name: default
  patches:
    multiple-namespaced-targets-patch:
      targetObjectRef:
        apiVersion: v1
        kind: ServiceAccount
        name: deployer
      patchTemplate: |
        metadata:
          annotations:
            {{ (index . 1).metadata.uid }}: {{ (index . 1) }}
      patchType: application/strategic-merge-patch+json
      sourceObjectRefs:
      - apiVersion: v1
        kind: ServiceAccount
        name: default
        namespace: "{{ .metadata.namespace }}"
        fieldPath: $.metadata.uid
```

The `deployer` service accounts from all namespaces are selected as target of this patch, each patch template will receive a different parameter and that is the `default` service account of the same namespace as the namespace of the `deployer` service account being processed.

`sourceObjectRefs` also have the `fieldPath` field which can contain a jsonpath expression. If a value is passed the jsonpath expression will be calculate for the current source object and the result will be passed as parameter of the template.

`patchTemplate` This is the the template that will be evaluated. The result must be a valid patch compatible with the requested type and expressed in yaml for readability. The parameters passed to the template are the target object and then the all of the source object. So if you want to refer to the target object in the template you can use this expression `(index . 0)`. Higher indexes refer to the sourceObjectRef array. The template is expressed in golang template notation and supports the same functions as helm template.

`patchType` is the type of the json patch. The possible values are: `application/json-patch+json`, `application/merge-patch+json` and `application/strategic-merge-patch+json`. If this annotation is omitted it defaults to strategic merge.

### Patch Controller Security Considerations

The patch enforcement enacted by the patch controller is executed with a client which uses the service account referenced by the `serviceAccountRef` field. So before a patch object can actually work an administrator must have granted the needed permissions to a service account in the same namespace. The `serviceAccountRef` will default to the `default` service account if not specified.

### Patch Controller Performance Considerations

The patch controller will create a controller-manager and per `Patch` object and a reconciler for each of the `PatchSpec` defined in the array on patches in the `Patch` object.
These reconcilers share the same cached client. In order to be able to watch changes on target and source objects of a `PatchSpec`, all of the target and source object type instances will be cached by the client. This is a normal behavior of a controller-manager client, but it implies that if you create patches on object types that have many instances in etcd (Secrets, ServiceAccounts, Namespaces for example), the patch operator instance will require a significant amount of memory. A way to contain this issue is to try to aggregate together `PatchSpec` that deal with the same object types. This will cause those object type instances to cached only once.  
