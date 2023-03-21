# ArgoCD Info

## Prerequisites

### Client

In order to bootstrap this repository you must have the following cli tools:

- `oc` - Download [mac](https://formulae.brew.sh/formula/openshift-cli), [linux](https://mirror.openshift.com/pub/openshift-v4/clients)
- `kustomize` (optional) - Download [mac](https://formulae.brew.sh/formula/kustomize), [linux](https://github.com/kubernetes-sigs/kustomize/releases)

## Bootstrapping a Cluster

Before beginning, make sure you are logged into your cluster using `oc`.

Next, clone this repository to your local environment.

### Sealed Secrets Bootstrap

This repository deploys sealed-secrets and requires a sealed secret master key to bootstrap.  If you plan to reuse sealed-secrets created using another key you must obtain that key from the person that created the sealed-secrets.

The sealed secret(s) for bootstrap should be located at:
```sh
bootstrap/base/sealed-secrets-secret.yaml
```

If you do not plan to utilize existing sealed secrets you can instead bootstrap a new sealed-secrets controller and obtain a new secret. 

`bootstrap.sh` can also be to used to create the file if it doesn't already exist.

### Cluster Bootstrap

Execute the following script:

```sh
./scripts/bootstrap.sh
```

The `bootstrap.sh` script will install the OpenShift GitOps Operator, create an ArgoCD instance once the operator is deployed in the `openshift-gitops` namespace, and bootstrap a set of ArgoCD applications to configure the cluster.

Once the script completes, verify that you can access the ArgoCD UI using the URL output by the last line of the script execution. This URL should present an ArgoCD login page, showing that it was successfully deployed.

Alternatively you can also obtain the ArgoCD login URL from the ArgoCD route:

```sh
oc get routes openshift-gitops-server -n openshift-gitops
```

Use the OpenShift Login option and sign in with your OpenShift credentials.

The cluster may take 10-15 minutes to finish installing and updating.

## Project Structure Overview

This project structure is based on the opinionated configuration found [here](https://github.com/gnunn-gitops/standards/blob/master/folders.md).  For a more detailed breakdown of the intention of this folder structure, feel free to read more there.

### Bootstrap

The bootstrap folder contains the initial set of resources utilized to deploy the cluster.

### Clusters

Clusters is the main aggregation layer for all of the elements of the cluster.  It also contains the main configuration elements for changing the repo/branch of the project.

### Components

Components contains the bulk of the configuration.  Currently we are utilizing two main folders inside of `components`:

- argocd
- operators
- rbac
- simple

The opinionated configuration referenced above recommends several other folders in the `components` folder that we are not utilizing today but may be useful to add in the future.

#### ArgoCD

The argocd folder contains the ArgoCD specific objects needed to configure the items in the apps folder.  The folders inside of Argo represent the different custom resources ArgoCD supports and refer back to objects in the `apps` folder.

#### Operators

Operators contain the operators we wish to configure on the cluster and the details of how we would like them to be configured.

The operators folder general follows a pattern where each folder in `operators` is intended to be a separate ArgoCD application.  The majority of the folder structure utilized inside of those folders is a direct reference to the [redhat-cop/gitops-catalog](https://github.com/redhat-cop/gitops-catalog).  When attempting to add new operators to the cluster, be sure to check there first and feel free to contribute new components back to the catalog as well!

## Updating the ArgoCD Groups

Argo creates the following group in OpenShift to grant access and control inside of ArgoCD:

- gitops-admins

To add a user to the admin group run:

```sh
oc adm groups add-users gitops-admins $(oc whoami)
```

To add a user to the user group run:

```sh
oc adm groups add-users gitops-users $(oc whoami)
```

Once the user has been added to the group logout of Argo and log back in to apply the updated permissions.

Can you validate that you have the correct permissions by going to `User Info` menu inside of Argo.

## Accessing Argo using the CLI

To log into ArgoCD using the `argocd` cli tool run the following command:

```sh
argocd login --sso <argocd-route> --grpc-web
```

## ArgoCD Troubleshooting

### Operator Shows Progressing for a Very Long Time

ArgoCD Symptoms:

Argo Applications and the child subscription object for operator installs show `Progressing` for a very long time.

Explanation:

Argo utilizes a `Health Check` to validate if an object has been successfully applied and updated, failed, or is progressing by the cluster.  The health check for the `Subscription` object looks at the `Condition` field in the `Subscription` which is updated by the `OLM`.  Once the `Subscription` is applied to the cluster, `OLM` creates several other objects in order to install the Operator.  Once the Operator has been installed `OLM` will report the status back to the `Subscription` object.  This reconciliation process may take several minutes even after the Operator has successfully installed.

Resolution/Troubleshooting:
- Validate that the Operator has successfully installed via the `Installed Operators` section of the OpenShift Web Console.
- If the Operator has not installed, additional troubleshooting is required.
- If the Operator has successfully installed, feel free to ignore the `Progressing` state and proceed.  `OLM` should reconcile the status after several minutes and Argo will update the state to `Healthy`.
