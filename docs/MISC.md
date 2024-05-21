# Misc

## triggerer

oc patch statefulset/airflow-triggerer --patch '{"spec":{"template":{"spec":{"initContainers":[{"name":"git-sync-init","securityContext":null}]}}}}'

oc patch statefulset/airflow-triggerer --patch '{"spec":{"template":{"spec":{"containers":[{"name":"git-sync","securityContext":null}]}}}}'

## worker

oc patch statefulset/airflow-worker --patch '{"spec":{"template":{"spec":{"initContainers":[{"name":"git-sync-init","securityContext":null}]}}}}'

oc patch statefulset/airflow-worker --patch '{"spec":{"template":{"spec":{"containers":[{"name":"git-sync","securityContext":null}]}}}}'

## RHDP Bastion login

```sh
ssh-copy-id 'lab-user@bastion...
```

## Resolve ingress / auth cert issues

```
oc -n openshift-config delete cm openshift-service-ca.crt
oc -n openshift-ingress delete cm service-ca-bundle 
oc -n openshift-authentication delete cm v4-0-config-system-service-ca
oc -n openshift-authentication delete cm v4-0-config-system-trusted-ca-bundle
```
