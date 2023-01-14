# Notes

## Set control-plane nodes as NoSchedulable

```
# run work on masters
oc patch schedulers.config.openshift.io/cluster --type merge --patch '{"spec":{"mastersSchedulable": true}}'

# scale down workers
oc scale $(oc -n openshift-machine-api get machineset -o name | grep worker) -n openshift-machine-api --replicas=0
```
