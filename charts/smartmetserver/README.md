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

## High Availability Configuration

### PodDisruptionBudget for Service Continuity

SmartMetServer includes PodDisruptionBudget (PDB) support to ensure high availability during cluster maintenance, node upgrades, and voluntary disruptions.

**Enable PodDisruptionBudget:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set podDisruptionBudget.enabled=true \
  --set podDisruptionBudget.minAvailable=1
```

**Values YAML:**
```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1  # Keep at least 1 pod running during disruptions
```

**Alternative configurations:**
```yaml
# Option 1: Specify minimum available pods
podDisruptionBudget:
  enabled: true
  minAvailable: 2  # Always keep 2 pods running

# Option 2: Specify maximum unavailable pods  
podDisruptionBudget:
  enabled: true
  maxUnavailable: 1  # Allow max 1 pod to be down

# Option 3: Use percentages (for larger deployments)
podDisruptionBudget:
  enabled: true
  minAvailable: "50%"  # Keep at least 50% of pods running
```

### Horizontal Pod Autoscaler (HPA)

The chart includes HPA support for automatic scaling based on CPU and memory usage:

```yaml
hpa:
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 60
  # Optional memory targeting
  targetMemoryUtilizationPercentage: 70
```

**Combined HA Strategy:**
```yaml
# Recommended high availability configuration
smartmetserver:
  replicas: 2  # Base replica count

hpa:
  minReplicas: 2  # HPA minimum (matches base replicas)
  maxReplicas: 6  # Scale up to 6 pods under load
  targetCPUUtilizationPercentage: 60

podDisruptionBudget:
  enabled: true
  minAvailable: 1  # Always keep at least 1 pod during maintenance
```

This configuration ensures:
- ✅ **Base availability**: 2 pods running normally
- ✅ **Auto-scaling**: Up to 6 pods during high load
- ✅ **Maintenance protection**: At least 1 pod during cluster operations
- ✅ **Zero downtime**: Service remains available during updates

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
| `podDisruptionBudget.enabled` | Whether PodDisruptionBudget is enabled for high availability | `true` |
| `podDisruptionBudget.minAvailable` | Minimum number/percentage of pods that must remain available | `1` |
| `podDisruptionBudget.maxUnavailable` | Maximum number/percentage of pods that can be unavailable (alternative to minAvailable) | `null` |
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
| `smartmetConf.querydata` | Custom querydata.conf content (optional) | `null` |
| `smartmetserver.resources` | Resource limits and requests for the container | See below |
| `smartmetserver.resources.limits.memory` | Memory limit for the container | `4Gi` |
| `smartmetserver.resources.limits.cpu` | CPU limit for the container | `2` |
| `smartmetserver.resources.requests.memory` | Memory request for the container | `2Gi` |
| `smartmetserver.resources.requests.cpu` | CPU request for the container | `0.5` |
| `securityContext.pod.runAsNonRoot` | Enforce non-root execution at pod level | `true` |
| `securityContext.pod.runAsUser` | User ID for pod security context | `65534` |
| `securityContext.pod.runAsGroup` | Group ID for pod security context | `65534` |
| `securityContext.pod.fsGroup` | File system group for volume permissions | `65534` |
| `securityContext.pod.seLinuxOptions.level` | SELinux security level | `s0` |
| `securityContext.container.readOnlyRootFilesystem` | Make container root filesystem read-only | `true` |
| `securityContext.container.allowPrivilegeEscalation` | Allow privilege escalation | `false` |
| `securityContext.container.capabilities.drop` | Linux capabilities to drop | `["ALL"]` |
| `serviceAccount.create` | Create a dedicated ServiceAccount | `true` |
| `serviceAccount.automountServiceAccountToken` | Automatically mount ServiceAccount token | `false` |
| `serviceAccount.annotations` | Annotations for the ServiceAccount | `{}` |
| `serviceAccount.name` | Name of the ServiceAccount (uses generated name if empty) | `""` |


## Security Configuration

The SmartMetServer chart implements comprehensive security hardening following Kubernetes Pod Security Standards and security best practices. All security settings are configurable via values.yaml with secure defaults.

### Default Security Context

The chart applies restrictive security contexts at both pod and container levels:

**Pod Level Security:**
```yaml
securityContext:
  pod:
    runAsNonRoot: true     # Enforces non-root execution
    runAsUser: 65534       # Uses 'nobody' user (non-privileged)
    runAsGroup: 65534      # Uses 'nobody' group  
    fsGroup: 65534         # File system group for volume permissions
    seLinuxOptions:
      level: "s0"          # SELinux security level
```

**Container Level Security:**
```yaml
securityContext:
  container:
    readOnlyRootFilesystem: true      # Prevents root filesystem writes
    allowPrivilegeEscalation: false   # Blocks privilege escalation
    capabilities:
      drop: ["ALL"]                   # Drops all Linux capabilities
```

### Dedicated ServiceAccount

The chart creates a dedicated ServiceAccount with minimal permissions:

```yaml
serviceAccount:
  create: true                           # Creates dedicated ServiceAccount
  automountServiceAccountToken: false   # Disables token auto-mounting for security
  annotations: {}                        # Optional annotations
  name: ""                              # Uses generated name by default
```

### Custom Security Configuration

You can customize security settings for your specific requirements:

**Custom User/Group IDs:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set securityContext.pod.runAsUser=1001 \
  --set securityContext.pod.runAsGroup=1001
```

**Using Existing ServiceAccount:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set serviceAccount.create=false \
  --set serviceAccount.name=my-existing-serviceaccount
```

**Values YAML Configuration:**
```yaml
securityContext:
  pod:
    runAsUser: 1001
    runAsGroup: 1001
    fsGroup: 1001
  container:
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]

serviceAccount:
  create: true
  annotations:
    iam.gke.io/gcp-service-account: "smartmet@project.iam.gserviceaccount.com"
```

### Security Benefits

The implemented security configuration provides:

- **Zero-privilege execution**: Containers run as non-root user with no Linux capabilities
- **Filesystem protection**: Read-only root filesystem prevents runtime modifications  
- **Identity isolation**: Dedicated ServiceAccount with no API token access
- **Volume security**: Proper file system group ownership for mounted data
- **Defense in depth**: Security enforced at both pod and container levels
- **Compliance ready**: Follows Kubernetes Pod Security Standards (Restricted profile)

## Resource Configuration

The chart includes default resource limits and requests optimized for typical SmartMet Server workloads. You can customize these values based on your specific requirements:

### Default Resource Configuration

```yaml
smartmetserver:
  resources:
    limits:
      memory: 4Gi
      cpu: "2"
    requests:
      cpu: "0.5"
      memory: 2Gi
```

### Custom Resource Configuration

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set smartmetserver.resources.limits.memory=8Gi \
  --set smartmetserver.resources.limits.cpu=4 \
  --set smartmetserver.resources.requests.memory=4Gi \
  --set smartmetserver.resources.requests.cpu=1
```

**Values YAML:**
```yaml
smartmetserver:
  resources:
    limits:
      memory: 8Gi
      cpu: "4"
    requests:
      memory: 4Gi
      cpu: "1"
```

### Disabling Resource Constraints

To disable resource limits and requests entirely:

```yaml
smartmetserver:
  resources: {}
```

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

## QueryData Engine Configuration

The QueryData engine configuration supports three different configuration methods, allowing you to choose the approach that best fits your needs.

### Method 1: Structured Configuration (Recommended)

The structured configuration approach allows you to define producers and levels using YAML structures, with automatic generation of the configuration file. This is the recommended approach as it's more maintainable and easier to understand.

**Example:**
```yaml
smartmetConf:
  querydata:
    # Global settings
    basePath: "/smartmet/data"
    defaultArea: "world"
    
    # Global defaults for all producers
    defaults:
      forecast: true
      type: "grid"
      refresh_interval_secs: 60
      number_to_keep: 4
      multifile: false
      alias: ""  # Empty = no alias line generated
    
    # Producer definitions
    producers:
      - name: ecmwf
        area: "kenya"
        levels:
          surface:
            alias: ["ecmwf"]
            number_to_keep: 4
          pressure:
            alias: "ecmwf_kenya_pressure"
            number_to_keep: 2
            multifile: null  # null = omit multifile line
      
      - name: gfs
        levels:
          surface:
            alias: ["gfs"]
          pressure:
            alias: ["gfs_pressure"]
      
      - name: icon
        area: "europe"
        forecast: false
        levels:
          surface: {}  # Uses all defaults
```

**Generated Configuration:**
```
producers = ["ecmwf_pressure", "ecmwf_surface", "gfs_pressure", "gfs_surface", "icon_surface"];

ecmwf_surface:
{
    alias = ["ecmwf"];
    directory = "/smartmet/data/ecmwf/kenya/surface/querydata";
    pattern = ".*_ecmwf_.*_surface\.sqd$";
    forecast = true;
    type = "grid";
    leveltype = "surface";
    refresh_interval_secs = 60;
    number_to_keep = 4;
    multifile = false;
};

ecmwf_pressure:
{
    alias = "ecmwf_kenya_pressure";
    directory = "/smartmet/data/ecmwf/kenya/pressure/querydata";
    pattern = ".*_ecmwf_.*_pressure\.sqd$";
    forecast = true;
    type = "grid";
    leveltype = "pressure";
    refresh_interval_secs = 60;
    number_to_keep = 2;
};
```

#### Configuration Priority

Settings are resolved with the following priority (highest to lowest):
1. Level-specific setting
2. Producer-specific setting
3. Global default

#### Alias Handling

- **Empty string** (`alias: ""`): No alias line is generated
- **String** (`alias: "ecmwf"`): Generates `alias = "ecmwf";`
- **Array** (`alias: ["ecmwf"]`): Generates `alias = ["ecmwf"];`
- **Null** (`alias: null`): Uses parent or global default

#### Multifile Handling

- **Set to value** (`multifile: false`): Generates `multifile = false;`
- **Set to null** (`multifile: null`): Omits the multifile line entirely
- **Not set**: Inherits from producer or global defaults

### Method 2: Raw Configuration

Provide the complete configuration as a raw string. Useful for complex configurations or when migrating from existing setups.

```yaml
smartmetConf:
  querydata:
    raw: |
      @include "querydata/translations.conf"
      verbose = true;
      valid_points_cache_dir = "/var/smartmet/cache/validpoints";
      producers = ["custom_surface"];
      custom_surface:
      {
          directory = "/custom/path/querydata";
          pattern = ".*custom.*\.sqd$";
          forecast = true;
          type = "grid";
          leveltype = "surface";
      };
```

### Method 3: Legacy String Format (Backward Compatible)

The original string-based configuration format is still supported for backward compatibility:

```yaml
smartmetConf:
  querydata: |
    @include "querydata/translations.conf"
    verbose = true;
    producers = ["demo_surface"];
    demo_surface:
    {
        directory = "/smartmet/data/demo/surface/querydata";
        pattern = ".*demo.*\.sqd$";
    };
```
