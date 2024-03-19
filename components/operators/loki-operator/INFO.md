# loki-operator

The Community Loki Operator provides Kubernetes native deployment and management of Loki and related logging components.
The purpose of this project is to simplify and automate the configuration of a Loki based logging stack for Kubernetes clusters.

### Operator features

The Loki Operator includes, but is not limited to, the following features:

* Kubernetes Custom Resources: Use Kubernetes custom resources to deploy and manage Loki, Alerting rules, Recording rules, and related components.
* Simplified Deployment Configuration: Configure the fundamentals of Loki like tenants, limits, replication factor and storage from a native Kubernetes resource.

### Feature Gates

The Loki Operator Bundle provides a set of feature gates that enable/disable specific feature depending on the target Kubernetes distribution. The following feature gates are enabled by default:
* `serviceMonitors`: Enables creating a Prometheus-Operator managed ServiceMonitor resource per LokiStack component.
* `serviceMonitorTlsEndpoints`: Enables TLS for the ServiceMonitor endpoints.
* `lokiStackAlerts`: Enables creating PrometheusRules for common Loki alerts.
* `httpEncryption`: Enables TLS encryption for all HTTP LokiStack services.
* `grpcEncryption`: Enables TLS encryption for all GRPC LokiStack services.
* `builtInCertManagement`: Enables the built-in facility for generating and rotating TLS client and serving certificates for all LokiStack services and internal clients
* `lokiStackGateway`: Enables reconciling the reverse-proxy lokistack-gateway component for multi-tenant authentication/authorization traffic control to Loki.
* `runtimeSeccompProfile`: Enables the restricted seccomp profile on all Lokistack components.
* `defaultNodeAffinity`: Enable the operator will set a default node affinity on all pods. This will limit scheduling of the pods to Nodes with Linux.
* `lokiStackWebhook`: Enables the LokiStack CR validation and conversion webhooks.
* `alertingRuleWebhook`: Enables the AlertingRule CR validation webhook.
* `recordingRuleWebhook`: Enables the RecordingRule CR validation webhook.
* `rulerConfigWebhook`: Enables the RulerConfig CR validation webhook.

In addition it enables the following OpenShift-only related feature gates:
* `servingCertsService`: Enables OpenShift ServiceCA annotations on the lokistack-gateway service only.
* `ruleExtendedValidation`: Enables extended validation of AlertingRule and RecordingRule to enforce tenancy in an OpenShift context.
* `clusterTLSPolicy`: Enables usage of TLS policies set in the API Server.
* `clusterProxy`: Enables usage of the proxy variables set in the proxy resource.

### Before you start

1. Ensure that the appropriate object storage solution, that will be used by Loki, is avaliable and configured.