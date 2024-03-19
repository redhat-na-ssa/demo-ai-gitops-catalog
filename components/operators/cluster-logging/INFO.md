# cluster-logging

# Red Hat OpenShift Logging
The Red Hat OpenShift Logging Operator orchestrates and manages the aggregated logging stack as a cluster-wide service.

##Features
* **Create/Destroy**: Launch and create an aggregated logging stack to support the entire OCP cluster.
* **Simplified Configuration**: Configure your aggregated logging cluster's structure like components and end points easily.

## Prerequisites and Requirements
### Red Hat OpenShift Logging Namespace
Cluster logging and the Red Hat OpenShift Logging Operator is only deployable to the **openshift-logging** namespace. This namespace
must be explicitly created by a cluster administrator (e.g. `oc create ns openshift-logging`). To enable metrics
service discovery add namespace label `openshift.io/cluster-monitoring: "true"`.

For additional installation documentation see [Deploying cluster logging](https://docs.openshift.com/container-platform/latest/logging/cluster-logging-deploying.html)
in the OpenShift product documentation.

### Elasticsearch Operator
The Elasticsearch Operator is responsible for orchestrating and managing cluster logging's Elasticsearch cluster.  This
operator must be deployed to the global operator group namespace
### Memory Considerations
Elasticsearch is a memory intensive application.  Red Hat OpenShift Logging will specify that each Elasticsearch node needs
16G of memory for both request and limit unless otherwise defined in the ClusterLogging custom resource. The initial
set of OCP nodes may not be large enough to support the Elasticsearch cluster.  Additional OCP nodes must be added
to the OCP cluster if you desire to run with the recommended(or better) memory. Each ES node can operate with a
lower memory setting though this is not recommended for production deployments.