# GeoWeb CloudNativePG Helm Chart

Creates one CloudNativePG `Cluster` for one GeoWeb service. The CloudNativePG operator and CRDs must already exist in the target cluster.

Use a separate Helm release for every service and environment.

## Quick start

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

The database and application must be deployed in the same namespace.

## Cluster settings

### PostgreSQL image and version

`cluster.imageName` is the complete CNPG-compatible PostgreSQL image reference, including its tag or digest, and determines the PostgreSQL version. When empty, CloudNativePG uses the operator's default image.

For production, pin an image published for the installed CNPG operator, preferably by digest:

```yaml
cluster:
  imageName: ghcr.io/cloudnative-pg/postgresql:<major.minor>-standard-trixie@sha256:<digest>
```

Use a tag that exists in the [CloudNativePG PostgreSQL container registry](https://github.com/cloudnative-pg/postgres-containers/pkgs/container/postgresql). Patch changes within one major version are normal rolling upgrades. A change to another major version requires the CloudNativePG major-upgrade procedure.

`cluster.primaryUpdateStrategy` controls whether the primary update is automatic (`unsupervised`, default) or manual (`supervised`). For automatic updates, `cluster.primaryUpdateMethod` selects `restart` (default) or `switchover`.

See [CNPG rolling updates](https://cloudnative-pg.io/docs/current/rolling_update/) for the behavior and restrictions of each method.

### Initial database

With `cluster.bootstrap.mode: initdb`, CNPG initializes an empty cluster with one application database, `cluster.bootstrap.initdb.database` (default: the Cluster `name`), owned by the login role `cluster.bootstrap.initdb.owner`. CNPG exposes that role's credentials in the `<cluster>-app` Secret. These settings apply only when the Cluster is created; changing them later does not rename an existing database or role. Encoding and locale use CNPG's defaults, `UTF8` and `C`.

### Instance placement

Instances use preferred pod anti-affinity across nodes by default, so replicas are likely to survive a node failure without making a database unschedulable in small environments. Set `cluster.affinity.podAntiAffinityType: required` only when every environment has enough topology domains for all instances. Set `cluster.affinity.topologyKey` to use another failure domain, such as a zone label.

### Data lifecycle

Treat `name` as immutable. Changing it creates a new, empty `Cluster` with new Services and Secrets rather than renaming the existing one. The values schema enforces CNPG's naming rules: a DNS-1035 label of at most 50 characters.

By default, `helm.resourcePolicy: keep` prevents Helm uninstall from deleting the `Cluster`. With Argo CD, also enable application-level resource preservation, because Argo CD deletion and pruning do not depend only on the Helm annotation. See [decommission a database](#decommission-a-database) for intentional removal.

## Backups

Backups are disabled by default. Set `backup.method` to one of:

| Method | Provides | Requires | Retention |
| --- | --- | --- | --- |
| `volumeSnapshot` | Cluster-local snapshots of the data volume, without point-in-time recovery | CSI `VolumeSnapshotClass` | Managed outside the chart |
| `barmanCloud` | Off-cluster base backups, continuous WAL archiving, and point-in-time recovery | Barman Cloud plugin, `ObjectStore`, and its credentials Secret | `ObjectStore.spec.retentionPolicy` |
| `barmanObjectStore` | As `barmanCloud`, using CNPG's deprecated built-in integration | Image containing `barman-cli-cloud`, credentials Secret | `backup.retentionPolicy` |

The chart references storage credentials, `ObjectStore` resources, and the plugin but does not create them. Create them before enabling backups.

`backup.schedule` uses six cron fields, including seconds, in the operator's time zone (normally UTC). `backup.backupOwnerReference` and `backup.volumeSnapshot.snapshotOwnerReference` default to `none`, so deleting the schedule or Cluster never deletes backups. Use retention policies to bound storage growth.

### CSI volume snapshots

```yaml
backup:
  method: volumeSnapshot
  schedule: "0 0 0 * * *"
  volumeSnapshot:
    className: ocs-storagecluster-rbdplugin-snapclass
```

Snapshots stay on the same storage platform as the database, so they do not protect against losing that platform.

### Barman Cloud plugin

```yaml
backup:
  method: barmanCloud
  schedule: "0 0 0 * * *"
  barmanCloud:
    objectStoreName: presets-db-backup
```

The CNPG operator must have the [Barman Cloud plugin](https://cloudnative-pg.io/plugin-barman-cloud/docs/installation/) installed.

### Native object store (deprecated)

Use `barmanObjectStore` while the Barman Cloud plugin is not available. It is deprecated since CNPG 1.26 and is removed in CNPG 1.32: [migrate to the plugin](#migrate-native-backups-to-the-plugin) before the operator is upgraded to 1.32.

`backup.barmanObjectStore` is passed directly to `Cluster.spec.backup.barmanObjectStore`; see CNPG's [object-store configuration](https://cloudnative-pg.io/docs/1.30/appendixes/object_stores/). For S3 or an S3-compatible service:

```yaml
backup:
  method: barmanObjectStore
  schedule: "0 0 0 * * *"
  # Recovery window in days, weeks, or months; empty leaves retention unmanaged.
  retentionPolicy: "30d"
  barmanObjectStore:
    destinationPath: s3://geoweb-backups/presets
    # Omit for AWS S3; set for an S3-compatible service.
    endpointURL: https://s3.example.com
    # Optional, for an endpoint using a private CA.
    # endpointCA:
    #   name: presets-db-backup-s3-ca
    #   key: ca.crt
    s3Credentials:
      accessKeyId:
        name: presets-db-backup-s3
        key: ACCESS_KEY_ID
      secretAccessKey:
        name: presets-db-backup-s3
        key: ACCESS_SECRET_KEY
    data:
      compression: gzip
    wal:
      compression: gzip
      maxParallel: 2
```

`backup.barmanObjectStore` and `backup.retentionPolicy` are accepted only with this method. Remove them with `null` in a values overlay, or by deleting them from the values file, when switching methods; `{}` does not clear an inherited map.

Some S3-compatible services reject the default checksums of recent Barman S3 clients with `x-amz-content-sha256 must be UNSIGNED-PAYLOAD, ...`. Apply CNPG's documented workaround through `cluster.env`. Changing it restarts the instances:

```yaml
cluster:
  env:
    - name: AWS_REQUEST_CHECKSUM_CALCULATION
      value: when_required
    - name: AWS_RESPONSE_CHECKSUM_VALIDATION
      value: when_required
```

### Archive layout and server names

Object-store backups are written to `<destinationPath>/<server name>/`. The server name identifies one database's archive within a destination:

| Setting | Default when empty |
| --- | --- |
| `backup.barmanObjectStore.serverName` | Cluster `name` |
| `backup.barmanCloud.serverName` | Cluster `name` |
| `cluster.bootstrap.recovery.barmanObjectStore.serverName` | `cluster.bootstrap.recovery.source` |
| `cluster.bootstrap.recovery.barmanCloud.serverName` | Restored Cluster `name` |

Each archive must have exactly one writer. A restored Cluster must therefore back up to a new server name or destination, never into the archive it was restored from. CNPG refuses to archive WAL into a non-empty archive when a Cluster is created, and WAL then accumulates on the data volume. For object-store recovery, the chart rejects a backup configuration using the same method and archive as the recovery source. It cannot check recovery from `backupName`.

### Verifying backups

`Ready` does not mean that backups work. After enabling or changing object-store backups, check WAL archiving and the first base backup:

```bash
kubectl get cluster presets-db --namespace geoweb \
  -o jsonpath='{.status.conditions[?(@.type=="ContinuousArchiving")]}'
primary=$(kubectl get cluster presets-db --namespace geoweb -o jsonpath='{.status.currentPrimary}')
kubectl exec --namespace geoweb "$primary" --container postgres -- psql -U postgres -c \
  'select last_archived_wal, last_archived_time, failed_count, last_failed_time from pg_stat_archiver'
kubectl get scheduledbackups,backups --namespace geoweb
```

`last_archived_time` should be after the backup configuration change and newer than `last_failed_time`. Before backups are configured, CNPG counts WAL as archived without uploading it. On a quiet database, a new WAL upload can take about five minutes. Failed WAL uploads keep WAL on the data volume until it fills and PostgreSQL stops, so alert on archiving failures and investigate them promptly.

Start an on-demand backup by creating a `Backup` resource:

```bash
kubectl create --namespace geoweb -f - <<'EOF'
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata:
  generateName: presets-db-manual-
spec:
  cluster:
    name: presets-db
  # barmanObjectStore, volumeSnapshot, or plugin
  method: barmanObjectStore
  # Required with method: plugin
  # pluginConfiguration:
  #   name: barman-cloud.cloudnative-pg.io
EOF
```

## Runbooks

### Restore a database

Recovery creates a new Cluster from a backup. The chart requires `database` and `owner` in recovery mode, so the restored application identity is explicit. Use the source application's database and owner role; CNPG creates or reconciles them if they are missing.

#### Before you start

Confirm that these are available:

1. **A backup:** a retained `Backup` resource in the namespace, or a base backup and WAL archive in object storage.
2. **Access to the backup:**
   - Native object store: the storage credentials Secret, any CA Secret, and an image containing `barman-cli-cloud`.
   - Plugin: the installed plugin, plus the `ObjectStore` and its credentials Secret recreated in the namespace.
3. **Application credentials:** the backup contains database roles and password hashes, but not Kubernetes Secrets or readable passwords. Either let CNPG generate a new password (leave `secretName` empty), or create a `kubernetes.io/basic-auth` Secret whose `username` matches `owner` and set `cluster.bootstrap.recovery.secretName`.

#### 1. Choose the Cluster name

- **New name**, such as `presets-db-restored`: use this for test restores or while the original Cluster still exists. Applications must be pointed at `<new name>-app`.
- **Original name**: only after the original Cluster and its PVCs are gone. Applications keep the same Service and Secret names but must be restarted to load the new Secret.

#### 2. Configure the recovery source

Set exactly one source. From a retained `Backup` resource:

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

From a native object-store archive. Set `serverName` to the archive's server name, usually the original Cluster name:

```yaml
name: presets-db-restored

cluster:
  bootstrap:
    mode: recovery
    recovery:
      source: presets-db-source
      database: presets
      owner: geoweb
      barmanObjectStore:
        destinationPath: s3://geoweb-backups/presets
        endpointURL: https://s3.example.com
        serverName: presets-db
        s3Credentials:
          accessKeyId:
            name: presets-db-backup-s3
            key: ACCESS_KEY_ID
          secretAccessKey:
            name: presets-db-backup-s3
            key: ACCESS_SECRET_KEY
        wal:
          maxParallel: 2
```

From an archive through the plugin. Always set `serverName`, because the plugin otherwise uses the restored Cluster's name:

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

To restore to a point in time instead of the latest archived WAL, add a [recovery target](https://cloudnative-pg.io/docs/1.30/recovery/#recovery-targets):

```yaml
cluster:
  bootstrap:
    recovery:
      recoveryTarget:
        targetTime: "2026-10-27 08:00:00+00"
```

#### 3. Configure backups for the restored Cluster

Leave `backup.method: none` to enable backups later, or configure them now with a server name that differs from the source archive's (see [archive layout](#archive-layout-and-server-names)):

```yaml
backup:
  method: barmanObjectStore
  barmanObjectStore:
    # Same settings as the source, with a new archive name.
    serverName: presets-db-r1
```

#### 4. Deploy and verify

1. Install or sync the release, then wait until the Cluster is ready:

   ```bash
   kubectl wait --namespace geoweb --for=condition=Ready cluster/presets-db-restored --timeout=30m
   ```

2. Check the application data, for example with `kubectl exec -it --namespace geoweb presets-db-restored-1 --container postgres -- psql -U postgres -d presets`.
3. Point the application at `<cluster>-app`, or restart it when the Cluster kept its original name.
4. If backups are configured, [verify them](#verifying-backups) and start a base backup immediately.

Keep the recovery settings in the release values. They take effect only when the Cluster is created.

### Change the backup storage target

1. Update `backup.barmanObjectStore`, or the `ObjectStore` referenced by `backup.barmanCloud.objectStoreName`, to the new destination, endpoint, and credentials.
2. Apply the change and [verify backups](#verifying-backups). Start a base backup immediately: the new location cannot be used for recovery until one completes.
3. Keep the previous location until its retention window has passed. The chart does not copy existing backups or WAL.

### Migrate native backups to the plugin

Follow the upstream [migration guide](https://cloudnative-pg.io/plugin-barman-cloud/docs/migration/). Migrate the existing Cluster in place, keeping its name, destination, and server name. Existing backups and WAL stay in place and remain usable.

| Native setting | Plugin setting |
| --- | --- |
| `backup.barmanObjectStore`, except `serverName` | `ObjectStore.spec.configuration` |
| `backup.retentionPolicy` | `ObjectStore.spec.retentionPolicy` |
| `backup.barmanObjectStore.serverName` | `backup.barmanCloud.serverName` |
| S3 client variables in `cluster.env` | `ObjectStore.spec.instanceSidecarConfiguration.env` |

The plugin requires `ObjectStore.spec.configuration.serverName` to be empty; set the server name through the chart instead. When native backups use the default server name, `backup.barmanCloud.serverName` can stay empty.

1. Have the platform team [install and verify the plugin](https://cloudnative-pg.io/plugin-barman-cloud/docs/installation/).
2. Create the `ObjectStore` in the database namespace, reusing the existing credentials Secret. For the native example above:

   ```yaml
   apiVersion: barmancloud.cnpg.io/v1
   kind: ObjectStore
   metadata:
     name: presets-db-backup
     namespace: geoweb
   spec:
     retentionPolicy: "30d"
     configuration:
       destinationPath: s3://geoweb-backups/presets
       endpointURL: https://s3.example.com
       s3Credentials:
         accessKeyId:
           name: presets-db-backup-s3
           key: ACCESS_KEY_ID
         secretAccessKey:
           name: presets-db-backup-s3
           key: ACCESS_SECRET_KEY
       data:
         compression: gzip
       wal:
         compression: gzip
         maxParallel: 2
   ```

   Copy the actual configuration, including any CA reference, encryption, tags, or extra arguments.
3. Set `backup.suspend: true`, apply it, and wait for running base backups to finish. WAL archiving continues.
4. Switch the method in a single change, keeping the schedule suspended:

   ```yaml
   backup:
     method: barmanCloud
     suspend: true
     retentionPolicy: ""
     barmanObjectStore: null
     barmanCloud:
       objectStoreName: presets-db-backup
       serverName: presets-db
   ```

   This replaces the native configuration with the plugin in one Cluster update, as upstream requires, and switches the schedule to the `plugin` method. With Argo CD, create the plugin and `ObjectStore` before syncing.
5. After the rolling update, [verify](#verifying-backups) that the plugin archives new WAL. Set `backup.suspend: false`, confirm a successful base backup, and test restores from backups taken before and after the switch.
6. Update dashboards and alerts to the [plugin metrics](https://cloudnative-pg.io/plugin-barman-cloud/docs/observability/) (`barman_cloud_cloudnative_pg_io` instead of `cnpg_collector`), and on-demand backup scripts to the plugin method.

A restored release with native recovery settings can switch them to the plugin in the same way, keeping the archive's server name:

```yaml
cluster:
  bootstrap:
    recovery:
      barmanObjectStore: null
      barmanCloud:
        objectStoreName: presets-db-backup
        serverName: presets-db
```

### Decommission a database

1. Stop the database's clients and verify a usable backup and restore procedure.
2. Set `helm.resourcePolicy: ""` and upgrade the release.
3. Uninstall the release. With Argo CD, follow the application's deletion procedure instead.

Deleting the `Cluster` can also delete its PVCs, depending on operator and storage configuration. Backups with owner reference `none` and object-store archives remain until removed by retention or manually.

## Configuration

| Parameter | Description | Default |
| --- | --- | --- |
| `name` | CNPG Cluster name | `geoweb-db` |
| `helm.resourcePolicy` | Value of the `helm.sh/resource-policy` annotation; empty omits it | `keep` |
| `cluster.instances` | Number of PostgreSQL instances | `1` |
| `cluster.affinity.podAntiAffinityType` | Instance anti-affinity mode _(preferred\|required)_ | `preferred` |
| `cluster.affinity.topologyKey` | Node label defining the placement failure domain | `kubernetes.io/hostname` |
| `cluster.imageName` | Full CNPG-compatible PostgreSQL image reference; empty uses the operator default | `""` |
| `cluster.env` | Environment variables for the PostgreSQL containers (`Cluster.spec.env`) | `[]` |
| `cluster.primaryUpdateStrategy` | Automatic or manual primary updates _(unsupervised\|supervised)_ | `unsupervised` |
| `cluster.primaryUpdateMethod` | Primary update method for automatic rolling updates _(restart\|switchover)_ | `restart` |
| `cluster.bootstrap.mode` | Bootstrap mode _(initdb\|recovery)_ | `initdb` |
| `cluster.bootstrap.initdb.database` | Initial application database; empty uses `name` | `""` |
| `cluster.bootstrap.initdb.owner` | Login role that owns the initial application database | `geoweb` |
| `cluster.bootstrap.recovery.source` | External cluster name for object-store recovery | `""` |
| `cluster.bootstrap.recovery.backupName` | Retained Backup resource used for recovery | `""` |
| `cluster.bootstrap.recovery.database` | Post-recovery application database (required in recovery mode) | `""` |
| `cluster.bootstrap.recovery.owner` | Post-recovery application owner (required in recovery mode) | `geoweb` |
| `cluster.bootstrap.recovery.secretName` | Optional replacement basic-auth Secret | `""` |
| `cluster.bootstrap.recovery.recoveryTarget` | Optional point-in-time recovery target | `{}` |
| `cluster.bootstrap.recovery.barmanCloud.objectStoreName` | Plugin `ObjectStore` containing the source archive | `""` |
| `cluster.bootstrap.recovery.barmanCloud.serverName` | Source archive server name; empty uses the restored Cluster name | `""` |
| `cluster.bootstrap.recovery.barmanObjectStore` | Native object-store configuration of the source archive | `{}` |
| `cluster.storage.size` | Data volume size | `1Gi` |
| `cluster.storage.storageClass` | Optional storage class | `""` |
| `cluster.resources` | PostgreSQL Pod requests and limits | See `values.yaml` |
| `backup.method` | Backup method _(none\|volumeSnapshot\|barmanCloud\|barmanObjectStore)_ | `none` |
| `backup.target` | Preferred backup source instance | `prefer-standby` |
| `backup.schedule` | Six-field backup cron schedule | `0 0 0 * * *` |
| `backup.immediate` | Start a backup when the schedule is created | `true` |
| `backup.suspend` | Suspend scheduled backup creation | `false` |
| `backup.backupOwnerReference` | Owner reference for generated Backup resources | `none` |
| `backup.retentionPolicy` | Native object-store recovery window; empty leaves retention unmanaged | `""` |
| `backup.volumeSnapshot.className` | VolumeSnapshotClass for PGDATA | `""` |
| `backup.volumeSnapshot.online` | Take online volume snapshots | `true` |
| `backup.volumeSnapshot.snapshotOwnerReference` | Owner reference for generated VolumeSnapshots | `none` |
| `backup.barmanCloud.objectStoreName` | Plugin `ObjectStore` used for backups and WAL archiving | `""` |
| `backup.barmanCloud.serverName` | Archive server name; empty uses `name` | `""` |
| `backup.barmanObjectStore` | Native object-store configuration for backups and WAL archiving | `{}` |
