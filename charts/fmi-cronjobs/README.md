# fmi-cronjobs

Reusable Helm chart for deploying multiple Kubernetes CronJobs from a single values file.

## Usage

Install standalone or add as a dependency to another chart:

```yaml
# Chart.yaml
dependencies:
  - name: fmi-cronjobs
    version: "0.2.0"
    repository: "https://fmidev.github.io/helm-charts"
```

When used as a dependency, nest values under `fmi-cronjobs:`:

```yaml
fmi-cronjobs:
  defaults:
    pullSecret: my-pull-secret
    pullPolicy: IfNotPresent
    timeZone: "Europe/Helsinki"
    resourcePreset: minimal
  jobs:
    - name: my-job
      enabled: true
      schedule: "0 4 * * *"
      image:
        repository: quay.io/myorg/my-image
        tag: 1.0.0
```

## Configuration

### `defaults`

Optional shared defaults applied to every job. Per-job settings always take precedence.

| Parameter | Description | Built-in fallback |
|-----------|-------------|-------------------|
| `pullSecret` | Single pull secret name; expands to `imagePullSecrets: [{name: ...}]`. Ignored if the job sets `image.pullSecrets` directly. | — |
| `pullPolicy` | Image pull policy | `IfNotPresent` |
| `timeZone` | IANA timezone for schedules | `Europe/Helsinki` |
| `backoffLimit` | Retries before marking the job failed | `5` |
| `concurrencyPolicy` | `Allow`, `Forbid`, or `Replace` | `Forbid` |
| `restartPolicy` | Pod restart policy | `Never` |
| `successfulJobsHistoryLimit` | Successful job records to keep | `1` |
| `failedJobsHistoryLimit` | Failed job records to keep | `3` |
| `resourcePreset` | Default resource preset (`minimal`, `normal`, `custom`) | — |

### `pvcs`

Optional list of PersistentVolumeClaims to create. Once created, any job can reference them by `claimName` in its `pvcMounts`. 

| Field | Description | Required |
|-------|-------------|----------|
| `name` | PVC name | Yes |
| `accessModes` | List of access modes (e.g. `[ReadWriteMany]`) | Yes |
| `size` | Storage request (e.g. `10Gi`) | Yes |
| `storageClassName` | Storage class to use; omit to use `ocs-storagecluster-cephfs` as default | No |
| `annotations` | Extra annotations on the PVC metadata | No |
| `volumeName` | Bind to a specific PersistentVolume by name | No |

```yaml
pvcs:
  - name: my-cronjob-pvc
    accessModes: [ReadWriteMany]
    size: 10Gi
    storageClassName: ocs-storagecluster-cephfs
```

### `jobs`

List of CronJob definitions. Each entry supports the following fields:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `name` | CronJob name (required) | — |
| `enabled` | Whether to create this CronJob. Jobs are **skipped** when `false` or omitted. | — |
| `schedule` | Cron schedule expression (required) | — |
| `timeZone` | IANA timezone; overrides `defaults.timeZone` | `Europe/Helsinki` |
| `backoffLimit` | Retries before marking the job failed; overrides `defaults.backoffLimit` | `5` |
| `concurrencyPolicy` | `Allow`, `Forbid`, or `Replace`; overrides `defaults.concurrencyPolicy` | `Forbid` |
| `restartPolicy` | Pod restart policy; overrides `defaults.restartPolicy` | `Never` |
| `successfulJobsHistoryLimit` | Successful job records to keep; overrides `defaults.successfulJobsHistoryLimit` | `1` |
| `failedJobsHistoryLimit` | Failed job records to keep; overrides `defaults.failedJobsHistoryLimit` | `3` |
| `annotations` | Extra annotations on the CronJob metadata | `{}` |

### `image`

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository (required) | — |
| `image.tag` | Container image tag (required) | — |
| `image.pullPolicy` | Image pull policy; overrides `defaults.pullPolicy` | `IfNotPresent` |
| `image.pullSecrets` | List of pull secret references; overrides `defaults.pullSecret` | `[]` |

### `command` and `args`

Optional lists that override the container entrypoint and arguments:

```yaml
command: ["python", "/app/main.py"]
args: ["--verbose"]
```

### `env`

List of environment variable definitions. Each item must have a `name` and either a `value` or a `valueFrom` block:

```yaml
env:
  - name: MY_VAR
    value: "hello"
  - name: MY_SECRET
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: my-key
```

### Resources

Set `resourcePreset` to one of the built-in presets, or omit it and provide a `resources` block directly.

| Preset | CPU limit/request | Memory limit/request |
|--------|-------------------|----------------------|
| `minimal` | 100m / 50m | 512Mi / 256Mi |
| `normal` | 500m / 250m | 1Gi / 512Mi |
| `custom` | — (reads from `resources`) | — (reads from `resources`) |

Custom resources example (either use `resourcePreset: custom` or omit `resourcePreset` entirely):

```yaml
resources:
  limits:
    cpu: 2
    memory: 4Gi
  requests:
    cpu: 500m
    memory: 1Gi
```

### `mounts`

List of NFS volume mounts. Volumes and volume mounts both default to read-only unless `readOnly: false` is set explicitly.

| Field | Description | Required |
|-------|-------------|----------|
| `name` | Volume name | Yes |
| `mountPath` | Path inside the container | Yes |
| `server` | NFS server hostname or IP | Yes |
| `serverPath` | Exported path on the NFS server | Yes |
| `readOnly` | Mount as read-only | No (default: `true`) |
| `subPath` | Sub-directory of the NFS export to mount | No |

```yaml
mounts:
  - name: data
    mountPath: /data
    server: nfs.example.com
    serverPath: /exports/data
    readOnly: true
  - name: output
    mountPath: /output
    server: nfs.example.com
    serverPath: /exports/output
    readOnly: false
  - name: subdir-data
    mountPath: /subdata
    server: nfs.example.com
    serverPath: /exports/data
    subPath: subdir
```

### `pvcMounts`

List of PersistentVolumeClaim volume mounts. Reference a PVC by its `claimName`. Volumes default to read-write unless `readOnly: true` is set explicitly.

| Field | Description | Required |
|-------|-------------|----------|
| `name` | Volume name | Yes |
| `claimName` | Name of the PersistentVolumeClaim to mount | Yes |
| `mountPath` | Path inside the container | Yes |
| `readOnly` | Mount as read-only | No (default: `false`) |
| `subPath` | Sub-path within the volume to mount | No |

```yaml
pvcMounts:
  - name: shared-data
    claimName: my-cronjob-pvc
    mountPath: /data
  - name: config-volume
    claimName: config-pvc
    mountPath: /config
    readOnly: true
  - name: partitioned
    claimName: my-cronjob-pvc
    mountPath: /data/subset
    subPath: subset
```

### `tmp`

Mount an `emptyDir` volume as a writable scratch space:

```yaml
tmp:
  enabled: true
  mountPath: /tmp
```

## Full example

When used as a dependency, nest everything under `fmi-cronjobs:`.

```yaml
fmi-cronjobs:
  defaults:
    pullSecret: my-pull-secret   # applied to all jobs unless overridden
    pullPolicy: IfNotPresent
    timeZone: "Europe/Helsinki"
    backoffLimit: 2
    resourcePreset: minimal

  pvcs:
    - name: my-batch-job-pvc
      accessModes: [ReadWriteMany]
      size: 10Gi
      storageClassName: ocs-storagecluster-cephfs

  jobs:
    - name: my-batch-job
      enabled: true
      schedule: "30 6 * * *"
      timeZone: "UTC"            # overrides defaults.timeZone for this job
      image:
        repository: quay.io/myorg/my-image
        tag: 2.3.1
      command: ["/app/run.sh"]
      env:
        - name: OUTPUT_PATH
          value: /output/results
        - name: API_TOKEN
          valueFrom:
            secretKeyRef:
              name: my-app-secrets
              key: API_TOKEN
      mounts:
        - name: input
          mountPath: /input
          server: nfs.example.com
          serverPath: /exports/input
      pvcMounts:
        - name: output
          claimName: my-batch-job-pvc
          mountPath: /output
      tmp:
        enabled: true
        mountPath: /tmp

    - name: my-heavy-job
      enabled: true
      schedule: "0 4 * * *"
      image:
        repository: quay.io/myorg/heavy-image
        tag: 1.0.0
      resources:                 # custom resources; overrides defaults.resourcePreset
        limits:
          cpu: 4
          memory: 8Gi
        requests:
          cpu: 2
          memory: 4Gi
```
