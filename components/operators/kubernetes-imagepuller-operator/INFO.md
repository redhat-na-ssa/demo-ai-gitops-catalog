# kubernetes-imagepuller-operator

## About the managed application

Create a `KubernetesImagePuller` custom resource to automatically configure and run an instance of the [kubernetes-image-puller.](https://github.com/che-incubator/kubernetes-image-puller)
## About this Operator

The `KubernetesImagePuller` custom resource understands the following fields in the `spec`:

1. `configMapName` - The name of the `ConfigMap` to create	
2. `daemonsetName` - The name of the `DaemonSet` to be create.
3. `deploymentName` - The name of the `kubernetes-image-puller` `Deployment` to create.
4. `images` - A list of key-value pairs separated by semicolons of images to pull.  For example: `java=quay.io/eclipse/che-java8-maven:latest;theia=quay.io/eclipse/che-theia:next`
5. `cachingIntervalHours` - The amount of time, in hours, between `DaemonSet` health checks.
6. `cachingMemoryRequest` - The memory request for each cached image when the puller is running.
7. `cachingMemoryLimit` - The memory limit for each cached image when the puller is running.
8. `nodeSelector` - Node selector applied to pods created by the `DaemonSet`.
## Prerequisites for enabling this Operator

The operator requires an existing namespace to be installed in.
