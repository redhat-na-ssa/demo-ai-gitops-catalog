# rhsso-operator

A Kubernetes Operator based on the Operator SDK for installing and managing Red Hat Single Sign-On.

Red Hat Single Sign-On lets you add authentication to applications and secure services with minimum fuss. No need to deal with storing users or authenticating users. It's all available out of the box.

The operator can deploy and manage Keycloak instances on Kubernetes and OpenShift.
The following features are supported:

* Install Keycloak to a namespace
* Import Keycloak Realms
* Import Keycloak Clients
* Import Keycloak Users
* Create scheduled backups of the database
