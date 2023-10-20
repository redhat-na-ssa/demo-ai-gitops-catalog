# Misc

## triggerer

oc patch statefulset/airflow-triggerer --patch '{"spec":{"template":{"spec":{"initContainers":[{"name":"git-sync-init","securityContext":null}]}}}}'

oc patch statefulset/airflow-triggerer --patch '{"spec":{"template":{"spec":{"containers":[{"name":"git-sync","securityContext":null}]}}}}'

## worker

oc patch statefulset/airflow-worker --patch '{"spec":{"template":{"spec":{"initContainers":[{"name":"git-sync-init","securityContext":null}]}}}}'

oc patch statefulset/airflow-worker --patch '{"spec":{"template":{"spec":{"containers":[{"name":"git-sync","securityContext":null}]}}}}'

oc mirror list operators --catalog registry.redhat.io/redhat/redhat-operator-index:v4.12 --package rhods-operator
