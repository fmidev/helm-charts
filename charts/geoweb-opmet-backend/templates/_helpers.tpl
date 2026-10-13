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
  value: {{ include "geoweb-opmet-backend.envValue" $value }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Quoted container env value that Kubernetes does not expand. "$" is escaped so that
values such as "$(NAME)" and "$$" stay literal, as they did when the variables were
read from a ConfigMap. A null value renders as an empty string.
Usage: value: {{ include "geoweb-opmet-backend.envValue" $value }}
*/}}
{{- define "geoweb-opmet-backend.envValue" -}}
{{- if kindIs "invalid" . -}}
""
{{- else -}}
{{- toString . | replace "$" "$$" | quote -}}
{{- end -}}
{{- end }}
