{{/* Return the explicitly configured CloudNativePG Cluster name. */}}
{{- define "geoweb-cnpg.name" -}}
{{- required "name is required" .Values.name }}
{{- end }}

{{/* Create chart version as used by the chart label. */}}
{{- define "geoweb-cnpg.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Common labels. */}}
{{- define "geoweb-cnpg.labels" -}}
helm.sh/chart: {{ include "geoweb-cnpg.chart" . }}
{{ include "geoweb-cnpg.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Selector labels. */}}
{{- define "geoweb-cnpg.selectorLabels" -}}
app.kubernetes.io/name: {{ include "geoweb-cnpg.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}