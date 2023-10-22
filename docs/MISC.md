# Misc

## triggerer

oc patch statefulset/airflow-triggerer --patch '{"spec":{"template":{"spec":{"initContainers":[{"name":"git-sync-init","securityContext":null}]}}}}'

oc patch statefulset/airflow-triggerer --patch '{"spec":{"template":{"spec":{"containers":[{"name":"git-sync","securityContext":null}]}}}}'

## worker

oc patch statefulset/airflow-worker --patch '{"spec":{"template":{"spec":{"initContainers":[{"name":"git-sync-init","securityContext":null}]}}}}'

oc patch statefulset/airflow-worker --patch '{"spec":{"template":{"spec":{"containers":[{"name":"git-sync","securityContext":null}]}}}}'

