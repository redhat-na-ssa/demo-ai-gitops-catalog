# jaeger-product

Red Hat OpenShift distributed tracing platform based on Jaeger. Jaeger is project inspired by [Dapper](https://research.google.com/pubs/pub36356.html) and [OpenZipkin](http://zipkin.io/). It is a distributed tracing system released as open source by Uber Technologies. It is used for monitoring and troubleshooting microservices-based distributed systems.

### Core capabilities
Jaeger is used for monitoring and troubleshooting microservices-based distributed systems, including:
* Distributed context propagation
* Distributed transaction monitoring
* Root cause analysis
* Service dependency analysis
* Performance / latency optimization
* OpenTracing compatible data model
* Multiple storage backends: Elasticsearch, Memory.

### Operator features

* **Multiple modes** - Provides `allInOne`, `production` and `streaming` [modes of deployment](https://www.jaegertracing.io/docs/latest/operator/#deployment-strategies).

* **Configuration** - The Operator manages [configuration information](https://www.jaegertracing.io/docs/latest/operator/#configuring-the-custom-resource) when installing Jaeger instances.

* **Storage** - [Configure storage](https://www.jaegertracing.io/docs/latest/operator/#storage-options) used by Jaeger. By default, `memory` is used. Other options include `elasticsearch`. The operator can delegate creation of an Elasticsearch cluster to the Elasticsearch Operator if deployed.

* **Agent** - can be deployed as [sidecar](https://www.jaegertracing.io/docs/latest/operator/#auto-injecting-jaeger-agent-sidecars) (default) and/or [daemonset](https://www.jaegertracing.io/docs/latest/operator/#installing-the-agent-as-daemonset).

* **UI** - Optionally setup secure route to provide [access to the Jaeger UI](https://www.jaegertracing.io/docs/latest/operator/#accessing-the-jaeger-console-ui).

### Before you start
1. Ensure that the appropriate storage solution, that will be used by the Jaeger instance, is available and configured.
2. If intending to deploy an Elasticsearch cluster via the Jaeger custom resource, then the Elasticsearch Operator must first be installed.

### Support & Troubleshooting

Red Hat OpenShift distributed tracing Jaeger is available and supported as part of a Red Hat OpenShift subscription. Troubleshooting information is available in the [Red Hat Jaeger documentation](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.9/html/distributed_tracing/index), Support is provided to Red Hat OpenShift entitled customers subject to the [Production Scope for Coverage](https://access.redhat.com/support/offerings/production/soc) and the [Red Hat OpenShift distributed tracing Life Cycle](https://access.redhat.com/support/policy/updates/openshift#jaeger).