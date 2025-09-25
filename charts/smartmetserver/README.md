# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm upgrade --install smartmetserver fmi/smartmetserver --dry-run --debug --namespace smartmetserver --create-namespace --values=./values.yaml
```

# Installing the Chart
Execute the following for installing the chart:

```bash
helm upgrade --install smartmetserver fmi/smartmetserver --namespace smartmetserver --create-namespace --values=./values.yaml
```

## Volume Configuration Examples

The chart supports three different volume types for smartmet data storage with both static and dynamic provisioning:

### 1. NFS Volume

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set volume.type=nfs \
  --set volume.nfs.server=10.12.12.66 \
  --set volume.nfs.path=/smartmet/data
```

**Values YAML:**
```yaml
volume:
  type: nfs
  nfs:
    server: 10.12.12.66
    path: /smartmet/data
```

### 2. CephFS Volume - Static Provisioning (existing PV)

Uses existing CephFS volume. The capacity values are metadata only and should match your actual volume size.

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set volume.type=cephfs
```

**Values YAML:**
```yaml
volume:
  type: cephfs
```

**If you need to specify the actual volume size:**
```yaml
volume:
  type: cephfs
  cephfs:
    pv:
      capacity: 5Ti  # Match your actual CephFS volume size
    pvc:
      capacity: 5Ti  # Must match PV capacity
```

### 3. CephFS Volume - Dynamic Provisioning

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver --namespace smartmetserver --create-namespace \
  --set volume.type=cephfs \
  --set volume.provisioning=dynamic \
  --set volume.cephfs.pvc.storageClassName=csi-cephfs \
  --set volume.cephfs.pvc.capacity=100Gi
```

**Values YAML:**
```yaml
volume:
  type: cephfs
  provisioning: dynamic
  cephfs:
    pvc:
      storageClassName: csi-cephfs
      capacity: 100Gi
```

### 4. HostPath Volume - Static Provisioning (existing PV)

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set volume.type=hostPath \
  --set volume.hostPath.path=/opt/smartmet/data \
  --set volume.hostPath.pvc.storage=10Gi
```

**Values YAML:**
```yaml
volume:
  type: hostPath
  hostPath:
    path: /opt/smartmet/data
    pvc:
      storage: 10Gi
```

### 5. HostPath Volume - Dynamic Provisioning

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver --namespace smartmetserver --create-namespace \
  --set volume.type=hostPath \
  --set volume.provisioning=dynamic \
  --set volume.hostPath.pvc.storageClassName=hostpath-provisioner \
  --set volume.hostPath.pvc.storage=10Gi
```

**Values YAML:**
```yaml
volume:
  type: hostPath
  provisioning: dynamic
  hostPath:
    pvc:
      storageClassName: hostpath-provisioner
      storage: 10Gi
```

## Ingress Configuration

### 1. Basic HTTP Ingress

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver --namespace smartmetserver --create-namespace \
  --set ingress.enabled=true \
  --set ingress.hosts[0]=smartmetserver.example.com
```

**Values YAML:**
```yaml
ingress:
  enabled: true
  hosts:
    - smartmetserver.example.com
```

### 2. HTTPS Ingress with TLS and Annotations

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver --namespace smartmetserver --create-namespace \
  --set ingress.enabled=true \
  --set ingress.hosts[0]=smartmetserver.example.com \
  --set ingress.tls.enabled=true
```

**Values YAML:**
```yaml
ingress:
  enabled: true
  hosts:
    - smartmetserver.example.com
  tls:
    enabled: true
```

### 3. Multi-Host Ingress with Custom Paths

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver --namespace smartmetserver --create-namespace \
  --set ingress.enabled=true \
  --set ingress.hosts[0]=api.example.com \
  --set ingress.hosts[1]=smartmet.example.com \
  --set ingress.paths[0].path=/api/v1 \
  --set ingress.paths[0].pathType=Prefix
```

**Values YAML:**
```yaml
ingress:
  enabled: true
  hosts:
    - api.example.com
    - smartmet.example.com
  paths:
    - path: /api/v1
      pathType: Prefix
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace smartmetserver smartmetserver
## Delete the Namespace
kubectl delete namespace smartmetserver
```

# Chart Configuration
The following table lists the configurable parameters of the Smartmetserver chart and their default values.

*The parameters will be keep updating.*

| Parameter | Description | Default |
| - | - | - |
| `image.repository` | Docker Hub repository | `fmidev/smartmetserver` |
| `image.tag` | Tag for the smartmetserver image | `latest` |
| `image.pullPolicy` | Adds option to modify imagePullPolicy | `IfNotPresent` |
| `smartmetserver.name` | Name of server | `smartmetserver` |
| `smartmetserver.containerPort` | Port used for container | `8080` |
| `smartmetserver.svcPort` | Port used for service | `80` |
| `smartmetserver.replicas` | Amount of replicas deployed | `2` |
| `smartmetserver.livenessProbe.periodSeconds` | Liveness probe's delay between probing attempts | `30` |
| `smartmetserver.readinessProbe.failureThreshold` | How many times the probe attempts before restarting the container | `5` |
| `smartmetserver.readinessProbe.periodSeconds` | Readiness probe's delay between probing attempts | `60` |
| `smartmetserver.startupProbe.failureThreshold` | How many times the probe attempts before restarting the container | `5` |
| `smartmetserver.startupProbe.periodSeconds` | Startup probe's delay between probing attempts | `60` |
| `service.type` | Type of Kubernetes service | `ClusterIP` |
| `service.portName` | Name of the service port | `http` |
| `service.targetPort` | Target port for the service | `8080` |
| `service.annotations` | Custom annotations for the service | `{}` |
| `ingress.enabled` | Whether ingress is enabled | `false` |
| `ingress.ingressClassName` | Configure ingressClassName if needed | `""` |
| `ingress.hosts` | List of hosts for ingress (required when enabled) | `[]` |
| `ingress.annotations` | Custom annotations for the ingress | `{}` |
| `ingress.paths` | List of path configurations for the ingress | `[{path: "/", pathType: "Prefix"}]` |
| `ingress.tls.enabled` | Whether TLS is enabled for ingress | `false` |
| `ingress.tls.secretName` | Secret name for TLS certificate | `smartmetserver-ingress-tls` |
| `ingress.tls.issuerRef.kind` | Certificate issuer kind | `ClusterIssuer` |
| `ingress.tls.issuerRef.name` | Certificate issuer name | `letsencrypt` |
| `volume.type` | Type of volume for smartmet data: `cephfs`, `nfs`, or `hostPath` | `hostPath` |
| `volume.readOnly` | Whether the volume should be mounted as read-only | `true` |
| `volume.provisioning` | Provisioning mode: `static` (use existing PV) or `dynamic` (create new PV) | `static` |
| `volume.hostPath.path` | Path for hostPath volume | `/tmp/smartmet-data` |
| `volume.hostPath.pv.name` | Name of hostPath PersistentVolume | `smartmet-data-pv` |
| `volume.hostPath.pv.storageClassName` | Storage class for hostPath PV | `hostpath-smartmet` |
| `volume.hostPath.pvc.name` | Name of hostPath PersistentVolumeClaim | `smartmet-data-pvc` |
| `volume.hostPath.pvc.accessModes` | Access modes for hostPath PVC | `ReadWriteOnce` |
| `volume.hostPath.pvc.storage` | Storage size for hostPath PVC | `1Gi` |
| `volume.hostPath.pvc.storageClassName` | Storage class for dynamic provisioning | `hostpath-smartmet` |
| `volume.nfs.server` | NFS server address | `10.12.12.66` |
| `volume.nfs.path` | NFS export path | `/smartmet/data` |
| `volume.cephfs.pv.name` | Name of CephFS PersistentVolume | `smartmet-data-pv` |
| `volume.cephfs.pv.capacity` | Storage capacity for CephFS PV | `1Ti` |
| `volume.cephfs.pv.fsName` | CephFS filesystem name | `smartmet_data` |
| `volume.cephfs.pv.rootPath` | Root path within CephFS | `/` |
| `volume.cephfs.pv.clusterID` | Ceph cluster ID | `smartmet-ceph` |
| `volume.cephfs.pv.secretName` | Secret containing Ceph credentials | `cephfs-secret` |
| `volume.cephfs.pv.secretNamespace` | Namespace of the Ceph secret | `ceph-csi` |
| `volume.cephfs.pvc.name` | Name of CephFS PersistentVolumeClaim | `smartmet-data-pvc` |
| `volume.cephfs.pvc.capacity` | Storage capacity for CephFS PVC | `1Ti` |
| `volume.cephfs.pvc.storageClassName` | Storage class for dynamic provisioning | `csi-cephfs` |
| `hpa.minReplicas` | Minimum amount of replicas for horizontal pod autoscaler | `2` |
| `hpa.maxReplicas` | Maximum amount of replicas for horizontal pod autoscaler | `6` |
| `hpa.targetCPUUtilizationPercentage` | Target CPU percentage for horizontal pod autoscaler | `60` |
| `hpa.targetMemoryUtilizationPercentage` | Target memory percentage for HPA (optional) | `null` |
| `hpa.behavior` | Advanced scaling behavior configuration (optional) | `null` |
| `hpa.behavior.scaleDown` | Scale down behavior policies and stabilization | `null` |
| `hpa.behavior.scaleUp` | Scale up behavior policies and stabilization | `null` |
| `smartmetConf.server.port` | SmartMet server port | `8080` |
| `smartmetConf.server.defaultlogging` | Enable default logging | `false` |
| `smartmetConf.server.logrequests` | Log HTTP requests | `true` |
| `smartmetConf.server.verbose` | Verbose output during startup | `true` |
| `smartmetConf.server.debug` | Enable debug information | `true` |
| `smartmetConf.server.lazylinking` | Enable lazy linking | `true` |
| `smartmetConf.server.compress` | Compress HTTP responses | `true` |
| `smartmetConf.server.compresslimit` | Do not compress responses smaller than this | `1000` |
| `smartmetConf.pools.slowpool.maxthreads` | Maximum threads for slow pool | `24` |
| `smartmetConf.pools.slowpool.maxrequeuesize` | Maximum requeue size for slow pool | `100` |
| `smartmetConf.pools.fastpool.maxthreads` | Maximum threads for fast pool | `24` |
| `smartmetConf.pools.fastpool.maxrequeuesize` | Maximum requeue size for fast pool | `100` |
| `smartmetConf.engines` | List of engines to enable | `[sputnik, contour, geonames, gis, querydata, grid]` |
| `smartmetConf.plugins` | List of plugins to enable | `[autocomplete, download, edr, timeseries, wms]` |


## SmartMet Configuration

The SmartMet server configuration is now generated dynamically from structured YAML values instead of a static configuration file. This makes it much easier to customize which engines and plugins to enable.

### Engine and Plugin Configuration

You can easily customize which engines and plugins are enabled by modifying the lists in values.yaml:

```yaml
smartmetConf:
  # Available engines: sputnik, contour, geonames, gis, querydata, grid
  engines:
    - sputnik
    - querydata
    - gis
  
  # Available plugins: autocomplete, download, edr, timeseries, wms, admin
  plugins:
    - timeseries
    - download
```

### Complete Configuration Example

```yaml
smartmetConf:
  server:
    port: 8080
    verbose: true
    compress: true
  pools:
    slowpool:
      maxthreads: 16
    fastpool: 
      maxthreads: 8
  engines:
    - querydata
    - gis
  plugins:
    - timeseries
    - edr
```

### Generated smartmet.conf

The above configuration will generate a smartmet.conf like this:
```
// SmartMet Server Configuration
port = 8080;
defaultlogging = false;
verbose = true;
compress = true;
compresslimit = 1000;

slowpool:
{
    maxthreads = 16;
    maxrequeuesize = 100;
};

fastpool:
{
    maxthreads = 8;
    maxrequeuesize = 100;
};

engines:
{
    querydata:
    {
        configfile = "engines/querydata.conf";
    };
    gis:
    {
        configfile = "engines/gis.conf";
    };
};

plugins:
{
    timeseries:
    {
        configfile = "plugins/timeseries.conf";
    };
    edr:
    {
        configfile = "plugins/edr.conf";
    };
};
```
