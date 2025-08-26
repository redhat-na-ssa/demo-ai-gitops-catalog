# strimzi-kafka-operator

Strimzi provides a way to run an [Apache Kafka®](https://kafka.apache.org) cluster on [Kubernetes](https://kubernetes.io/) or [OpenShift](https://www.openshift.com/) in various deployment configurations. See our [website](https://strimzi.io) for more details about the project.
### !!! IMPORTANT !!!
* **Support for ZooKeeper-based clusters and for migration from ZooKeeper-based clusters to KRaft has been removed.**
  Please make sure all your clusters are using KRaft before upgrading to Strimzi 0.46.0 or newer!

* **Strimzi 0.47 is the last Strimzi version with support for Kubernetes 1.25 and 1.26.**
  From Strimzi 0.48.0 on, we will support only Kubernetes 1.27 and newer.

* **Strimzi EnvVar Configuration Provider (deprecated in Strimzi 0.38.0) and Strimzi MirrorMaker 2 Extensions (deprecated in Strimzi 0.28.0) plugins were removed from Strimzi container images.**
  Please use the Apache Kafka EnvVarConfigProvider and Identity Replication Policy instead.

* **Support for MirrorMaker 1 has been removed.**
  Please make sure to migrate to MirrorMaker 2 before upgrading to Strimzi 0.46 or newer.

### New in 0.47.0
* Support for Kafka 3.9.1
* Progress tracking for Cruise Control rebalances
* Support for Kubernetes Image Volumes to mount custom plugins
* Support for [JsonTemplateLayout](https://logging.apache.org/log4j/2.x/manual/json-template-layout.html) in Operators, Cruise Control, and Kafka 4.0.0
* Support for Strimzi Metrics Reporter for the Kafka brokers / controllers
### Supported Features
* **Manages the Kafka Cluster** - Deploys and manages all of the components of this complex application, including dependencies like Apache ZooKeeper® that are traditionally hard to administer.
* **Supports KRaft** - You can run your Apache Kafka clusters without Apache ZooKeeper.
* **Tiered storage** - Offloads older, less critical data to a lower-cost, lower-performance storage tier, such as object storage.
* **Includes Kafka Connect** - Allows for configuration of common data sources and sinks to move data into and out of the Kafka cluster.
* **Topic Management** - Creates and manages Kafka Topics within the cluster.
* **User Management** - Creates and manages Kafka Users within the cluster.
* **Connector Management** - Creates and manages Kafka Connect connectors.
* **Includes Kafka Mirror Maker 2** - Allows for mirroring data between different Apache Kafka® clusters.
* **Includes HTTP Kafka Bridge** - Allows clients to send and receive messages through an Apache Kafka® cluster via HTTP protocol.
* **Cluster Rebalancing** - Uses built-in Cruise Control for redistributing partition replicas according to specified goals in order to achieve the best cluster performance.
* **Auto-rebalancing when scaling** - Automatically rebalance the Kafka cluster after a scale-up or before a scale-down.
* **Monitoring** - Built-in support for monitoring using Prometheus and provided Grafana dashboards
### Upgrading your Clusters
The Strimzi Operator understands how to run and upgrade between a set of Kafka versions. When specifying a new version in your config, check to make sure you aren't using any features that may have been removed. See [the upgrade guide](https://strimzi.io/docs/operators/latest/deploying.html#assembly-upgrading-kafka-versions-str) for more information.
### Storage
An efficient data storage infrastructure is essential to the optimal performance of Apache Kafka®. Apache Kafka® deployed via Strimzi requires block storage. The use of file storage (for example, NFS) is not recommended.
The Strimzi Operator supports three types of data storage:
* Ephemeral (Recommended for development only!)
* Persistent
* JBOD (Just a Bunch of Disks, suitable for Kafka only. Not supported in Zookeeper.)
Strimzi also supports advanced operations such as adding or removing disks in Apache Kafka® brokers or resizing the persistent volumes (where supported by the infrastructure).
### Documentation
Documentation to the current _main_ branch as well as all releases can be found on our [website](https://strimzi.io/documentation).
### Getting help
If you encounter any issues while using Strimzi, you can get help using:
* [Strimzi mailing list on CNCF](https://lists.cncf.io/g/cncf-strimzi-users/topics)
* [Strimzi Slack channel on CNCF workspace](https://cloud-native.slack.com/messages/strimzi)
### Contributing
Learn more about contributing to Strimzi on our [Join Us page](https://strimzi.io/join-us/).
### License
Strimzi is licensed under the [Apache License, Version 2.0](https://github.com/strimzi/strimzi-kafka-operator/blob/main/LICENSE).
