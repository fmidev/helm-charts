{{/*
Resource name for this release's Redis objects. Suffixed with "-redis" (rather
than the bare release name) so this chart is safe to use both as its own
release AND as a subchart dependency of another chart that might otherwise
claim the bare release name for its own resources.
*/}}
{{- define "fmi-redis.fullname" -}}
{{- printf "%s-redis" .Release.Name -}}
{{- end -}}
