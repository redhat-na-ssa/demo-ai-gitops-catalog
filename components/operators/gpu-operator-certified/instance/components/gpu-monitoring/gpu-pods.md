# Low Cluster Queue Resource Usage

## Severity: Info

## Impact

Cloud costs may increase by requesting specialized resources.

## Summary

This alert is triggered when the nvidia GPUs are requested.

## Steps

* Check current resource usage for the cluster and ensure the resource in question is correctly configured.

```sh
oc describe pod < pod name >
```
