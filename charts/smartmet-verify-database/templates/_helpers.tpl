{{/*
Chart name, overridable.
*/}}
{{- define "smartmet-verify-database.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified release name. Used for chart-owned objects that are not tied to
the CNPG cluster name.
*/}}
{{- define "smartmet-verify-database.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "smartmet-verify-database.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
The CNPG Cluster name.

Deliberately NOT derived from .Release.Name: SmartMet Verify application configs
hard-code `verification-db` as the JDBC host, and CNPG appends its own suffixes
(-rw, -ro, -r, -1, ...) which must stay within the object name length limit.
*/}}
{{- define "smartmet-verify-database.clusterName" -}}
{{- required "clusterName is required" .Values.clusterName | trunc 53 | trimSuffix "-" -}}
{{- end -}}

{{- define "smartmet-verify-database.labels" -}}
helm.sh/chart: {{ include "smartmet-verify-database.chart" . }}
{{ include "smartmet-verify-database.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: smartmet-verify
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "smartmet-verify-database.selectorLabels" -}}
app.kubernetes.io/name: {{ include "smartmet-verify-database.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Labels for a named component. Call as:
  {{- include "smartmet-verify-database.componentLabels" (list . "database") }}
*/}}
{{- define "smartmet-verify-database.componentLabels" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
{{ include "smartmet-verify-database.labels" $root }}
app.kubernetes.io/component: {{ $component }}
{{- end -}}

{{/*
Name of the Secret holding a role's password.

Role names may contain underscores (verifapi_restore, verifwww_len), which are
illegal in Kubernetes object names (RFC 1123). Sanitise the OBJECT name only --
the `username` key inside the Secret must keep the unsanitised role name,
because CNPG matches it against the PostgreSQL role.
*/}}
{{- define "smartmet-verify-database.roleSecretName" -}}
{{- $root := index . 0 -}}
{{- $role := index . 1 -}}
{{- $stem := include "smartmet-verify-database.clusterName" $root -}}
{{- printf "%s-%s" $stem ($role.name | replace "_" "-" | lower) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Resolve the plaintext password for a managed role.

Precedence (the caller has already established role.existingSecret is empty):
  1. role.password  -- operator-supplied literal, never generated
  2. existing in-cluster Secret -- reused so `helm upgrade` does not rotate
  3. randAlphaNum 32 -- first install only

WARNING: step 2 uses `lookup`, which returns an empty dict under `helm template`,
`helm lint`, client-side `--dry-run` and Argo CD. See the GitOps section of the
README before enabling generation in a GitOps setup.

randAlphaNum (not randAscii) keeps the password safe to embed in the
jdbc:postgresql:// URLs the application charts build.
*/}}
{{- define "smartmet-verify-database.rolePassword" -}}
{{- $root := index . 0 -}}
{{- $role := index . 1 -}}
{{- if $role.password -}}
{{- $role.password -}}
{{- else -}}
{{- $name := include "smartmet-verify-database.roleSecretName" (list $root $role) -}}
{{- $existing := lookup "v1" "Secret" $root.Release.Namespace $name -}}
{{- $data := dict -}}
{{- if $existing -}}
{{- $data = default (dict) $existing.data -}}
{{- end -}}
{{- if hasKey $data "password" -}}
{{- b64dec (get $data "password") -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Secret name CNPG should read a role's password from: either the operator-supplied
existingSecret, or the one this chart renders.
*/}}
{{- define "smartmet-verify-database.rolePasswordSecret" -}}
{{- $root := index . 0 -}}
{{- $role := index . 1 -}}
{{- if $role.existingSecret -}}
{{- $role.existingSecret -}}
{{- else -}}
{{- include "smartmet-verify-database.roleSecretName" (list $root $role) -}}
{{- end -}}
{{- end -}}

{{/*
Upstream revision of the vendored SQL, from Chart.yaml annotations.
*/}}
{{- define "smartmet-verify-database.sqlRef" -}}
{{- $ann := default (dict) .Chart.Annotations -}}
{{- default "unknown" (index $ann "fmi.fi/verification-sql-ref") -}}
{{- end -}}
