{{/*
Expand the name of the chart.
*/}}
{{- define "radon.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "radon.fullname" -}}
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
{{- define "radon.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "radon.labels" -}}
helm.sh/chart: {{ include "radon.chart" . }}
{{ include "radon.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "radon.selectorLabels" -}}
app.kubernetes.io/name: {{ include "radon.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "radon.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "radon.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{- define "radon.localImageRepository" -}} 
{{- if eq .Values.environment "local" -}}
default-route-openshift-image-registry.apps-crc.testing/{{ .Release.Namespace }}
{{- else if eq .Values.cloud "aws" -}}
image-registry.openshift-image-registry.svc:5000/{{ .Release.Namespace }}
{{- else -}}
image-registry.openshift-image-registry.svc:5000/{{ .Release.Namespace }}
{{- end -}}
{{- end -}}
