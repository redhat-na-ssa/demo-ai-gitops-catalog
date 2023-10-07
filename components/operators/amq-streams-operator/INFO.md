# amq-streams

**Red Hat AMQ Streams** is a massively scalable, distributed, and high performance data streaming platform based on the Apache Kafka® project. AMQ Streams provides an event streaming backbone that allows microservices and other application components to exchange data with extremely high throughput and low latency.
**The core capabilities include:**
* A pub/sub messaging model, similar to a traditional enterprise messaging system, in which application components publish and consume events to/from an ordered stream
* The long term, fault-tolerant storage of events
* The ability for a consumer to replay streams of events
* The ability to partition topics for horizontal scalability
### CRD Upgrades
**!!! IMPORTANT !!!**  This release supports only the API version `v1beta2` and CRD version `apiextensions.k8s.io/v1`.  If upgrading from AMQ Streams 1.7, migration to `v1beta2` needs to be completed for all AMQ Streams CRDs and CRs before the upgrade to 1.8 is done!  If upgrading from AMQ Streams version earlier than 1.7, you need to first install the CRDs from AMQ Streams 1.7 and complete the migration to `v1beta2` for all AMQ Streams CRDs and CRs before the upgrade to 1.8 is done!  For more details about the CRD upgrades, see the [documentation](https://access.redhat.com/documentation/en-us/red_hat_amq/2021.q3/html/deploying_and_upgrading_amq_streams_on_openshift/assembly-upgrade-str#assembly-upgrade-resources-str).
### Supported Features
* **Manages the Kafka Cluster** - Deploys and manages all of the components of this complex application, including dependencies like Apache ZooKeeper® that are traditionally hard to administer.
* **Includes Kafka Connect** - Allows for configuration of common data sources and sinks to move data into and out of the Kafka cluster.
* **Topic Management** - Creates and manages Kafka Topics within the cluster.
* **User Management** - Creates and manages Kafka Users within the cluster.
* **Connector Management** - Creates and manages Kafka Connect connectors.
* **Includes Kafka Mirror Maker 1 and 2** - Allows for mirroring data between different Apache Kafka® clusters.
* **Includes HTTP Kafka Bridge** - Allows clients to send and receive messages through an Apache Kafka® cluster via HTTP protocol.
* **Cluster Rebalancing** - Uses built-in Cruise Control for redistributing partition replicas according to specified goals in order to achieve the best cluster performance.
* **Monitoring** - Built-in support for monitoring using Prometheus and provided Grafana dashboards
### Upgrading your Clusters
The AMQ Streams Operator understands how to run and upgrade between a set of Kafka versions. When specifying a new version in your config, check to make sure you aren't using any features that may have been removed. See [the upgrade guide](https://access.redhat.com/documentation/en-us/red_hat_amq/2021.q2/html/deploying_and_upgrading_amq_streams_on_openshift/assembly-upgrade-str) for more information.
### Storage
An efficient data storage infrastructure is essential to the optimal performance of Apache Kafka®. Apache Kafka® deployed via AMQ Streams requires block storage. The use of file storage (for example, NFS) is not recommended.
The AMQ Streams supports three types of data storage:
* Ephemeral (Recommended for development only!)
* Persistent
* JBOD (Just a Bunch of Disks, suitable for Kafka only. Not supported in Zookeeper.)
AMQ Streams also supports advanced operations such as adding or removing disks in Apache Kafka® brokers or resizing the persistent volumes (where supported by the infrastructure).
### Documentation
Documentation for the current release can be found on the Red Hat [Customer Portal](https://access.redhat.com/documentation/en-us/red_hat_amq/2021.q2/html/using_amq_streams_on_openshift/index).
