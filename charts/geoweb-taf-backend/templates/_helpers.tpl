{{/*
Backend environment variables, shared by the taf and messageconverter containers.
Values in taf.env override the chart defaults. "skip" lists variables the calling
container sets itself.
Usage: include "geoweb-taf-backend.env" (dict "root" $ "skip" (list "NAME"))
*/}}
{{- define "geoweb-taf-backend.env" -}}
{{- $root := .root -}}
{{- $skip := .skip -}}
{{- $env := dict "VERSION" (default $root.Chart.AppVersion $root.Values.versions.taf) -}}
{{- if $root.Values.taf.messageconverter.version -}}
{{- $_ := set $env "AVI_VERSION" $root.Values.taf.messageconverter.version -}}
{{- end -}}
{{- range $key, $value := $root.Values.taf.env -}}
{{- $_ := set $env (upper $key) $value -}}
{{- end -}}
{{- range $key, $value := $env }}
{{- if not (has $key $skip) }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}
