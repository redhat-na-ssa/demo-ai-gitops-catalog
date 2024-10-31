# authorino-operator

[Authorino](https://docs.kuadrant.io/authorino/) is Red Hat's Kubernetes-native lightweight external authorization service for tailor-made Zero Trust API security.

Install this Red Hat official distribution of [Authorino Operator](https://docs.kuadrant.io/authorino-operator/) to manage instances of Authorino in this cluster.

The current state of this distribution of the operator is: **_Technical Preview_**.

The Community version of Authorino Operator, based on upstream public images, is available in [OperatorHub.io](https://operatorhub.io/operator/authorino-operator).

## Getting started

After installing the Operator, request an instance of the external authorization service by creating an `Authorino` custom resource.

**Minimal example (namespaced)**

```yaml
apiVersion: operator.authorino.kuadrant.io/v1beta1
kind: Authorino
metadata:
  name: authorino
spec:
  listener:
    tls:
      enabled: false
  oidcServer:
    tls:
      enabled: false
```

**Extended example**

```yaml
apiVersion: operator.authorino.kuadrant.io/v1beta1
kind: Authorino
metadata:
  name: authorino
spec:
  clusterWide: true
  authConfigLabelSelectors: environment=production
  secretLabelSelectors: authorino.kuadrant.io/component=authorino,environment=production

  replicas: 2

  evaluatorCacheSize: 2 # mb

  logLevel: info
  logMode: production

  listener:
    ports:
      grpc: 50001
      http: 5001
    tls:
      certSecretRef:
        name: authorino-server-cert # secret must contain `tls.crt` and `tls.key` entries
    timeout: 2

  oidcServer:
    port: 8083
    tls:
      certSecretRef:
        name: authorino-oidc-server-cert # secret must contain `tls.crt` and `tls.key` entries

  metrics:
    port: 8080
    deep: true

  healthz:
    port: 8081

  tracing:
    endpoint: rpc://otel-collector.observability.svc.cluster.local:4317
    insecure: true

  volumes:
    items:
      - name: keycloak-tls-cert
        mountPath: /etc/ssl/certs
        configMaps:
          - keycloak-tls-cert
        items: # details to mount the k8s configmap in the authorino pods
          - key: keycloak.crt
            path: keycloak.crt
    defaultMode: 420
```

### Cluster-wide vs Namespaced

Namespaced instances only watch auth resources (`AuthConfig` and `Secrets`) created in the same namespace as the Authorino service. Use this mode for dedicated instances that do not require elevated privileges.

Cluster-wide instances watch resources across the entire cluster (all namespaces.) Deploying and running Authorino in this mode requires elevated privileges.

### Multi-tenancy

Use the `authConfigLabelSelectors` field of the `Authorino` custom resource to narrow the scope of the Authorino instance.

Only `AuthConfig` custom resources whose labels match the value of this field will be handled by the Authorino instance.

## Protect a host

To protect a host, create an `AuthConfig` custom resource for the host. E.g.:

```yaml
apiVersion: authorino.kuadrant.io/v1beta2
kind: AuthConfig
metadata:
  name: my-api-protection
spec:
  hosts:
  - my-api.io

  authentication:
    "keycloak":
      jwt:
        issuerUrl: https://keycloak.keycloak.svc.cluster.local:8080/realms/my-realm

  authorization:
    "k8s-rbac":
      kubernetesSubjectAccessReview:
        user:
          selector: auth.identity.user.username
        resourceAttributes:
          resource:
            value: my-api
          verb:
            selector: request.method
      cache:
        key:
          selector: auth.identity.user.username
        ttl: 30
    "after-2am-only":
      rego: |
        allow {
          [hour, _, _] := time.clock(time.now_ns())
          hour >= 2
        }
```

Make sure all requests to the host are fisrt checked with the Authorino instance, by configuring an Envoy proxy for external authz:

```yaml
clusters:
- name: my-api
  …
- name: authorino
  connect_timeout: 0.25s
  type: STRICT_DNS
  lb_policy: ROUND_ROBIN
  http2_protocol_options: {}
  load_assignment:
    cluster_name: authorino
    endpoints:
    - lb_endpoints:
      - endpoint:
          address:
            socket_address:
              address: authorino-authorino-authorization
              port_value: 50051
listeners:
- filter_chains:
  - filters:
    name: envoy.http_connection_manager
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
      use_remote_address: true
      route_config:
        name: my-api-config
        virtual_hosts:
        - name: my-api-vs
          domains:
          - my-api.io
          routes:
          - match:
              prefix: /
            route:
              cluster: my-api
      http_filters:
      - name: envoy.filters.http.ext_authz
        typed_config:
          "@type": type.googleapis.com/envoy.extensions.filters.http.ext_authz.v3.ExtAuthz
          transport_api_version: V3
          failure_mode_allow: false
          include_peer_certificate: true
          grpc_service:
            envoy_grpc:
              cluster_name: authorino
            timeout: 1s
```

...or, if using Istio, by creating an [`AuthorizationPolicy`](https://istio.io/latest/docs/reference/config/security/authorization-policy/#AuthorizationPolicy) custom resource. Use `action: CUSTOM` in the resource and the Authorino authorization service configured in the mesh extension provider settings.

## Features

**Authentication**

* JWT validation (with OpenID Connect Discovery)
* OAuth 2.0 Token Introspection (opaque tokens)
* Kubernetes TokenReview (ServiceAccount tokens)
* API key authentication
* X.509 client certificate authentication
* Anonymous access
* Proxy-handled (authentication performed by the proxy)

**Authorization**

* Built-in simple pattern matching (e.g. JWT claims, request attributes checking)
* OPA policies (inline Rego and fetch from external registry)
* Kubernetes SubjectAccessReview (resource and non-resource attributes)
* Authzed SpiceDB

**External metadata**

* HTTP request
* OpenID Connect User Info
* UMA-protected resource attributes

**Custom responses**

* Header injection (Festival Wristbands tokens, JSON, plain text)
* Envoy Dynamic Metadata
* Custom HTTP response (status code, headers, messages, body, etc)

**Callbacks**

* HTTP webhooks

**Caching**

* OpenID Connect and User-Managed Access configs
* JSON Web Keys (JWKs) and JSON Web Key Sets (JWKS)
* Access tokens
* External metadata
* Precompiled Rego policies
* Policy evaluation

Check out the full [Feature Specification](https://docs.kuadrant.io/authorino/docs/features/) and how-to guides in the [Kuadrant Docs](https://docs.kuadrant.io) website.