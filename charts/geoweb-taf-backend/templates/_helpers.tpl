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
  value: {{ include "geoweb-taf-backend.envValue" $value }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Quoted container env value that Kubernetes does not expand. "$" is escaped so that
values such as "$(NAME)" and "$$" stay literal, as they did when the variables were
read from a ConfigMap. A null value renders as an empty string.
Usage: value: {{ include "geoweb-taf-backend.envValue" $value }}
*/}}
{{- define "geoweb-taf-backend.envValue" -}}
{{- if kindIs "invalid" . -}}
""
{{- else -}}
{{- toString . | replace "$" "$$" | quote -}}
{{- end -}}
{{- end }}
