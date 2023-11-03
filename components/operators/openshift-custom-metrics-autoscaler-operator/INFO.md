# openshift-custom-metrics-autoscaler-operator

## About the managed application
Custom Metrics Autoscaler for OpenShift is an event driven autoscaler based upon KEDA.  Custom Metrics Autoscaler can monitor event sources like Kafka, RabbitMQ, or cloud event sources and feed the metrics from those sources into the Kubernetes horizontal pod autoscaler.  With Custom Metrics Autoscaler, you can have event driven and serverless scale of deployments within any Kubernetes cluster.
## About this Operator
The Custom Metrics Autoscaler Operator deploys and manages installation of KEDA Controller in the cluster. Install this operator and follow installation instructions on how to install Custom Metrics Autoscaler in your cluster.

## Prerequisites for enabling this Operator
## How to install Custom Metrics Autoscaler in the cluster
The installation of Custom Metrics Autoscaler is triggered by the creation of `KedaController` resource. Please refer to the [KedaController Spec](https://github.com/openshift/custom-metrics-autoscaler-operator/blob/main/README.md#the-kedacontroller-custom-resource) for more details on available options.

Only a resource named `keda` in the namespace where the operator is installed will trigger the installation, reconfiguration or removal of the KEDA Controller resource.

There should be only one KEDA Controller in the cluster.

The operator will behave in this manner whether it is installed with the `AllNamespaces` or `OwnNamespace` install mode. While the operator more closely matches the `OwnNamespace` semantics, `AllNamespaces` is a supported installation mode to allow it to be installed to namespaces with existing `OperatorGroups` which require that installation mode, such as `openshift-operators`.
