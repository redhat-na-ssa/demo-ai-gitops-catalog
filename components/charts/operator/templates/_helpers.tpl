{{/*
Expand the name of the chart.
*/}}
{{- define "operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Define the default namespace.
*/}}
{{- define "operator.namespace" -}}
{{- default "openshift-operators" .Values.targetNamespace | trunc 63 | trimSuffix "-" }}
{{- end }}
