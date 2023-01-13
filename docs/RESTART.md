```
oc annotate -n openshift-config secret/htpasswd-secret \
  sealedsecrets.bitnami.com/managed='true'
```

```
oc delete -n openshift-config secret/htpasswd-secret
```