# smartmet-verify-database

Deploys the SmartMet Verify PostgreSQL/PostGIS database as a
[CloudNativePG](https://cloudnative-pg.io/) (CNPG) `Cluster`, loads the
verification schema at bootstrap, and manages the role passwords.

The schema from [`fmidev/fmi-verification-common-sql`](https://github.com/fmidev/fmi-verification-common-sql)
is **vendored into this chart** under `files/sql/`, so a plain `helm install`
produces a working, correctly-owned, correctly-credentialed `verifapi` database
with no prerequisite `kubectl create configmap/secret` steps.

Pair it with the [`smartmet-verify`](../smartmet-verify/) chart, which deploys
the GUI and runner applications against this database.

## Prerequisites

The CNPG **operator is not installed by this chart**. Install it cluster-wide
first:

```shell
kubectl apply --server-side -f \
  https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v1.29.0/cnpg-1.29.0.yaml
```

v1.29.0 is the version this chart is tested against; any reasonably current CNPG
release should work. `--server-side` is required — the `Cluster` CRD exceeds 1 MB.

You also need a StorageClass capable of satisfying `cluster.storage.size`
(100 Gi by default).

## Quick start

```shell
helm install verification-db fmi/smartmet-verify-database \
  --namespace smartmet-verify --create-namespace \
  --set cluster.storage.storageClass=local-path
```

Then watch it come up — first bootstrap takes a while, as it loads a ~686 KB
dump with 186 tables:

```shell
kubectl -n smartmet-verify get cluster verification-db -w
```

## What gets created

| Object | Name | Purpose |
|---------|------|---------|
| `Cluster` | `verification-db` | The CNPG cluster |
| `ConfigMap` | `verification-db-sql-pre-init` | `0000-pre-init.sql` — roles |
| `ConfigMap` | `verification-db-sql-production` | `0001-production-schema.sql` — the schema |
| `ConfigMap` | `verification-db-sql-post-ownership` | `0002-post-ownership.sql` — ownership transfer |
| `ConfigMap` | `verification-db-sql-reference-data` | `0004-reference-data.sql` — rows the applications require |
| `ConfigMap` | `verification-db-sql-extra` | operator-supplied `schema.extraSql` |
| `Secret` × 9 | `verification-db-<role>` | `kubernetes.io/basic-auth` role passwords |
| `Service` | `verification-db` | alias for the primary (via CNPG `managed.services`) |
| `Service` | `verification-db-external` | only when `externalAccess.enabled` |

CNPG additionally creates `verification-db-rw`, `-ro` and `-r` services itself.

Applications connect with `jdbc:postgresql://verification-db:5432/verifapi`.

## The schema

Vendored files, applied in this order:

1. `0000-pre-init.sql` — as superuser on the `postgres` database, via
   `postInitSQLRefs`. Creates the group roles (`verif_data_rw`, `verif_meta_rw`,
   `verif_ro`) and the nine login roles.
2. `0001-production-schema.sql` — as superuser on `verifapi`. `pg_dump` output;
   186 tables, 29 functions, and `CREATE EXTENSION postgis, postgis_raster,
   pgstattuple`.
3. `0002-post-ownership.sql` — transfers ownership of the database and schema
   `public` to `verifadmin`.
4. `0004-reference-data.sql` — reference rows the applications require in every
   deployment: `target_types`, the 97 `estimators` and the 291 `parameters`, the
   latter two with their localized descriptions in English and Finnish. These are
   **not** customer metadata: the GUI compiles both the names and, in places, the
   ids in, so a database without them is broken rather than empty. Every query
   form switches on the selected target type, and an empty `target_types` makes
   the first view a user opens throw
   `Cannot invoke "String.hashCode()" because ... is null`; an absent
   `BIAS_ON_MAP` estimator likewise made the bias-on-map view an Internal Server
   Error page before fmi-verification-gui 3.25.1. Estimator ids therefore match
   FMI's exactly — `ColumnDiagramChartBuilder` hardcodes id 93 for
   `BIAS_ON_MAP` while `EstimatorComboBox` resolves the same row by name.

   Parameter *names* carry the same weight: `ModelData.getValue()` rescales
   `TotalCloudCover` from percent to eighths and clamps `Ceiling` and
   `Visibility` by name, `ObservationManager` shifts the observation window for
   `Precipitation24h`, and the chart builders branch on `Direction`,
   `CloudBase` and `TotalCloudCover`. A deployment that spells them differently
   gets silently wrong values, not missing ones. Parameter ids are FMI's too, so
   the views that hardcode them stay usable.

   `localization_entries` is shared, so the seeded tables each own a
   100000-wide block of entry ids: estimators at offset 0 (1..110), parameters
   at offset 100000 (100001..100865). A further table takes offset 200000.

   Idempotent, so it is safe against a database that already has the rows.
5. `verification-db-sql-extra` — anything from `schema.extraSql`. Last, so an
   operator can override the reference data above.

`0003-legacy-test-data.sql` is deliberately **not** vendored: it consists of
`\COPY` meta-commands against ~176 MB of CSV fixtures, which CNPG cannot execute.
That is why the vendored numbering skips from `0002` to `0004`.

> **The schema is applied by `initdb` ONLY, on first bootstrap.**
> Editing `files/sql/` and running `helm upgrade` does **not** migrate an
> existing database. CNPG also treats `spec.bootstrap` as immutable once the
> cluster is initialised, which is why the ConfigMap names are stable and the
> `-sql-extra` ConfigMap is always referenced even when empty. Post-bootstrap
> migrations are an out-of-band operation.

### The `owner: app` detail

`cluster.owner` is `app`, a throw-away role CNPG creates itself, rather than
`verifadmin`. That is deliberate: it leaves `0000-pre-init.sql` free to
`CREATE ROLE verifadmin` without colliding with a role the operator already made.
`0002-post-ownership.sql` then hands ownership over. Do not "fix" this.

### Updating the vendored schema

`scripts/sync-schema.sh` re-fetches the SQL and rewrites the pin in `Chart.yaml`
(`fmi.fi/verification-sql-ref`), which is the single source of truth for which
upstream revision is baked in:

```shell
./scripts/sync-schema.sh          # re-fetch the pinned revision
./scripts/sync-schema.sh main     # move the pin to upstream HEAD
```

It requires an authenticated `gh` with access to the (private) upstream repo,
and rejects any file containing CR bytes, trailing whitespace, invalid UTF-8, or
psql meta-commands — each of which would either break Helm's YAML block-scalar
rendering or fail to execute under CNPG. Bump the chart `version` afterwards.

## Roles and passwords

`0000-pre-init.sql` creates every login role with the literal password
`'password'`. CNPG replaces those via `managed.roles` — **but only for roles
listed in `roles`**. All nine are listed by default.

> Removing a role from `roles` leaves a live account with a publicly known
> password. Set `enabled: false` only if you also patch the vendored SQL.

The three **group** roles are intentionally unmanaged. CNPG revokes any
membership it did not declare itself, and the group-to-group grants
(`GRANT verif_ro TO verif_data_rw`) exist only in the SQL — managing the groups
would require restating those and risks CNPG revoking them on reconcile. For the
same reason, each login role repeats its membership in `inRoles`.

| Role | `inRoles` | Used by |
|------|-----------|---------|
| `verifadmin` | — | schema owner |
| `verifapi_restore` | — | restores |
| `verifely` | `verif_ro` | |
| `verifimport` | `verif_data_rw` | data import |
| `verifrun` | `verif_data_rw` | smartmet-verify **runner** |
| `verifmeta` | `verif_meta_rw` | metadata updates |
| `verifwww` | `verif_ro` | smartmet-verify **GUI** |
| `verifwww_len` | `verif_ro` | |
| `replicator` | — | legacy; CNPG uses its own `streaming_replica` |

### Password handling

By default (`auth.generatePasswords: true`) the chart generates a random
32-character password per role and **reuses the existing one on upgrade**, so
`helm upgrade` never rotates credentials.

Read a generated password:

```shell
kubectl -n smartmet-verify get secret verification-db-verifwww \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

Note the Secret **object** names replace underscores with hyphens
(`verifapi_restore` → `verification-db-verifapi-restore`), since underscores are
illegal in Kubernetes names. The `username` key inside keeps the real role name,
which CNPG requires.

Per role you may instead set:

- `existingSecret` — name of a `kubernetes.io/basic-auth` Secret you manage. It
  **must** carry a `username` key exactly equal to the role name, or CNPG will
  refuse to reconcile that role. Nothing is rendered by the chart.
- `password` — a literal, for values files under SOPS/sealed-secrets.

With `auth.generatePasswords: false`, every enabled role must supply one of the
two or the render fails with an explicit error.

Generated passwords are stored in cleartext inside the Helm release Secret, so
anyone with `get secrets` in the namespace can read all nine. Use `existingSecret`
with External Secrets Operator where that matters.

### GitOps / Argo CD

**Do not use password generation under Argo CD.** Reuse depends on Helm's
`lookup`, which returns nothing under `helm template`, `helm lint`, client-side
`--dry-run`, and Argo CD's renderer. Argo would render a *new* password on every
reconcile, apply it, and CNPG would issue `ALTER ROLE` — breaking live
connection pools each time.

For GitOps:

```yaml
auth:
  generatePasswords: false
roles:
  - name: verifwww
    enabled: true
    inRoles: [verif_ro]
    existingSecret: verification-db-verifwww   # from ESO / sealed-secrets
```

When previewing an upgrade with plain Helm, use `--dry-run=server`, which does
execute `lookup`.

## External access

Off by default. The window between `initdb` and the first `managed.roles`
reconcile is the only time the `'password'` credentials are live, and it should
not be reachable from outside the cluster.

```yaml
externalAccess:
  enabled: true
  type: NodePort      # or LoadBalancer
  nodePort: 30432
cluster:
  postgresql:
    pg_hba:
      - hostssl verifapi verifwww 10.0.0.0/8 scram-sha-256
```

## Configuration

### General

| Parameter | Description | Default |
|-----------|-------------|---------|
| `clusterName` | CNPG Cluster name; stem of its services and role Secrets | `verification-db` |
| `nameOverride` / `fullnameOverride` | Standard Helm name overrides | `""` |
| `commonLabels` / `commonAnnotations` | Added to every object | `{}` |
| `serviceAlias.enabled` | Publish the primary under a bare hostname | `true` |
| `serviceAlias.name` | Alias name; defaults to `clusterName` | `""` |

### Cluster

| Parameter | Description | Default |
|-----------|-------------|---------|
| `cluster.instances` | Number of PostgreSQL instances | `1` |
| `cluster.imageName` | Must be a PostGIS image — the schema needs `postgis`, `postgis_raster`, `pgstattuple` | `ghcr.io/cloudnative-pg/postgis:16-3.4` |
| `cluster.imagePullPolicy` | Image pull policy | `""` |
| `cluster.imagePullSecrets` | Pull secrets | `[]` |
| `cluster.database` | Application database name | `verifapi` |
| `cluster.owner` | initdb owner; see "The `owner: app` detail" | `app` |
| `cluster.storage.size` | Data volume size | `100Gi` |
| `cluster.storage.storageClass` | Empty omits the field (cluster default) | `""` |
| `cluster.walStorage.enabled` | Separate WAL volume | `false` |
| `cluster.walStorage.size` / `.storageClass` | WAL volume settings | `20Gi` / `""` |
| `cluster.resources` | Requests and limits | 2Gi/500m → 4Gi/2 |
| `cluster.env` | Extra environment | `TZ=UTC` |
| `cluster.postgresql.parameters` | `postgresql.conf` settings | UTC timezones |
| `cluster.postgresql.pg_hba` | Extra `pg_hba.conf` lines | `[]` |
| `cluster.primaryUpdateStrategy` | `unsupervised` or `supervised` | `unsupervised` |
| `cluster.nodeSelector` / `.tolerations` / `.affinity` / `.priorityClassName` | Scheduling | `{}` / `[]` / `{}` / `""` |
| `cluster.extraSpec` | Merged into `Cluster.spec` last — backups, monitoring, etc. Do **not** put `bootstrap` here | `{}` |

### Schema

| Parameter | Description | Default |
|-----------|-------------|---------|
| `schema.enabled` | Render and wire up the vendored SQL | `true` |
| `schema.existingConfigMaps.postInit` | Refs used when `schema.enabled` is false | `[]` |
| `schema.existingConfigMaps.postInitApplication` | As above, on the app database | `[]` |
| `schema.extraSql` | Extra SQL, concatenated in sorted key order into one ref | `{}` |
| `schema.extraPostInitApplicationRefs.configMapRefs` / `.secretRefs` | Additional refs appended last | `[]` |

### Roles and auth

| Parameter | Description | Default |
|-----------|-------------|---------|
| `auth.generatePasswords` | Generate and reuse role passwords | `true` |
| `roles[].name` | PostgreSQL role name | see values |
| `roles[].enabled` | Manage this role | `true` |
| `roles[].inRoles` | Memberships, restated from the SQL | see table above |
| `roles[].existingSecret` | Use a Secret you manage | `""` |
| `roles[].password` | Literal password | `""` |
| `roles[].replication` | Grant `REPLICATION` | only `replicator` |

### External access

| Parameter | Description | Default |
|-----------|-------------|---------|
| `externalAccess.enabled` | Expose the primary outside the cluster | `false` |
| `externalAccess.type` | `NodePort` or `LoadBalancer` | `NodePort` |
| `externalAccess.nodePort` | Fixed port; empty auto-assigns | `""` |
| `externalAccess.annotations` | Service annotations | `{}` |
| `externalAccess.loadBalancerIP` / `.loadBalancerSourceRanges` | LoadBalancer settings | `""` / `[]` |

## Notes for operators

- `helm uninstall` deletes the `Cluster`, and CNPG's owner references mean the
  **PVCs and all data go with it**, along with the password Secrets. Take a dump
  first if you care about the contents.
- Backups (`barmanObjectStore`, `ScheduledBackup`), connection pooling
  (`Pooler`) and `monitoring.enablePodMonitor` are not templated in this release.
  They are reachable through `cluster.extraSpec`.
