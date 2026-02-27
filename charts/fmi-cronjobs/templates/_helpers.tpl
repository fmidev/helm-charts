{{/* render full env: block (no output if list is empty) */}}
{{- define "app.renderEnv" -}}
{{- with . -}}
env:
{{- range . }}
  - name: {{ .name | quote }}
    {{- if hasKey . "value" }}
    value: {{ .value | quote }}
    {{- else if hasKey . "valueFrom" }}
    valueFrom:
      {{- toYaml .valueFrom | nindent 6 }}
    {{- else }}
    {{- fail (printf "env item %q must have either 'value' or 'valueFrom'" .name) }}
    {{- end }}
{{- end }}
{{- end -}}
{{- end -}}

{{/* render resource requests and limits for a container */}}
{{- define "app.renderResources" -}}
{{- $job := .job -}}
{{- if $job.resourcePreset }}
{{- if eq $job.resourcePreset "minimal" }}
resources:
  limits:
    cpu: 100m
    memory: 512Mi
  requests:
    cpu: 50m
    memory: 256Mi
{{- else if eq $job.resourcePreset "normal" }}
resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi
{{- else if eq $job.resourcePreset "custom" }}
resources:
  {{- toYaml $job.resources | nindent 2 }}
  {{- end -}}
{{- else }}
{{- if $job.resources }}
resources:
  {{- toYaml $job.resources | nindent 2 }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Render all volumes: NFS mounts + optional tmp emptyDir
Usage from a manifest:
  {{ include "app.renderVolumes" (dict "mounts" (.Values.mount | default (list)) "tmp" (.Values.tmp | default (dict))) | nindent 12 }}
*/}}
{{- define "app.renderVolumes" -}}
{{- $mounts := (default (list) .mounts) -}}
{{- $tmp := (default (dict) .tmp) -}}
{{- $renderTmp := and $tmp (hasKey $tmp "enabled") ($tmp.enabled) -}}

{{- if or (gt (len $mounts) 0) $renderTmp }}
volumes:
{{- if $renderTmp }}
  - name: tmp
    emptyDir: {}
{{- end }}
{{- range $mount := $mounts }}
  - name: {{ required "mount.name is required" $mount.name }}
    nfs:
      server: {{ required "mount.server is required for NFS" $mount.server }}
      path: {{ required "mount.serverPath is required for NFS" $mount.serverPath }}
      {{- if hasKey $mount "readOnly" }}
      readOnly: {{ $mount.readOnly }}
      {{- else }}
      readOnly: true
      {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Render all volumeMounts: NFS mounts + optional tmp emptyDir
*/}}
{{- define "app.renderVolumeMounts" -}}
{{- $mounts := (default (list) .mounts) -}}
{{- $tmp := (default (dict) .tmp) -}}

{{- if or (gt (len $mounts) 0) (and $tmp $tmp.enabled) }}
volumeMounts:
{{- range $mount := $mounts }}
  - name: {{ required "mount.name is required" $mount.name }}
    mountPath: {{ required "mount.mountPath is required" $mount.mountPath }}
    {{- if $mount.subPath }}
    subPath: {{ $mount.subPath }}
    {{- end }}
    {{- if hasKey $mount "readOnly" }}
    readOnly: {{ $mount.readOnly }}
    {{- else }}
    readOnly: true
    {{- end }}
{{- end }}

{{- if and $tmp $tmp.enabled }}
  - name: tmp
    mountPath: {{ required "tmp.mountPath is required when tmp.enabled=true" $tmp.mountPath }}
{{- end }}
{{- end }}
{{- end }}

