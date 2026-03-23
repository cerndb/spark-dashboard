{{/* vim: set filetype=mustache: */}}
{{- define "spark_dashboard_v2.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "spark_dashboard_v2.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "spark_dashboard_v2.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "spark_dashboard_v2.labels" -}}
helm.sh/chart: {{ include "spark_dashboard_v2.chart" . }}
app.kubernetes.io/name: {{ include "spark_dashboard_v2.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "spark_dashboard_v2.selectorLabels" -}}
app.kubernetes.io/name: {{ include "spark_dashboard_v2.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
