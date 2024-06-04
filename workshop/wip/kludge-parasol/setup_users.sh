#!/bin/bash
# shellcheck disable=SC2034

MINIO_ROOT_USER=$(oc get secret minio-root-user -n ic-shared-minio -o template --template '{{.data.MINIO_ROOT_USER|base64decode}}')
MINIO_ROOT_PASSWORD=$(oc get secret minio-root-user -n ic-shared-minio -o template --template '{{.data.MINIO_ROOT_PASSWORD|base64decode}}')
MINIO_HOST=https://$(oc get route minio-s3 -n ic-shared-minio -o template --template '{{.spec.host}}')
DASHBOARD_ROUTE=https://$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}')

oc apply -k instance