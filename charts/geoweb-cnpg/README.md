# GeoWeb CloudNativePG Helm Chart

Creates one CloudNativePG `Cluster` for one GeoWeb service. The CloudNativePG operator and CRDs must already exist in the target cluster.

Use a separate Helm release for every service and environment. Database lifecycle must remain separate from the consuming application release.

## Presets example

Install the database first:

```yaml
name: presets-db

cluster:
  instances: 1
  bootstrap:
    initdb:
      database: presets
      owner: geoweb
  storage:
    size: 1Gi
```

```bash
helm upgrade --install presets-db ./charts/geoweb-cnpg \
  --namespace geoweb \
  --values presets-db-values.yaml
kubectl wait --namespace geoweb --for=condition=Ready cluster/presets-db --timeout=5m
```

CloudNativePG creates `Secret/presets-db-app`. Its `uri` key contains the complete PostgreSQL connection string. Configure the presets chart to consume it without copying credentials:

```yaml
presets:
  db:
    mode: external
    external:
      source: existingSecret
      secretName: presets-db-app
      secretKey: uri
```

The database and application must be deployed in the same namespace for this example. Kubernetes Pods cannot reference a Secret in another namespace, and the `uri` value uses a namespace-local service name. If an environment deliberately copies the connection Secret into another namespace, consume CNPG's `fqdn-uri` key instead so the database service name remains resolvable. Treat any copied Secret as a separate credential asset with its own secure synchronization and rotation process.

## PostgreSQL image and version

`cluster.imageName` is the complete CNPG-compatible PostgreSQL container image reference, including its tag or digest. The image determines the PostgreSQL major and minor version; it is not merely an image repository override. When empty, CloudNativePG uses the operator's default operand image.

For production, select an image published for the installed CNPG operator and pin it explicitly, preferably by digest. For example:

```yaml
cluster:
  imageName: ghcr.io/cloudnative-pg/postgresql:<major.minor>-standard-trixie@sha256:<digest>
```

Use a tag that actually exists in the [CloudNativePG PostgreSQL container registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql). Patch-level changes within one PostgreSQL major are normal rolling upgrades. Treat a change to another PostgreSQL major as a planned major upgrade and follow the CloudNativePG major-upgrade procedure; changing this value alone is not a general-purpose migration plan.

`cluster.primaryUpdateStrategy` controls the final primary switchover during a rolling update. `unsupervised` lets CNPG perform it automatically after updating the replicas. `supervised` pauses at that point until an operator promotes an updated replica, which is useful when production changes require a controlled maintenance window.

## Initial database

With `cluster.bootstrap.mode: initdb`, CNPG initializes a new PostgreSQL cluster and creates one database for the consuming application. `cluster.bootstrap.initdb.database` is that database's name; when empty, this chart uses the Cluster `name`. `cluster.bootstrap.initdb.owner` is the login role that owns it and whose credentials CNPG exposes through the generated `<cluster>-app` Secret. The owner defaults to the organization-wide `geoweb` application role.

Override the database when its established application name differs from the Cluster name, as in the presets example. These settings only initialize a new cluster; changing them later does not rename an existing database or role.

The chart leaves encoding and locale settings to CNPG, whose `initdb` defaults are `UTF8` and `C`. These provide deterministic byte-order sorting and do not introduce environment-dependent locale behavior. Supporting a service that requires language-specific collation should be an explicit chart change accompanied by migration planning because collation choices cannot be changed safely in place.

## Data lifecycle

Installing this chart with `bootstrap.initdb` creates an empty database. It does not migrate an existing sidecar or Zalando database.

Treat `name` as immutable after installation. Changing it does not rename the existing Cluster or database: Helm or Argo CD submits a new CNPG `Cluster` with new services and Secrets. With the default resource policy, the old Cluster is retained, so changing `name` requires an explicit migration and decommission plan.

`name` must satisfy CNPG's Cluster-name validation: a DNS-1035 label of at most 50 lowercase alphanumeric or `-` characters, beginning with a letter and ending with an alphanumeric character. The values schema rejects invalid names before Helm submits any resources.

By default, `helm.resourcePolicy: keep` adds `helm.sh/resource-policy: keep` to prevent Helm uninstall from deleting the `Cluster`. This can leave the Cluster orphaned from the release. Before a controlled decommission, verify an external backup and restore procedure, set `helm.resourcePolicy` to an empty string, upgrade the release, and only then uninstall it. Removing the CNPG `Cluster` can also remove its PVCs, depending on operator and storage configuration.

For Argo CD, also enable application-level resource preservation. Do not rely on the Helm annotation as the only deletion safeguard because Argo CD deletion and pruning behavior depends on its configuration.

## Instance placement

CNPG instances use preferred pod anti-affinity across Kubernetes nodes by default. This gives replicas a better chance of surviving a node failure without making a database unschedulable in small or temporarily constrained environments.

Set `cluster.affinity.podAntiAffinityType: required` only when the target environments always provide enough schedulable topology domains for every instance. Change `cluster.affinity.topologyKey` when the platform exposes a more appropriate failure-domain label, such as a zone label.

## Backups

Backups are disabled by default because the chart cannot infer an environment's snapshot class, object store, credentials, retention, RPO, or RTO.

### CSI volume snapshots

Use this for cluster-local recovery when the storage platform supports `VolumeSnapshot`:

```yaml
backup:
  method: volumeSnapshot
  schedule: "0 0 0 * * *"
  immediate: true
  volumeSnapshot:
    className: ocs-storagecluster-rbdplugin-snapclass
```

The schedule uses six fields, including seconds. The example runs daily at midnight. Volume snapshots share the storage cluster's failure domain and are not sufficient as the only production backup.

### Barman Cloud object-store backups

Use the Barman Cloud plugin for off-cluster backups, WAL archiving, and point-in-time recovery. The operator administrators must install the plugin, and an `ObjectStore` resource plus its storage-access Secret must already exist:

```yaml
backup:
  method: barmanCloud
  schedule: "0 0 0 * * 0"
  barmanCloud:
    objectStoreName: presets-db-backup
```

The chart translates `barmanCloud` to the CNPG-I Barman Cloud plugin configuration. It references the plugin and `ObjectStore` but does not install them or own their credentials. Configure retention on the Barman `ObjectStore`; the CNPG in-tree retention field is deprecated.

Backup and snapshot owner references default to `none`. This prevents deletion of the schedule or Cluster from cascading to recovery artifacts. Define independent object-store or snapshot retention and cleanup policies to avoid unbounded storage growth.

### Credentials during recovery

A physical PostgreSQL backup contains database roles and password hashes, so the restored database initially has the source users. It does not contain CNPG's Kubernetes Secrets or readable passwords. Object-store access credentials are also external to the backup.

Treat these as separate disaster-recovery assets:

1. The database base backups and WAL archive, or retained volume snapshots.
2. Credentials and configuration needed to read that backup storage.
3. The application credential Secret, or an approved process for replacing it after recovery.

If the original `<cluster>-app` Secret is gone, bootstrap the recovered Cluster with the application database and owner and either provide a new `kubernetes.io/basic-auth` Secret or let CNPG generate a new one. After recovery reaches primary, CNPG updates the owner's password and creates the new Cluster's `<cluster>-app` connection Secret. Roll out the application to consume the new Secret. The old plaintext password cannot be extracted from the PostgreSQL password hash.

Recover from a retained `Backup` object in the same namespace:

```yaml
name: presets-db-restored

cluster:
  bootstrap:
    mode: recovery
    recovery:
      backupName: presets-db-20260820000000
      database: presets
      owner: geoweb
```

Recover when only the object-store backup and WAL archive remain:

```yaml
name: presets-db-restored

cluster:
  bootstrap:
    mode: recovery
    recovery:
      source: presets-db-source
      database: presets
      owner: geoweb
      barmanCloud:
        objectStoreName: presets-db-backup
        serverName: presets-db
```

This chart requires `database` and `owner` in recovery mode so the post-recovery application identity is explicit and is not accidentally derived from the new Cluster name. They normally match the source application's database and role. If either does not exist in the recovered data, CNPG creates or reconciles it after recovery. `owner` defaults to `geoweb` to match this chart's initialization convention, but override it when the restored application uses another owner.

Leave `secretName` empty to generate replacement application credentials. To select the password explicitly, first create a `kubernetes.io/basic-auth` Secret containing `username` and `password`, then set `cluster.bootstrap.recovery.secretName`. The Secret username must match `owner` for CNPG to apply its password after recovery.

Object-store recovery requires the plugin, `ObjectStore`, and storage-access Secret to be recreated before the Cluster. Use a different writable object store or `serverName` for backups made by the restored Cluster so it cannot overwrite the source archive.

Back up externally managed Secrets with the platform's encrypted Kubernetes backup system or recreate them from a secrets manager. Never put plaintext database or object-store credentials in chart values or Git.

Role reconciliation, pooling, and NetworkPolicies are still deferred until their environment-specific requirements are defined. Do not promote this first iteration to production without a tested restore procedure and those controls.

## Configuration

| Parameter | Description | Default |
| --- | --- | --- |
| `name` | CNPG Cluster name (required) | `""` |
| `helm.resourcePolicy` | Value of the `helm.sh/resource-policy` annotation; empty omits it | `keep` |
| `cluster.instances` | Number of PostgreSQL instances | `1` |
| `cluster.affinity.podAntiAffinityType` | Instance anti-affinity mode _(preferred\|required)_ | `preferred` |
| `cluster.affinity.topologyKey` | Node label defining the placement failure domain | `kubernetes.io/hostname` |
| `cluster.imageName` | Full CNPG-compatible PostgreSQL image reference; empty uses the operator default | `""` |
| `cluster.primaryUpdateStrategy` | Primary switchover policy during rolling updates _(unsupervised\|supervised)_ | `unsupervised` |
| `cluster.bootstrap.mode` | Bootstrap mode _(initdb\|recovery)_ | `initdb` |
| `cluster.bootstrap.initdb.database` | Initial application database; empty uses `name` | `""` |
| `cluster.bootstrap.initdb.owner` | Login role that owns the initial application database | `geoweb` |
| `cluster.bootstrap.recovery.source` | External cluster source name for Barman Cloud recovery | `""` |
| `cluster.bootstrap.recovery.backupName` | Retained Backup resource used for recovery | `""` |
| `cluster.bootstrap.recovery.database` | Post-recovery application database (required in recovery mode) | `""` |
| `cluster.bootstrap.recovery.owner` | Post-recovery application owner (required in recovery mode) | `geoweb` |
| `cluster.bootstrap.recovery.secretName` | Optional replacement basic-auth Secret | `""` |
| `cluster.bootstrap.recovery.recoveryTarget` | Optional PITR target fields | `{}` |
| `cluster.bootstrap.recovery.barmanCloud.objectStoreName` | Barman ObjectStore containing the source backup and WAL archive | `""` |
| `cluster.bootstrap.recovery.barmanCloud.serverName` | Source cluster name in the archive; empty uses `source` | `""` |
| `cluster.storage.size` | Data volume size | `1Gi` |
| `cluster.storage.storageClass` | Optional storage class | `""` |
| `cluster.resources` | PostgreSQL Pod requests and limits | See `values.yaml` |
| `backup.method` | Backup method; `none` disables backups _(none\|volumeSnapshot\|barmanCloud)_ | `none` |
| `backup.target` | Preferred backup source instance | `prefer-standby` |
| `backup.schedule` | Six-field backup cron schedule | `0 0 0 * * *` |
| `backup.immediate` | Start a backup when the schedule is created | `true` |
| `backup.suspend` | Suspend scheduled backup creation | `false` |
| `backup.backupOwnerReference` | Owner reference for generated Backup resources | `none` |
| `backup.volumeSnapshot.className` | VolumeSnapshotClass for PGDATA | `""` |
| `backup.volumeSnapshot.online` | Take online volume snapshots | `true` |
| `backup.volumeSnapshot.snapshotOwnerReference` | Owner reference for generated VolumeSnapshots | `none` |
| `backup.barmanCloud.objectStoreName` | Barman ObjectStore used for backups and WAL archiving | `""` |
