{{- define "smartmet-verify.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "smartmet-verify.fullname" -}}
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

{{- define "smartmet-verify.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "smartmet-verify.labels" -}}
helm.sh/chart: {{ include "smartmet-verify.chart" . }}
app.kubernetes.io/name: {{ include "smartmet-verify.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . | trimSuffix "\n" }}
{{- end }}
{{- end -}}

{{- define "smartmet-verify.selectorLabels" -}}
app.kubernetes.io/name: {{ include "smartmet-verify.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "smartmet-verify.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "smartmet-verify.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "smartmet-verify.componentFullname" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
{{- printf "%s-%s" (include "smartmet-verify.fullname" $root) $component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "smartmet-verify.componentLabels" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
{{ include "smartmet-verify.labels" $root }}
app.kubernetes.io/component: {{ $component }}
{{- end -}}

{{- define "smartmet-verify.componentSelectorLabels" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
{{ include "smartmet-verify.selectorLabels" $root }}
app.kubernetes.io/component: {{ $component }}
{{- end -}}

{{/*
Render a Kubernetes probe from a probe spec.

Input: a map like `.Values.<component>.probes.liveness`.
The probe action is picked in this priority order:

  1. exec       — map with a command list
  2. tcpSocket  — map with a port
  3. httpGet    — map with path/port/scheme/httpHeaders
  4. path       — legacy shortcut, expanded to httpGet on the named "http" port

Timing fields are forwarded when set.
*/}}
{{- define "smartmet-verify.probe" -}}
{{- if .exec -}}
exec:
  {{- toYaml .exec | nindent 2 }}
{{- else if .tcpSocket -}}
tcpSocket:
  {{- toYaml .tcpSocket | nindent 2 }}
{{- else if .httpGet -}}
httpGet:
  {{- toYaml .httpGet | nindent 2 }}
{{- else if .path -}}
httpGet:
  path: {{ .path }}
  port: http
{{- end }}
{{- with .initialDelaySeconds }}
initialDelaySeconds: {{ . }}
{{- end }}
{{- with .periodSeconds }}
periodSeconds: {{ . }}
{{- end }}
{{- with .timeoutSeconds }}
timeoutSeconds: {{ . }}
{{- end }}
{{- with .failureThreshold }}
failureThreshold: {{ . }}
{{- end }}
{{- with .successThreshold }}
successThreshold: {{ . }}
{{- end }}
{{- end -}}

{{- define "smartmet-verify.image" -}}
{{- $root := index . 0 -}}
{{- $image := index . 1 -}}
{{- $registry := $root.Values.global.imageRegistry | default "" -}}
{{- $repo := $image.repository -}}
{{- $repoWithoutRegistry := $repo -}}
{{- $repoParts := splitList "/" $repo -}}
{{- if gt (len $repoParts) 1 -}}
{{- $firstPart := first $repoParts -}}
{{- if or (contains "." $firstPart) (contains ":" $firstPart) (eq $firstPart "localhost") -}}
{{- $repoWithoutRegistry = join "/" (rest $repoParts) -}}
{{- end -}}
{{- end -}}
{{- $tag := coalesce $image.tag "latest" -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repoWithoutRegistry $tag -}}
{{- else -}}
{{- printf "%s:%s" $repo $tag -}}
{{- end -}}
{{- end -}}
