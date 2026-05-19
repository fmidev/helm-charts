{{/* render full env: block (no output if list is empty) */}}
{{- define "fmi-cronjobs.renderEnv" -}}
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
{{- define "fmi-cronjobs.renderResources" -}}
{{- $job := .job -}}
{{- $defaults := (.defaults | default (dict)) -}}
{{- $preset := $job.resourcePreset | default $defaults.resourcePreset -}}
{{- if $preset }}
{{- if eq $preset "minimal" }}
resources:
  limits:
    cpu: 100m
    memory: 512Mi
  requests:
    cpu: 50m
    memory: 256Mi
{{- else if eq $preset "normal" }}
resources:
  limits:
    cpu: 500m
    memory: 1Gi
  requests:
    cpu: 250m
    memory: 512Mi
{{- else if eq $preset "custom" }}
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
Render all volumes: NFS mounts + PVC mounts + optional tmp emptyDir
Usage from a manifest:
  {{ include "fmi-cronjobs.renderVolumes" (dict "mounts" ($job.mounts | default (list)) "pvcMounts" ($job.pvcMounts | default (list)) "tmp" ($job.tmp | default (dict))) | nindent 10 }}
*/}}
{{- define "fmi-cronjobs.renderVolumes" -}}
{{- $mounts := (default (list) .mounts) -}}
{{- $pvcMounts := (default (list) .pvcMounts) -}}
{{- $tmp := (default (dict) .tmp) -}}
{{- $renderTmp := and $tmp (hasKey $tmp "enabled") ($tmp.enabled) -}}

{{- if or (gt (len $mounts) 0) (gt (len $pvcMounts) 0) $renderTmp }}
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
{{- range $mount := $pvcMounts }}
  - name: {{ required "pvcMount.name is required" $mount.name }}
    persistentVolumeClaim:
      claimName: {{ required "pvcMount.claimName is required" $mount.claimName }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Render all volumeMounts: NFS mounts + PVC mounts + optional tmp emptyDir
*/}}
{{- define "fmi-cronjobs.renderVolumeMounts" -}}
{{- $mounts := (default (list) .mounts) -}}
{{- $pvcMounts := (default (list) .pvcMounts) -}}
{{- $tmp := (default (dict) .tmp) -}}

{{- if or (gt (len $mounts) 0) (gt (len $pvcMounts) 0) (and $tmp $tmp.enabled) }}
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
{{- range $mount := $pvcMounts }}
  - name: {{ required "pvcMount.name is required" $mount.name }}
    mountPath: {{ required "pvcMount.mountPath is required" $mount.mountPath }}
    {{- if $mount.subPath }}
    subPath: {{ $mount.subPath }}
    {{- end }}
    {{- if hasKey $mount "readOnly" }}
    readOnly: {{ $mount.readOnly }}
    {{- else }}
    readOnly: false
    {{- end }}
{{- end }}
{{- if and $tmp $tmp.enabled }}
  - name: tmp
    mountPath: {{ required "tmp.mountPath is required when tmp.enabled=true" $tmp.mountPath }}
{{- end }}
{{- end }}
{{- end }}
