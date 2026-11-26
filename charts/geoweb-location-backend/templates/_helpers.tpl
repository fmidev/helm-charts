{{/*
Quoted container env value that Kubernetes does not expand. "$" is escaped so that
values such as "$(NAME)" and "$$" stay literal, as they did when the variables were
read from a ConfigMap. A null value renders as an empty string.
Usage: value: {{ include "geoweb-location-backend.envValue" $value }}
*/}}
{{- define "geoweb-location-backend.envValue" -}}
{{- if kindIs "invalid" . -}}
""
{{- else -}}
{{- toString . | replace "$" "$$" | quote -}}
{{- end -}}
{{- end }}
