# kiali-ossm

## About the managed application

A Microservice Architecture breaks up the monolith into many smaller pieces
that are composed together. Patterns to secure the communication between
services like fault tolerance (via timeout, retry, circuit breaking, etc.)
have come up as well as distributed tracing to be able to see where calls
are going.

A service mesh can now provide these services on a platform level and frees
the application writers from those tasks. Routing decisions are done at the
mesh level.

Kiali works with OpenShift Service Mesh to visualize the service
mesh topology, to provide visibility into features like circuit breakers,
request rates and more. It offers insights about the mesh components at
different levels, from abstract Applications to Services and Workloads.

See [https://www.kiali.io](https://www.kiali.io) to read more.

### Accessing the UI

By default, the Kiali operator exposes the Kiali UI as an OpenShift Route.

If on OpenShift, you can create an OSSMConsole CR to have the operator
install the OpenShift ServiceMesh Console plugin to the OpenShift Console
thus providing an interface directly integrated with the OpenShift Console.

## About this Operator

### Kiali Custom Resource Configuration Settings

For quick descriptions of all the settings you can configure in the Kiali
Custom Resource (CR), see
[the kiali.io docs](https://kiali.io/docs/configuration/kialis.kiali.io/).

## Prerequisites for enabling this Operator

Kiali is a companion tool for OpenShift Service Mesh. So before you install Kiali, you must have
already installed Service Mesh.