{{- define "snwc_bc.localImageRepository" -}} 
image-registry.openshift-image-registry.svc:5000/{{ .Release.Namespace }}/{{ .Release.Name }}
{{- end }}

{{- define "snwc_bc.imageTag" -}} 
{{- if eq .Values.environment "dev" -}} 
latest
{{- else -}} 
{{ .Values.prodType }}
{{- end }}
{{- end }}
