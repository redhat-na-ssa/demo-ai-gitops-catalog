# odf-operator

**Red Hat OpenShift Data Foundation** deploys three operators.

### OpenShift Data Foundation
The OpenShift Data Foundation operator is the primary operator for
OpenShift Data Foundation. It serves to facilitate the other operators in
OpenShift Data Foundation by performing administrative tasks outside their
scope as well as watching and configuring their CustomResources.

### Rook
[Rook][1] deploys and manages Ceph on OpenShift, which provides block,
file and object storage.

### NooBaa operator
The NooBaa operator deploys and manages the [NooBaa][2] Multi-Cloud Gateway
on OpenShift, which provides object storage.

# Core Capabilities
* **Self-managing service:** No matter which supported storage technologies
you choose, OpenShift Data Foundation ensures that resources can be
deployed and managed automatically.

* **Hyper-scale or hyper-converged:** With OpenShift Data Foundation you
can either build dedicated storage clusters or hyper-converged clusters
where your apps run alongside storage.

* **File, Block, and Object provided by OpenShift Data Foundation:**
OpenShift Data Foundation integrates Ceph with multiple storage
presentations including object storage (compatible with S3), block storage,
and POSIX-compliant shared file system.

* **Your data, protected:** OpenShift Data Foundation efficiently
distributes and replicates your data across your cluster to minimize the
risk of data loss. With snapshots, cloning, and versioning, no more losing
sleep over your data.

* **Elastic storage in your datacenter:** Scale is now possible in your
datacenter. Get started with a few terabytes, and easily scale up.

* **Simplified data management:** Easily create hybrid and multi-cloud data
storage for your workloads, using a single namespace.

# Subscriptions
OpenShift Data Foundation requires a matching 1:1 ratio with the OpenShift
subscription used. The Essential subscription is included in the OpenShift
Platform Plus subscription. Disaster Recovery features, external mode, and
KMS integration for encryption at rest require a bundle of OpenShift
Platform Plus with OpenShift Data Foundation Advanced subscription.

[1]: https://rook.io
[2]: https://www.noobaa.io
