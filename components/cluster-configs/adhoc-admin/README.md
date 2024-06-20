# Adhoc Admin

In an ideal world this folder will be empty.

The objects in this folder are a short path to a solution and would love having
your attention to obtain non-kludged status.

Once we have an Identity Provider lets remove `kubeadmin`...

```sh
TOKEN=$(oc -n adhoc-admin \
  exec deploy/sleeper-admin-0 -- oc whoami -t)

oc login --token $TOKEN
```
