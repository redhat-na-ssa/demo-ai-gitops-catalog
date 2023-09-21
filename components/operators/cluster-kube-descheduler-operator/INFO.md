# cluster-kube-descheduler-operator

The Kube Descheduler Operator provides the ability to evict a running pod so that the pod can be rescheduled onto a more suitable node.

There are several situations where descheduling can benefit your cluster:

* Nodes are underutilized or overutilized.
* Pod and node affinity requirements, such as taints or labels, have changed and the original scheduling decisions are no longer appropriate for certain nodes.
* Node failure requires pods to be moved.
* New nodes are added to clusters.

## Descheduler Profiles

Once the operator is installed, you can configure one or more profiles to identify pods to evict. The scheduler will schedule the replacement of the evicted pods.

The following profiles are available:

* AffinityAndTaints
* TopologyAndDuplicates
* SoftTopologyAndDuplicates
* LifecycleAndUtilization
* EvictPodsWithPVC
* EvictPodsWithLocalStorage

These profiles are documented in detail in the [descheduler operator README](https://github.com/openshift/cluster-kube-descheduler-operator#profiles).

## Additional Parameters

In addition to the profiles, the following parameters can be configured:

* `deschedulingIntervalSeconds` - Set the number of seconds between descheduler runs. A value of `0` in this field runs the descheduler once and exits.
* `profileCustomizations` - Allows certain profile parameters to be tweaked, such as `podLifetime` (see [README](https://github.com/openshift/cluster-kube-descheduler-operator#profile-customizations) for more info).
