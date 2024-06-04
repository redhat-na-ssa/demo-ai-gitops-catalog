# elasticsearch-operator

The Elasticsearch Operator for OCP provides a means for configuring and managing an Elasticsearch cluster for use in tracing 
and cluster logging as well as a Kibana instance to connect to it.
This operator only supports OCP Cluster Logging and Jaeger.  It is tightly coupled to each and is not currently capable of
being used as a general purpose manager of Elasticsearch clusters running on OCP.

Please note: For a general purpose Elasticsearch operator, please use Elastic's Elasticsearch (ECK) Operator [here](https://catalog.redhat.com/software/containers/elastic/eck-operator/5fabf6d1ecb52450895164be?container-tabs=gti)

It is recommended that this operator be installed in the `openshift-operators-redhat` namespace to 
properly support the Cluster Logging and Jaeger use cases.

Once installed, the operator provides the following features for **Elasticsearch**:
* **Create/Destroy**: Deploy an Elasticsearch cluster to the same namespace in which the elasticsearch CR is created.
* **Update**: Changes to the elasticsearch CR will be scheduled and applied to the cluster in a controlled manner (most often as a rolling upgrade).
* **Cluster health**: The operator will periodically poll the cluster to evaluate its current health (such as the number of active shards and if any cluster nodes have reached their storage watermark usage).
* **Redeploys**: In the case where the provided secrets are updated, the Elasticsearch Operator will schedule and perform a full cluster restart.
* **Index management**: The Elasticsearch Operator will create cronjobs to perform index management such as roll over and deletion.

Once installed, the operator provides the following features for **Kibana**:
* **Create/Destroy**: Deploy a Kibana instance to the same namespace in which the kibana CR is created (this should be the same namespace as the elasticsearch CR).
* **Update**: Changes to the kibana CR will be scheduled and applied to the cluster in a controlled manner.
* **Redeploys**: In the case where the provided secrets are updated, the Elasticsearch Operator will perform a restart.

### Additionally provided features
* Out of the box multitenancy that is integrated with OCP user access control.
* Document Level Security
* mTLS communication between Elasticsearch, Kibana, Index Management cronjobs, and CLO's Fluentd
* OCP prometheus dashboard for Elasticsearch clusters
* Prometheus Alerting rules  
