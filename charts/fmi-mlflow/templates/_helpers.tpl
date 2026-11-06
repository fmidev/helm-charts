{{/*
Expand the name of the chart.
*/}}
{{- define "mlflow.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mlflow.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mlflow.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mlflow.labels" -}}
helm.sh/chart: {{ include "mlflow.chart" . }}
{{ include "mlflow.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mlflow.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mlflow.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "environment" -}}
{{- if eq .Values.environment "prod" }}ocp{{- else }}ock{{- end }}
{{- end -}}

{{/*
MLflow image, tag defaults to v<appVersion>-full
*/}}
{{- define "mlflow.image" -}}
{{- $tag := .Values.mlflow.image.tag | default (printf "v%s-full" .Chart.AppVersion) }}
{{- printf "%s:%s" .Values.mlflow.image.repository $tag }}
{{- end }}

{{/*
Public hostname of the route
*/}}
{{- define "mlflow.host" -}}
{{ .Release.Namespace }}.out.{{ include "environment" . }}.{{ .Values.host }}
{{- end -}}

{{/*
Read-write service of the postgresql cluster
*/}}
{{- define "mlflow.dbHost" -}}
{{ .Values.postgresql.clusterName }}-rw.{{ .Release.Namespace }}:5432
{{- end -}}

{{/*
Database credentials. The database uris don't contain credentials,
libpq reads them from the PGUSER and PGPASSWORD environment variables.
*/}}
{{- define "mlflow.dbEnv" -}}
- name: PGUSER
  valueFrom:
    secretKeyRef:
      name: {{ .Values.postgresql.secrets.mlflow }}
      key: username
- name: PGPASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ .Values.postgresql.secrets.mlflow }}
      key: password
{{- end -}}
