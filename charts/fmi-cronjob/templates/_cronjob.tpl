{{/*
Render ONE CronJob.

Call with:
  {{ include "fmi-cronjob.render" (dict "root" $ "job" $job "defaults" $defaults) }}

"root" is the parent chart root context (so we can access Release.Namespace etc)
*/}}
{{- define "fmi-cronjob.render" -}}
{{- $root := required "root is required" .root -}}
{{- $job  := required "job is required"  .job -}}
{{- $d    := default (dict) .defaults -}}

{{- if (default true $job.enabled) -}}
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ required "cronjob.name is required" $job.name }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    app.kubernetes.io/name: {{ $job.name }}
    app.kubernetes.io/instance: {{ $root.Release.Name }}
    app.kubernetes.io/managed-by: {{ $root.Chart.Name }}
    app.kubernetes.io/component: cronjob
  {{- if $job.annotations }}
  annotations:
    {{- toYaml $job.annotations | nindent 4 }}
  {{- end }}
spec:
  schedule: {{ required "cronjob.schedule is required" $job.schedule | quote }}
  timeZone: {{ default (default "Europe/Helsinki" $d.timeZone) $job.timeZone | quote }}
  successfulJobsHistoryLimit: {{ default (default 1 $d.successfulJobsHistoryLimit) $job.successfulJobsHistoryLimit }}
  failedJobsHistoryLimit: {{ default (default 3 $d.failedJobsHistoryLimit) $job.failedJobsHistoryLimit }}
  concurrencyPolicy: {{ default (default "Forbid" $d.concurrencyPolicy) $job.concurrencyPolicy }}
  jobTemplate:
    spec:
      backoffLimit: {{ default (default 5 $d.backoffLimit) $job.backoffLimit }}
      template:
        spec:
          restartPolicy: {{ default (default "Never" $d.restartPolicy) $job.restartPolicy }}

          {{- $pullSecrets := default $d.pullSecret $job.pullSecret -}}
          {{- if or $pullSecrets ($job.image.pullSecrets) }}
          imagePullSecrets:
            {{- if $job.image.pullSecrets }}
            {{- toYaml $job.image.pullSecrets | nindent 12 }}
            {{- else }}
            - name: {{ $pullSecrets }}
            {{- end }}
          {{- end }}

          containers:
            - name: {{ $job.name }}-runner
              image: "{{ required "image.repository required" $job.image.repository }}:{{ required "image.tag required" $job.image.tag }}"
              imagePullPolicy: {{ default (default "IfNotPresent" $d.pullPolicy) (default "IfNotPresent" $job.image.pullPolicy) }}

              {{- if $job.command }}
              command: {{ toJson $job.command }}
              {{- end }}
              {{- if $job.args }}
              args: {{ toJson $job.args }}
              {{- end }}

              {{ include "fmi-cronjob.renderEnv" $job.env | nindent 14 }}
              {{ include "fmi-cronjob.renderResources" (dict "job" $job) | nindent 14 }}
              {{ include "fmi-cronjob.renderVolumeMounts" (dict "mounts" ($job.mounts | default (list)) "tmp" ($job.tmp | default (dict))) | nindent 14 }}

          {{ include "fmi-cronjob.renderVolumes" (dict "mounts" ($job.mounts | default (list)) "tmp" ($job.tmp | default (dict))) | nindent 10 }}
{{- end -}}
{{- end -}}
