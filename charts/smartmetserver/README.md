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
| `serviceMonitor.enabled` | Enable Prometheus ServiceMonitor for metrics collection | `false` |
| `serviceMonitor.interval` | Prometheus scraping interval | `30s` |
| `serviceMonitor.scrapeTimeout` | Prometheus scraping timeout | `10s` |
| `serviceMonitor.path` | Metrics endpoint path | `/metrics` |
| `serviceMonitor.honorLabels` | Honor labels from the target | `false` |
| `serviceMonitor.labels` | Additional labels for the ServiceMonitor | `{}` |
| `serviceMonitor.annotations` | Additional annotations for the ServiceMonitor | `{}` |
| `serviceMonitor.metricRelabelings` | Metric relabelings to apply | `[]` |
| `serviceMonitor.relabelings` | Target relabelings to apply | `[]` |
| `serviceMonitor.targetLabels` | Target labels to add to scraped metrics | `[]` |
| `serviceMonitor.namespaceSelector` | Namespace selector for cross-namespace monitoring | `{}` |
| `networkPolicy.enabled` | Enable NetworkPolicy for network security | `false` |
| `networkPolicy.annotations` | Additional annotations for the NetworkPolicy | `{}` |
| `networkPolicy.ingress.enabled` | Enable ingress rules in NetworkPolicy | `true` |
| `networkPolicy.ingress.rules` | Custom ingress rules (uses sensible defaults if empty) | `[]` |
| `networkPolicy.egress.enabled` | Enable egress rules in NetworkPolicy | `true` |
| `networkPolicy.egress.rules` | Custom egress rules (uses sensible defaults if empty) | `[]` |
| `smartmetserver.livenessProbe.httpGet.enabled` | Enable HTTP health checks for liveness probe | `false` |
| `smartmetserver.livenessProbe.httpGet.path` | HTTP path for liveness probe | `/admin?what=qengine` |
| `smartmetserver.readinessProbe.httpGet.enabled` | Enable HTTP health checks for readiness probe | `false` |
| `smartmetserver.readinessProbe.httpGet.path` | HTTP path for readiness probe | `/admin?what=qengine` |
| `smartmetserver.startupProbe.httpGet.enabled` | Enable HTTP health checks for startup probe | `false` |
| `smartmetserver.startupProbe.httpGet.path` | HTTP path for startup probe | `/admin?what=qengine` |


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

## Observability and Monitoring

The SmartMet Server chart includes comprehensive observability features for production monitoring and operational excellence.

### ServiceMonitor for Prometheus

Enable Prometheus metrics collection with ServiceMonitor:

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.interval=30s \
  --set serviceMonitor.path=/metrics
```

**Values YAML:**
```yaml
serviceMonitor:
  enabled: true
  interval: 30s          # Scraping interval
  scrapeTimeout: 10s     # Scraping timeout
  path: /metrics         # Metrics endpoint path
  honorLabels: false     # Honor labels from target
  # Additional labels for the ServiceMonitor
  labels:
    team: weather-services
  # Metric relabelings to modify scraped metrics
  metricRelabelings:
    - sourceLabels: [__name__]
      regex: 'unwanted_metric.*'
      action: drop
```

### Network Security with NetworkPolicy

Control network traffic with NetworkPolicy:

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set networkPolicy.enabled=true
```

**Values YAML:**
```yaml
networkPolicy:
  enabled: true
  ingress:
    enabled: true
    # Custom ingress rules (optional - defaults provided)
    rules:
      - from:
          - podSelector:
              matchLabels:
                app: api-gateway
        ports:
          - protocol: TCP
            port: 8080
  egress:
    enabled: true
    # Custom egress rules (optional - defaults provided)
    rules:
      - to: []
        ports:
          - protocol: TCP
            port: 443  # HTTPS
```

### HTTP Health Checks

Enable HTTP-based health checks for better monitoring:

**Helm Command:**
```bash
helm upgrade --install smartmetserver fmi/smartmetserver \
  --namespace smartmetserver --create-namespace \
  --set smartmetserver.livenessProbe.httpGet.enabled=true \
  --set smartmetserver.readinessProbe.httpGet.enabled=true \
  --set smartmetserver.startupProbe.httpGet.enabled=true
```

**Values YAML:**
```yaml
smartmetserver:
  livenessProbe:
    httpGet:
      enabled: true
      path: /admin?what=qengine  # SmartMet health endpoint
  readinessProbe:
    httpGet:
      enabled: true
      path: /admin?what=qengine
  startupProbe:
    httpGet:
      enabled: true
      path: /admin?what=qengine
```

### Grafana Dashboard

The chart includes a pre-configured Grafana dashboard for monitoring SmartMet Server:

- **Location**: `dashboards/smartmetserver-dashboard.json`
- **Features**: CPU/Memory usage, pod status, container restarts
- **Variables**: Namespace selector for multi-environment support

Import the dashboard into Grafana or use it with dashboard provisioning:

```yaml
# Grafana dashboard provisioning
apiVersion: v1
kind: ConfigMap
metadata:
  name: smartmetserver-dashboard
  namespace: monitoring
data:
  smartmetserver-dashboard.json: |
    {{ .Files.Get "dashboards/smartmetserver-dashboard.json" | indent 4 }}
```

### Automated Testing

The chart includes comprehensive test suites:

**Run Connection Tests:**
```bash
helm test smartmetserver --namespace smartmetserver
```

**Test Templates:**
- `test-connection.yaml`: Basic connectivity and health endpoint testing
- `test-functionality.yaml`: Plugin availability and API endpoint validation

**Custom Test Configuration:**
```yaml
# Tests are enabled by default and include:
# - HTTP connectivity testing
# - Health endpoint validation (/admin?what=qengine)
# - Version endpoint testing (/admin?what=version)
# - Plugin availability checks
```

### Complete Observability Setup

**Production-Ready Monitoring:**
```yaml
# Complete observability configuration
serviceMonitor:
  enabled: true
  interval: 15s
  path: /metrics
  labels:
    team: weather-services
    environment: production

networkPolicy:
  enabled: true
  ingress:
    enabled: true
  egress:
    enabled: true

smartmetserver:
  livenessProbe:
    httpGet:
      enabled: true
      path: /admin?what=qengine
  readinessProbe:
    httpGet:
      enabled: true
      path: /admin?what=qengine
  startupProbe:
    httpGet:
      enabled: true
      path: /admin?what=qengine

# High availability for monitoring
podDisruptionBudget:
  enabled: true
  minAvailable: 1

hpa:
  minReplicas: 2
  maxReplicas: 6
  targetCPUUtilizationPercentage: 60
```

### Post-Installation Validation

After installation, the NOTES.txt template provides:

1. **Service Access Instructions**: How to connect to SmartMet Server
2. **Health Check Commands**: Verify service is running correctly
3. **API Endpoint Documentation**: Available SmartMet Server endpoints
4. **Monitoring Information**: ServiceMonitor and dashboard details
5. **Configuration Details**: ConfigMap and volume information

**Example NOTES.txt Output:**
```
1. Get the application URL by running these commands:
   export POD_NAME=$(kubectl get pods --namespace smartmetserver -l "app.kubernetes.io/name=smartmetserver" -o jsonpath="{.items[0].metadata.name}")
   kubectl --namespace smartmetserver port-forward $POD_NAME 8080:8080

2. SmartMet Server API endpoints:
   - Health check: GET /admin?what=qengine
   - Version info: GET /admin?what=version
   - Time series data: GET /timeseries?...

3. Monitoring:
   - Prometheus ServiceMonitor is enabled for metrics collection
   - Metrics endpoint: /metrics
```

## Troubleshooting

### Common Observability Issues

**ServiceMonitor not discovered:**
```bash
# Check ServiceMonitor labels match Prometheus selector
kubectl get servicemonitor -n smartmetserver -o yaml

# Verify Prometheus has access to the namespace
kubectl get rolebinding -n smartmetserver
```

**NetworkPolicy blocking traffic:**
```bash
# Check NetworkPolicy rules
kubectl get networkpolicy -n smartmetserver -o yaml

# Test connectivity from allowed sources
kubectl run test-pod --image=curlimages/curl -it --rm -- \
  curl -f smartmetserver.smartmetserver.svc.cluster.local:80/admin?what=version
```

**Health checks failing:**
```bash
# Check pod logs for health check errors
kubectl logs -f deployment/smartmetserver -n smartmetserver

# Test health endpoints manually
kubectl port-forward svc/smartmetserver 8080:80 -n smartmetserver
curl http://localhost:8080/admin?what=qengine
```
