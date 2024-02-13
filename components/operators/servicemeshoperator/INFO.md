# servicemeshoperator

Red Hat OpenShift Service Mesh is a platform that provides behavioral insight and operational control over a service mesh, providing a uniform way to connect, secure, and monitor microservice applications.

### Overview

Red Hat OpenShift Service Mesh, based on the open source [Istio](https://istio.io/) project, adds a transparent layer on existing
distributed applications without requiring any changes to the service code. You add Red Hat OpenShift Service Mesh
support to services by deploying a special sidecar proxy throughout your environment that intercepts all network
communication between microservices. You configure and manage the service mesh using the control plane features.

Red Hat OpenShift Service Mesh provides an easy way to create a network of deployed services that provides discovery,
load balancing, service-to-service authentication, failure recovery, metrics, and monitoring. A service mesh also
provides more complex operational functionality, including A/B testing, canary releases, rate limiting, access
control, and end-to-end authentication.

### Core Capabilities

Red Hat OpenShift Service Mesh supports uniform application of a number of key capabilities across a network of services:

+ **Traffic Management** - Control the flow of traffic and API calls between services, make calls more reliable,
  and make the network more robust in the face of adverse conditions.

+ **Service Identity and Security** - Provide services in the mesh with a verifiable identity and provide the
  ability to protect service traffic as it flows over networks of varying degrees of trustworthiness.

+ **Policy Enforcement** - Apply organizational policy to the interaction between services, ensure access policies
  are enforced and resources are fairly distributed among consumers. Policy changes are made by configuring the
  mesh, not by changing application code.

+ **Telemetry** - Gain understanding of the dependencies between services and the nature and flow of traffic between
  them, providing the ability to quickly identify issues.

### Joining Projects Into a Mesh

Once an instance of Red Hat OpenShift Service Mesh has been installed, it will only exercise control over services within its own
project.  Other projects may be added into the mesh using one of two methods:

1. A **ServiceMeshMember** resource may be created in other projects to add those projects into the mesh.  The
  **ServiceMeshMember** specifies a reference to the **ServiceMeshControlPlane** object that was used to install
  the control plane.  The user creating the **ServiceMeshMember** resource must have permission to *use* the
  **ServiceMeshControlPlane** object.  The adminstrator for the project containing the control plane can grant
  individual users or groups the *use* permissions.

2. A **ServiceMeshMemberRoll** resource may be created in the project containing the control plane.  This resource
  contains a single *members* list of all the projects that should belong in the mesh.  The resource must be named
  *default*.  The user creating the resource must have *edit* or *admin* permissions for all projects in the
  *members* list.

### More Information

* [Documentation](https://docs.openshift.com/container-platform/latest/service_mesh/v2x/servicemesh-release-notes.html)
* [Bugs](https://issues.redhat.com/projects/OSSM)