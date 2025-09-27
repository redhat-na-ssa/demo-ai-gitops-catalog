# OpenShift - General

## Privileged Deployment - `root`

By default all pods in OpenShift run unprivileged (not `root`). Thoughtfully allows root privileges on a per project and a case by case basis.

!!! WARNING
    For security reasons it’s recommended to run as non-root (default) and update your container to work in this security context.

### Option 1

Update the container to run as a non-root user at the bottom of your `Dockerfile`

```sh
USER 1001
```

### Option 2

Use the `oc adm policy` `scc-subject-review` sub-command to list all the security context constraints that can overcome the limitations that hinder the container.

```sh
oc -n <namespace> get deployment <deployment-name> -o yaml | \
  oc adm policy scc-subject-review -f -
```

Create a service account in the namespace of your container.

```sh
oc -n <namespace> create serviceaccount <service-account-name>
```

Associate the service account with a SCC

```sh
oc adm policy add-scc-to-user <scc-name> \
  -z <service-account-name> \
  -n <project>
```

Update existing deployment with newly created service account

```sh
oc set serviceaccount deployment/<deployment-name> \
  <service-account-name> -n <project>
```

### Option 3 (Not Recommended)

Update the `privileged` Security Context Constraints by adding the projects `default` service account.

```sh
oc edit scc privileged
```

!!! NOTE
    You can apply this to any project and any service account in use with the deployment. In the following example we’re using the `default` project / namespace and the `default` service account.

```yaml hl_lines="4"
users:
- system:admin
- system:serviceaccount:openshift-infra:build-controller
- system:serviceaccount:default:default
```

Update deployment - changes highlighted below

```yaml hl_lines="5 16 24-28"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: busybox
  template:
    metadata:
      labels:
        app: busybox
    spec:
      serviceAccountName: default
      containers:
      - image: docker.io/library/busybox:latest
        command:
          - sleep
          - infinity
        name: busybox
        securityContext:
          runAsUser: 0
          privileged: true
          allowPrivilegeEscalation: true
          runAsNonRoot: false
          seccompProfile:
            type: RuntimeDefault
          capabilities:
            drop: ["ALL"]
        ports:
        - containerPort: 8080
          protocol: TCP
```

## Rename a node

Evacuate the node:

```sh
oc adm drain < node > --ignore-daemonsets
```

Make the DNS / hostname change.
If the hostname is not DNS name, you can use the following command on the node itself:

```sh
# vi /etc/hostname
hostnamectl set-hostname < hostname >
```

Delete old certificates (which are valid only for the old hostname) on the node:

```sh
sudo rm /var/lib/kubelet/pki/*
```

Delete the node

```sh
oc delete node < node >
```

Reboot the server

```sh
sudo reboot
```

Approve csrs

```sh
# get csr
oc get csr

# approve all csr
oc get csr -o name | xargs oc adm certificate approve
```

Now you should see the node with the new name:

```sh
oc get nodes
```

## Community Operators

- [Community Operators Index](https://github.com/redhat-openshift-ecosystem/community-operators-prod)

## Registry Caching

- https://github.com/obeone/multi-registry-cache
- https://zotregistry.dev/v2.1.8/articles/mirroring/?h=#basic-configuration-for-mirroring-with-sync
- https://github.com/rpardini/docker-registry-proxy
