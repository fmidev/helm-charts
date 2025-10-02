{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "smartmetserver.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "smartmetserver.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "smartmetserver.fullname" -}}
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
Common labels
*/}}
{{- define "smartmetserver.labels" -}}
helm.sh/chart: {{ include "smartmetserver.chart" . }}
{{ include "smartmetserver.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ include "smartmetserver.name" . }}
{{- end }}

{{/*
Common labels with component
*/}}
{{- define "smartmetserver.labels.component" -}}
{{ include "smartmetserver.labels" . }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "smartmetserver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "smartmetserver.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "smartmetserver.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "smartmetserver.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
