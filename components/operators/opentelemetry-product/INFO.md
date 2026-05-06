# opentelemetry-product

Red Hat build of OpenTelemetry is a collection of tools, APIs, and SDKs. You use it to instrument, generate, collect, and export telemetry data (metrics, logs, and traces) for analysis in order to understand your software's performance and behavior.
This operator was previously called Red Hat OpenShift distributed tracing data collection.

### Operator features

* **Sidecar injection** - annotate your pods and let the operator inject a sidecar.
* **Managed upgrades** - updating the operator will automatically update your OpenTelemetry collectors.
* **Deployment modes** - your collector can be deployed as sidecar, daemon set, or regular deployment.
* **Service port management** - the operator detects which ports need to be exposed based on the provided configuration.

## Examples

There is a list of examples to help you deploy different configurations in [this GitHub repository](https://github.com/os-observability/redhat-rhosdt-samples)

### Support & Troubleshooting

Red Hat build of OpenTelemetry is available as part of a Red Hat OpenShift subscription.
Checking the [Red Hat Documentation](https://docs.redhat.com/en/documentation/red_hat_build_of_opentelemetry) is recommended when installing, configuring, and managing the Operator and instances.