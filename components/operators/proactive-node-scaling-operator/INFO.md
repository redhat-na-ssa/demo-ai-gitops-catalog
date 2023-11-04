# proactive-node-scaling-operator

This operator makes the [cluster autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) more proactive. As of now the cluster auto scaler will create new nodes only when a pod is pending because it cannot be allocated due to lack of capacity. This is not a goos user experience as the pending workload has to wait for several minutes as the new node is create and joins the cluster.

The Proactive Node Scaling Operator improves the user experience by allocating low priority pods that don't do anything. When the cluster is full and a new user pod is created the following happens:

1. some of the low priority pods are de-scheduled to make room for the user pod, which can then be scheduled. The user workload does not have to wait in this case.

2. the de-scheduled low priority pods are rescheduled and in doing so the trigger the cluster autoscaler to add new nodes.

Essentially this operator allows you to trade wasted resources for faster response time.

In order for this operator to work correctly [pod priorities](https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/) must be defined. The default name for the priority class used by this operator is "proactive-node-autoscaling-pods" and it should have the lowest possible priority, 0. To ensure your regular workloads get a normal priority you should also define a PriorityClass for those with a higher priority than 0 and set globalDefault to true.

For example:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: proactive-node-autoscaling-pods
value: 0
globalDefault: false
description: "This priority class is the priority class used for Proactive Node Scaling Pods."
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: normal-workload
value: 1000
globalDefault: true
description: "This priority classis the cluster default and should be used for normal workloads."
```

Also for this operator to work the [cluster autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) must be active, see OpenShift instructions [here](https://docs.openshift.com/container-platform/4.6/machine_management/applying-autoscaling.html) on how to turn it on.

To activate the proactive autoscaling, a CR must be defined, here is an example:

```yaml
apiVersion: redhatcop.redhat.io/v1alpha1
kind: NodeScalingWatermark
metadata:
  name: us-west-2a
spec:
  priorityClassName: proactive-node-autoscaling-pods
  watermarkPercentage: 20
  nodeSelector:
    topology.kubernetes.io/zone: us-west-2a
```

The `nodeSelector` selects the nodes observed by this operator, which are also the nodes on which the low priority pods will be scheduled. The nodes observed by the cluster autoscaler should coincide with the nodes selected by this operator CR.

The `watermarkPercentage` define the percentage of capacity of user workload that will be allocated to low priority pods. So in this example 20% of the user allocated capacity will be allocated via low priority pods. This also means that when the user workload reaches 80% capacity of the nodes selected by this CR (and the autoscaler), the cluster will start to scale.
