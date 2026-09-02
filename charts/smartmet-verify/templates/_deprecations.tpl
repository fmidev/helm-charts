{{/*
Guards for values that have been REMOVED from this chart.

Helm silently ignores unknown keys in a values file, and this chart ships no
values.schema.json, so a consumer that still sets a removed value would get a
silent no-op rather than an error. These guards turn that into a hard failure
with an actionable message.

`smartmet-verify.checkDeprecations` is invoked from templates/NOTES.txt, which
Helm renders on every `helm template`, `helm install` and `helm upgrade` --
including when this chart is used as a subchart. Do not remove that call.
*/}}

{{- define "smartmet-verify.checkDeprecations" -}}
{{- if hasKey .Values "database" -}}
{{- fail (include "smartmet-verify.databaseRemovedMessage" .) -}}
{{- end -}}
{{- end -}}

{{- define "smartmet-verify.databaseRemovedMessage" -}}
The `database.*` values were REMOVED from the smartmet-verify chart in 0.8.0,
but this release still sets `database`.

This chart no longer renders a CloudNativePG `Cluster`. The database is now
owned by a separate chart, `fmi/smartmet-verify-database`, installed as its
own Helm release:

    helm install verification-db fmi/smartmet-verify-database

DANGER -- DATA LOSS IF YOU UPGRADE AN EXISTING RELEASE THAT OWNS THE CLUSTER.
Dropping the `database` values alone is not enough. If this release currently
owns the `Cluster` this chart used to render, that object drops out of the
release manifest on upgrade and Helm DELETES it. CloudNativePG owner-references
the PVC to the `Cluster`, so the volume and every row in the database go with
it, and there is no undo.

Before upgrading to 0.8.0, either:

  a) Hand the cluster over -- back it up, then detach it from this release so
     Helm will not prune it:

       kubectl annotate -n {{ .Release.Namespace }} \
         cluster/<cluster-name> helm.sh/resource-policy=keep

     then upgrade this release without `database`, and adopt the object into a
     `smartmet-verify-database` release (label/annotate it with the new
     release's `app.kubernetes.io/managed-by`, `meta.helm.sh/release-name` and
     `meta.helm.sh/release-namespace`).

  b) Rebuild -- capture a dump you have verified you can restore, uninstall,
     then install `smartmet-verify-database` and restore into it.

Once the database is owned elsewhere, remove the `database` key from your
values to proceed. Pinning smartmet-verify 0.7.0 keeps the old behaviour.

See https://github.com/fmidev/smartmet-rke2/issues/100 for the background.
{{- end -}}
