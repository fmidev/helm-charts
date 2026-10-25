# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install smartmet-data-gfs fmi/smartmet-data-gfs --dry-run --debug -n smartmet-data-gfs --create-namespace --values=./values.yaml
```

# Installing the Chart
Execute the following for installing the chart:

```bash
helm install smartmet-data-gfs fmi/smartmet-data-gfs -n smartmet-data-gfs --create-namespace --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n smartmet-data-gfs smartmet-data-gfs
## Delete the Namespace
kubectl delete namespace smartmet-data-gfs
```

# Chart Configuration
The following table lists the configurable parameters of the Smartmetserver chart and their default values.

*The parameters will be keep updating.*

| Parameter | Description | Default |
| - | - | - |
| `smartmetDataGfs.image.repository` | Docker Hub repository | `fmidev/smartmet-data-gfs` |
| `smartmetDataGfs.image.tag` | Tag for the smartmetserver image | `latest` |
| `smartmetDataGfs.image.pullPolicy` | Adds option to modify imagePullPolicy | `IfNotPresent` |
| `smartmetDataGfs.name` | Name of Job deployment | `smartmet-data-gfs` |
| `pvc.name` | Name of the persistent volume claim in use | `pvc` |
| `pvc.accessModes` | Type of access modes persistent volume claim supports  | `ReadWriteOnce` |
| `pvc.storageClass` | Name of storageClassName of volume pvc is trying to bound to | `local` |
| `pvc.storageRequest` | The amount of storage for persistent volume claim  | `1Gi` |
| `cronJob.name` | Name for smartmet-data-gfs cronjob | `cronjob` |
| `cronJob.restartPolicy` | Should the smartmet-data-gfs job restart | `restartPolicy` |
| `cronJob.securityContext.fsGroup` | Default fsGroup as image is run as non-root | `1001` |
| `cronJob.securityContext.schedule` | Schedule for the cronjob | `15 15 * * *` |
| `cronJob.securityContext.timeZone` | TimeZone for the cronjob. Only supported in Kubernetes v1.27. **See:** [**Time Zones Documentation**](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones) | `Etc/UTC` |
| `gfsFileConfigMap.name` | Name for the ConfigMap that is mounted to `/smartmet/cnf/data/gfs.cnf` | `gfs-cnf-file-cm` |
| `gfsFileConfigMap.gfsCnf` | Configurations for the ConfigMap gfs.cnf file` | [See next section](https://github.com/fmidev/helm-charts/edit/feature/smartmet-data-gfs-chart/charts/smartmet-data-gfs/README.md#configure-smartmet-data-gfs-gfscnf) |

# Configure smartmet-data-gfs gfs.cnf
Configurations for the ConfigMap gfs.cnf file can be found from Chart's values.yaml gfsFileConfigMap.gfsCnf section.

**Default values:**
```yaml
  gfsCnf: |-
    AREA="world"
    TOP=90
    BOTTOM=-90
    LEFT=-180
    RIGHT=180
    # Default: ("0 3 126" "132 6 240")
    # ("start step end")"
    INTERVALS=("0 3 126" "132 6 240")
    # Values 0p25 0p50
    RESOLUTION=0p25
    # GRIB_COPY_DEST=
    # DRYRUN=1
```
