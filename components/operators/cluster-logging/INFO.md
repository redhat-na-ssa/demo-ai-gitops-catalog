# cluster-logging

# Red Hat OpenShift Logging
The Red Hat OpenShift Logging Operator orchestrates log collection and forwarding to Red Had managed log stores and
other third-party receivers.

##Features
* **Create/Destroy**: Deploy log collectors and forwarders to support observability of OCP cluster.
* **Simplified Configuration**: Spec collectors using a simplified API to configure log collection from opinionated sources to one or more third-party receivers.

## Prerequisites and Requirements
### Red Hat OpenShift Logging Namespace
It is recommended to deploy the Red Hat OpenShift Logging Operator to the **openshift-logging** namespace. This namespace
must be explicitly created by a cluster administrator (e.g. `oc create ns openshift-logging`). To enable metrics
service discovery add namespace label `openshift.io/cluster-monitoring: "true"`.

For additional installation documentation see [Installing logging](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/logging/index#installing-logging-6-2)
in the OpenShift product documentation.