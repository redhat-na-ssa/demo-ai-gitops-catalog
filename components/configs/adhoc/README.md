# Adhoc tasks

In an ideal world this folder will be empty.

The objects in this folder are a short path to a solution and would love having
your attention to obtain non-kludged status.

Lets remove kubeadmin...

```
TOKEN=$(oc -n adhoc-ops \
  exec deploy/sleeper-admin-0 -- oc whoami -t)

oc login --token $TOKEN
```
