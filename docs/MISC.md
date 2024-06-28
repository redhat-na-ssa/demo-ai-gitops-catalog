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

```sh
oc -n openshift-config delete cm openshift-service-ca.crt
oc -n openshift-ingress delete cm service-ca-bundle 
oc -n openshift-authentication delete cm v4-0-config-system-service-ca
oc -n openshift-authentication delete cm v4-0-config-system-trusted-ca-bundle
```

Label storage nodes to deploy odf

```
oc label node cluster.ocs.openshift.io/openshift-storage="" --all
# oc label nodes --selector='node-role.kubernetes.io/worker' cluster.ocs.openshift.io/openshift-storage="" --overwrite=true

oc annotate sc ocs-storagecluster-cephfs storageclass.kubernetes.io/is-default-class="true"
```

Setup image registry

```
# check storage class
oc get sc

# setup registry operator
oc patch configs.imageregistry.operator.openshift.io/cluster --type=merge -p '{"spec":{"rolloutStrategy":"RollingUpdate","replicas":2}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge -p '{"spec":{"managementState":"Managed"}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge -p '{"spec":{"storage":{"pvc":{"claim": null}}}}'
```

Expose image registry

```
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge

HOST=$(oc get route default-route -n openshift-image-registry --template='{{ .spec.host }}')
```
