# Steps

Create a L4 GPU MachineSet (g6.xlarge)

In the machine set template add the following:

```yaml
spec:
  template:
    spec:
      taints:
      - effect: NoSchedule           
        key: nvidia.com/gpu
        value: ''
      metadata:
        labels:
          cluster-api/accelerator: nvidia-l4
```

Create a A10 GPU Machineset (g5.xlarge)

Same as above, this time:

```yaml
spec:
  template:
    spec:
      taints:
      - effect: NoSchedule           
        key: nvidia.com/gpu
        value: ''
      metadata:
        labels:
          cluster-api/accelerator: nvidia-a10g
```

Install NFD Operator and NFD Instance as usual

Install GPU Operator and GPU Cluster Policy as usual

Create autoscalers

```bash
oc create -f cluster-autoscaler.yaml
oc create -f l4-autoscaler.yaml
oc create -f a10-autoscaler.yaml
```

Finally, deploy the sample apps:

```bash
oc new-project sandbox
oc create -f cuda-a10.yaml
oc create -f cuda-l4.yaml
```
