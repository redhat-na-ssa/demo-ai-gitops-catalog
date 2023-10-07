# nxrm-operator-certified

Nexus Repository is the central source of control to efficiently manage all binaries
and build artifacts across your DevOps pipeline.
The flow of open source and third-party components into and through an organization
creates a complex software supply chain.
Nexus Repository delivers speed, efficiency, and quality to the governance
and management of all dependencies, libraries, and applications for your DevOps teams.

## Core Capabilities

* **Dependency Management**:
  Improves reliability with repeatable, fast access to secure dependencies
* **Developer Productivity**:
  Streamline developer workflows by enabling the sharing of components and applications across teams
* **Supply Chain Performance**:
  Improve speed-to-market and reduced build times with release advanced staging and component tagging
* **CI/CD Integrations**:
  Increase DevOps scalability with integrations to the most popular build and deployment tools

Version control systems and package registries do not scale when managing proprietary,
open source, and third-party components.
Organizations need a central binary and build artifact repository to manage dependencies
across the entire software supply chain.

## Limitations

High Availability Clustering (HA-C) is not supported for Nexus Repository Pro for OpenShift.

This operator will be released on a quarterly basis.

## Controlling Automatic vs Manual Update

If you use the default configuration for the Nexus Repository Operator installation,
please notice that on any new operator release, the corresponding deployments are
also updated without user intervention, resulting in unscheduled downtime.

If you want to avoid this unscheduled downtime, we recommend installing the operator
into **its own namespace** with **manual approval** for updates.

## Usage

Once the server instance is created by the operator and running,
you'll want to expose the service as you see fit:
1. Create a Route to that service for nexus.port (8081).

By default, the Nexus Repository starts up in OSS mode until a license is installed.

The Nexus Repository can be further configured via the NexusRepo custom resource definition:

| Parameter                                   | Description                         | Default                                 |
| ------------------------------------------  | ----------------------------------  | ----------------------------------------|
| `statefulset.enabled`                       | Use statefulset instead of deployment | `false` |
| `deploymentStrategy.type`                   | Deployment Strategy     |  `Recreate` |
| `nexus.env`                                 | Nexus environment variables         | `See example.` |
| `nexus.resources`                           | Nexus resource requests and limits  | `{}`                                    |
| `nexus.dockerPort`                          | Port to access docker               | `5003`                                  |
| `nexus.nexusPort`                           | Internal port for Nexus service     | `8081`                                  |
| `nexus.service.type`                        | Service for Nexus                   |`NodePort`                                |
| `nexus.service.clusterIp`                   | Specific cluster IP when service type is cluster IP. Use None for headless service |`nil`   |
| `nexus.securityContext`                     | Security Context |
| `nexus.labels`                              | Service labels                      | `{}`                                    |
| `nexus.podAnnotations`                      | Pod Annotations                     | `{}`
| `nexus.livenessProbe.initialDelaySeconds`   | LivenessProbe initial delay         | 30                                      |
| `nexus.livenessProbe.periodSeconds`         | Seconds between polls               | 30                                      |
| `nexus.livenessProbe.failureThreshold`      | Number of attempts before failure   | 6                                       |
| `nexus.livenessProbe.timeoutSeconds`        | Time in seconds after liveness probe times out    | `nil`                     |
| `nexus.livenessProbe.path`                  | Path for LivenessProbe              | /                                       |
| `nexus.readinessProbe.initialDelaySeconds`  | ReadinessProbe initial delay        | 30                                      |
| `nexus.readinessProbe.periodSeconds`        | Seconds between polls               | 30                                      |
| `nexus.readinessProbe.failureThreshold`     | Number of attempts before failure   | 6                                       |
| `nexus.readinessProbe.timeoutSeconds`       | Time in seconds after readiness probe times out    | `nil`                    |
| `nexus.readinessProbe.path`                 | Path for ReadinessProbe             | /                                       |
| `nexus.hostAliases`                         | Aliases for IPs in /etc/hosts       | []                                      |
| `ingress.enabled`                           | Create an ingress for Nexus         | `true`                                  |
| `ingress.annotations`                       | Annotations to enhance ingress configuration  | `{}`                          |
| `ingress.tls.enabled`                       | Enable TLS                          | `true`                                 |
| `ingress.tls.secretName`                    | Name of the secret storing TLS cert, `false` to use the Ingress' default certificate | `nexus-tls`                             |
| `ingress.path`                              | Path for ingress rules. GCP users should set to `/*` | `/`                    |
| `tolerations`                               | tolerations list                    | `[]`                                    |
| `config.enabled`                            | Enable configmap                    | `false`                                 |
| `config.mountPath`                          | Path to mount the config            | `/sonatype-nexus-conf`                  |
| `config.data`                               | Configmap data                      | `nil`                                   |
| `deployment.terminationGracePeriodSeconds`  | Time to allow for clean shutdown    | 120                                     |
| `deployment.annotations`                    | Annotations to enhance deployment configuration  | `{}`                       |
| `deployment.initContainers`                 | Init containers to run before main containers  | `nil`                        |
| `deployment.postStart.command`              | Command to run after starting the nexus container  | `nil`                    |
| `deployment.preStart.command`               | Command to run before starting the nexus container  | `nil`                   |
| `deployment.additionalContainers`           | Add additional Container         | `nil`                                      |
| `deployment.additionalVolumes`              | Add additional Volumes           | `nil`                                      |
| `deployment.additionalVolumeMounts`         | Add additional Volume mounts     | `nil`                                      |
| `secret.enabled`                            | Enable secret                    | `false`                                    |
| `secret.mountPath`                          | Path to mount the secret         | `/etc/secret-volume`                       |
| `secret.readOnly`                           | Secret readonly state            | `true`                                     |
| `secret.data`                               | Secret data                      | `nil`                                      |
| `service.enabled`                           | Enable additional service        | `nil`                                      |
| `service.name`                              | Service name                     | `nil`                                      |
| `service.portName`                          | Service port name                | `nil`                                      |
| `service.labels`                            | Service labels                   | `nil`                                      |
| `service.annotations`                       | Service annotations              | `nil`                                      |
| `service.loadBalancerSourceRanges`          | Service LoadBalancer source IP whitelist | `nil`                              |
| `service.targetPort`                        | Service port                     | `nil`                                      |
| `service.port`                              | Port for exposing service        | `nil`                                      |
| `route.enabled`         | Set to true to create route for additional service | `false` |
| `route.name`            | Name of route                                      | `docker` |
| `route.portName`        | Target port name of service                        | `docker` |
| `route.labels`          | Labels to be added to route                        | `{}` |
| `route.annotations`     | Annotations to be added to route                   | `{}` |
| `route.path`            | Host name of Route e.g jenkins.example.com         | nil |