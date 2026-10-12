{{/*
Backend environment variables, shared by the opmet and messageconverter containers.
Values in opmet.env override the chart defaults. "skip" lists variables the calling
container sets itself.
Usage: include "geoweb-opmet-backend.env" (dict "root" $ "skip" (list "NAME"))
*/}}
{{- define "geoweb-opmet-backend.env" -}}
{{- $root := .root -}}
{{- $skip := .skip -}}
{{- $env := dict "VERSION" (default $root.Chart.AppVersion $root.Values.versions.opmet) -}}
{{- range $key, $value := $root.Values.opmet.env -}}
{{- $_ := set $env (upper $key) $value -}}
{{- end -}}
{{- range $key, $value := $env }}
{{- if not (has $key $skip) }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}
