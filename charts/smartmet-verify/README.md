# SmartMet Verify Helm Chart

This Helm chart deploys the **SmartMet Verify** system, consisting of:

- `fmi-verification-gui` (web application)
- `fmi-verification-runner` (background processing)
- `fmi-verification-loader` (optional EDR model-data loader)

Each component can be deployed on its own or alongside the others. This chart
deploys applications only; the PostgreSQL/PostGIS database is a separate
concern, handled by the sibling
[`smartmet-verify-database`](../smartmet-verify-database/) chart — see
[Database](#database).

## Overview

The chart is designed to:

- Work on standard Kubernetes (RKE2) and OpenShift
- Support separate deployments of GUI, runner and the optional EDR model-data loader
- Use **external services**:
  - PostgreSQL/PostGIS database
  - SmartMet Server (HTTP API)
- Use **Secrets for configuration** (recommended)

> **All components are disabled by default.** You must explicitly enable at
> least one:
> ```yaml
> gui:
>   enabled: true
> runner:
>   enabled: true
> loader:
>   enabled: true
> ```

### Replicas

The GUI is the only component that scales. `gui.replicaCount` is yours to set;
the runner and loader are pinned to a single pod each and have no
`replicaCount` at all.

Both reconcile shared state — the runner polls one queue of result orders and
marks them done, the loader owns the forecasts ledger and a spool volume — so a
second replica would repeat the work rather than share it, and would contend on
a `ReadWriteOnce` PVC. Their Deployments therefore hardcode `replicas: 1` and
use the `Recreate` strategy, so not even a rollout overlaps two pods. Setting
`runner.replicaCount` or `loader.replicaCount` is rejected by the schema
instead of being silently ignored:

```text
- at '/runner/replicaCount': false schema
```

## Prerequisites

Before installing:

1. You must have:
   - A Kubernetes or OpenShift cluster
   - `kubectl` or `oc` configured
   - `helm` installed
   - An ingress controller (Kubernetes) or Route support (OpenShift) — RKE2 includes Traefik by default
   - A DNS record for the GUI hostname pointing to the cluster's ingress IP
   - [cert-manager](https://cert-manager.io/) with a `letsencrypt` ClusterIssuer for automated TLS (Kubernetes); on OpenShift TLS is handled by the Route
   - A PostgreSQL/PostGIS database — see [Database](#database)

2. You must create:
   - **configuration Secrets** for GUI and/or runner

## Container images

The application images are public on GitHub Container Registry:

- `ghcr.io/fmidev/fmi-verification-gui`
- `ghcr.io/fmidev/fmi-verification-runner`
- `ghcr.io/fmidev/fmi-verification-loader` (only when `loader.enabled: true`)

**No image pull secret is needed** to deploy this chart as shipped.

`imagePullSecrets` remains available for deployments that point the image
repositories somewhere that does require credentials — a private mirror, or an
air-gapped copy:

```yaml
imagePullSecrets:
  - name: pull-secret
```

```shell
kubectl create secret docker-registry pull-secret \
  --docker-server=<REGISTRY> \
  --docker-username=<USERNAME> \
  --docker-password=<PASSWORD> \
  --namespace=smartmet-verify
```

### Image registry and tag overrides

To use a mirror or a private registry for all images:

```yaml
global:
  imageRegistry: my-registry.example.org
```

Tags must be set per component, as the three applications are versioned
independently:

```yaml
gui:
  image:
    tag: "1.2.3"
runner:
  image:
    tag: "4.5.6"
loader:
  image:
    tag: "0.3.7"
```

## Configuration

Each application requires its own configuration file (`application.yaml`).

### Configuration modes

Set `config.mode` for each component independently:

| Mode | Description |
|------|-------------|
| `configMapFile` | Mount a single file from a ConfigMap. **Recommended** — keep non-sensitive config in version control; inject only the DB password from a Secret via `extraEnv`. |
| `secretFile` | Mount a single file from a Secret. Use when the entire config must be opaque. |
| `env` | Import environment variables from Secrets and/or ConfigMaps. |
| `none` | No configuration injection. |

#### `configMapFile` mode (recommended)

Store the non-sensitive `application.yaml` in a ConfigMap. Use `${SPRING_DATASOURCE_PASSWORD}`
as a Spring placeholder — it is resolved at startup from the `SPRING_DATASOURCE_PASSWORD`
environment variable, which you inject from a separate password-only Secret:

```yaml
gui:
  config:
    mode: configMapFile
    configMapFile:
      configMapName: smartmet-verify-gui-config   # must be set
  extraEnv:
    - name: SPRING_DATASOURCE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: smartmet-verify-gui-db-password   # Secret containing only the password
          key: password
```

#### `secretFile` mode

Create a Secret containing `application.yaml` and reference it:

```yaml
gui:
  config:
    mode: secretFile
    secretFile:
      secretName: smartmet-verify-gui-config   # must be set
```

#### `env` mode

```yaml
gui:
  config:
    mode: env
    envFrom:
      secretRefs:
        - my-spring-secrets
      configMapRefs:
        - my-spring-config
```

### Example: GUI configuration ConfigMap

The `application.yaml` is stored in a ConfigMap. The DB password is a Spring placeholder
resolved from the `SPRING_DATASOURCE_PASSWORD` env var (injected by the chart via `extraEnv`).

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: smartmet-verify-gui-config
  namespace: smartmet-verify
data:
  application.yaml: |
    spring:
      datasource:
        name: verification
        type: com.zaxxer.hikari.HikariDataSource
        driverClassName: org.postgresql.Driver
        jdbcUrl: jdbc:postgresql://verification-db:5432/verifapi
        # readOnly: false is required to enable the result calculation and user UI selection storing from GUI, set this to true if not required
        readOnly: false
        username: verifwww
        password: "${SPRING_DATASOURCE_PASSWORD}"
        connectionInitSql: SET SESSION TIME ZONE 'UTC'
        poolName: verification
        maximumPoolSize: 5
        initialize: false
    observation:
      smartmet-server:
        url: http://smartmet-server.example.org/timeseries
    locales:
      supported-language-tags: en-US
      default-language-tag: en-US
    security:
      require-ssl: false
      basic:
        enabled: false
      # List of allowed GUI views
      view-whitelist:
        - MetadataView
        - ModelAndObservationTablesView
        #- ...
      # Where to redirect an empty request. Needs to be in list above.
      default-redirect: MetadataView
    verification-gui:
      wiki:
        url: https://wiki.example.com/path/to/documentation
    logging:
      level:
        fi.fmi.verification: INFO
```

Password Secret (contains only the DB password):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: smartmet-verify-gui-db-password
  namespace: smartmet-verify
type: Opaque
stringData:
  password: change-me
```

### Example: Runner configuration ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: smartmet-verify-runner-config
  namespace: smartmet-verify
data:
  application.yaml: |
    spring:
      datasource:
        name: verification
        type: com.zaxxer.hikari.HikariDataSource
        driverClassName: org.postgresql.Driver
        jdbcUrl: jdbc:postgresql://verification-db:5432/verifapi
        readOnly: false
        username: verifrun
        password: "${SPRING_DATASOURCE_PASSWORD}"
        connectionInitSql: SET SESSION TIME ZONE 'UTC'
        poolName: verification
        maximumPoolSize: 5
        initialize: false
    observation:
      smartmet-server:
        url: http://smartmet-server.example.org/timeseries
        producer-fmi: observations_fmi
        #producer-road: ...
    logging:
      level:
        fi.fmi.verification: INFO
```

Password Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: smartmet-verify-runner-db-password
  namespace: smartmet-verify
type: Opaque
stringData:
  password: change-me
```

### Full example YAML files

See [`examples/`](./examples/).

## Exposing the GUI

### Standard Kubernetes (Ingress)

```yaml
gui:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: verify.example.org
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: verify-tls
        hosts:
          - verify.example.org
    # Use customAnnotations for cert-manager or other ingress controller annotations.
    # These are merged with any chart-default annotations.
    customAnnotations:
      cert-manager.io/cluster-issuer: letsencrypt
```

### OpenShift (Route)

```yaml
gui:
  route:
    enabled: true
    host: verify.apps.openshift.example.org
    tls:
      enabled: true
      termination: edge
      insecureEdgeTerminationPolicy: Redirect
```

Do not enable both `ingress` and `route` at the same time.

## Management port

All three applications expose Spring Boot Actuator on a dedicated management
port, separate from the main HTTP port 8080 — **8081** for the GUI, **8082** for
the runner and **8083** for the loader, so they do not collide on a host where
they share a network namespace. Each value must match `management.server.port`
in that application's own `application.yaml`. This port starts its
own HTTP listener that is independent of Spring Security, so health endpoints
are always reachable by probes regardless of the authentication profile active
on the main port.

The management port is used for liveness/readiness probes and can also be
scraped by Prometheus. It is configurable independently per component:

```yaml
gui:
  managementPort: 8081   # default
runner:
  managementPort: 8082   # default
```

## Writable `/tmp` volume

Both components run with `securityContext.readOnlyRootFilesystem: true`, which
blocks Tomcat/JVM writes to `/tmp`. To keep the root filesystem read-only while
still allowing these writes, the chart mounts an `emptyDir` at `/tmp` by
default. It is controlled independently per component:

```yaml
gui:
  tmpDir:
    enabled: true   # default
runner:
  tmpDir:
    enabled: true   # default
```

Disable only if you provide an alternative writable location for `/tmp`.

## Probes

Both components default to `httpGet` probes against their own management port
(8081 for the GUI, 8082 for the runner).
Because the management port is a separate HTTP listener that bypasses Spring
Security, probes work correctly regardless of which authentication profile is
active — no special probe configuration is needed.

Each probe field (`gui.probes.liveness`, `gui.probes.readiness`,
`runner.probes.liveness`, `runner.probes.readiness`) accepts any of the
standard Kubernetes probe actions — `httpGet`, `tcpSocket`, or `exec` — passed
through verbatim to the pod spec. Override only if you have a specific reason:

```yaml
# Example: disable readiness probing entirely for the runner
runner:
  probes:
    readiness:
      enabled: false
```

## Subchart usage

When this chart is used as a dependency (subchart) of a wrapper chart, all
values must be nested under the chart's release name key. For example, if the
dependency is declared as `name: smartmet-verify`, prefix every parameter from
this README with `smartmet-verify.`:

```yaml
# wrapper chart values.yaml
smartmet-verify:
  gui:
    enabled: true
    image:
      tag: "1.2.3"
  runner:
    enabled: true
```

The [deployment template](https://github.com/fmidev/smartmet-verify-deployment-template)
follows this pattern — its `values-rke2.yaml` and `values-openshift.yaml` use
the `smartmet-verify.` prefix throughout.

## Installation

1. Add Helm repo:
```shell
helm repo add fmi https://fmidev.github.io/helm-charts
helm repo update
```
2. Install chart:
```shell
helm install smartmet-verify fmi/smartmet-verify \
  --namespace smartmet-verify \
  -f values.yaml
```

## Database

**This chart does not deploy a database.** It expects the verification
PostgreSQL/PostGIS database to already exist, and is pointed at it through the
GUI, runner and loader configuration (`spring.datasource.jdbcUrl` and
`loader.db.jdbcUrl`).

To run the database inside the same cluster, use the separate
[`smartmet-verify-database`](../smartmet-verify-database/) chart, installed as
its own Helm release:

```shell
helm install verification-db fmi/smartmet-verify-database \
  --namespace smartmet-verify
```

That chart renders the CloudNativePG `Cluster`, vendors the SmartMet Verify
schema and FMI's reference metadata, and manages the login roles. Exactly one
Helm release may own `Cluster/verification-db`.

Any existing external PostgreSQL/PostGIS instance also works unchanged — point
the application configs at it and install neither database chart.

## Notes for operators

> **Upgrading a release that used to render the database.** Earlier versions of
> this chart could render the CloudNativePG `Cluster` themselves. If a release
> was installed that way, its `Cluster` and PVCs belong to *this* release, and
> upgrading to a version that no longer renders them makes Helm prune them —
> deleting the database with them. Move the database to the
> [`smartmet-verify-database`](../smartmet-verify-database/) chart, or to an
> external instance, **before** upgrading, and verify with
> `helm get manifest <release>` that no `Cluster` remains in this release's
> manifest.

- Always use Secrets for database credentials
- Keep the GUI, runner and loader configs separate
- Use different database users for each app
- Deploy into a dedicated namespace — the conventional default is `smartmet-verify` (may vary, especially on OpenShift where project names are customer-specific)

## Troubleshooting

Check pods:

```shell
kubectl get pods -n smartmet-verify
```

View logs:

```shell
kubectl logs -n smartmet-verify <pod-name>
```

Check mounted configuration:

```shell
kubectl exec -it <pod> -- ls /var/app/config
```

## Values schema

The chart ships a `values.schema.json`, which Helm enforces on `install`,
`upgrade`, `template` and `lint`.

It rejects **unknown top-level keys**. Values that this chart no longer reads --
`database.*`, removed in 0.8.0 -- and simple typos now fail with a clear message
instead of being silently ignored:

```text
Error: values don't meet the specifications of the schema(s) in the following chart(s):
smartmet-verify:
- at '': additional properties 'database' not allowed
```

(The exact wording comes from Helm's validator and differs between Helm 3 and
Helm 4; the path and the offending key are the parts to read.)

This matters most on `helm upgrade`: a values key that Helm ignores renders a
manifest without the resources it was meant to configure, and Helm prunes
whatever is missing. Failing the render is the safe outcome.

Nested configuration stays deliberately open. `extraEnv`, `podAnnotations`,
`resources`, `nodeSelector`, `tolerations`, `affinity`, probe bodies and the
whole of `global` accept any content, so pass-through Kubernetes fragments are
never blocked. Only well-defined leaves are typed -- `enabled` as a boolean,
`gui.replicaCount` and the ports as integers, image fields as strings. Quote
numeric-looking image tags (`tag: "1.2"`), or the schema rejects them; unquoted
they used to render as a broken image reference.

Two keys are rejected outright rather than typed: `runner.replicaCount` and
`loader.replicaCount`, because those Deployments hardcode `replicas: 1` (see
[Replicas](#replicas)). A key the templates never read is worse than no key --
it reads like a supported control and changes nothing.

**If a legitimate key is rejected, the schema is out of date, not the values.**
Do not work around it by removing the file: add the property to
`values.schema.json` alongside the template change that reads it, and open a PR.

## Chart Configuration

The following table lists all configurable parameters and their defaults.

### Global

| Parameter | Description | Default |
|---|---|---|
| `nameOverride` | Override the chart name used in resource names | `""` |
| `fullnameOverride` | Override the full name used in resource names | `""` |
| `commonLabels` | Labels added to every resource | `{}` |
| `commonAnnotations` | Annotations added to every resource | `{}` |
| `imagePullSecrets` | Image pull secrets for private registries | `[]` |
| `global.imageRegistry` | Global image registry prefix (overrides per-image registries) | `""` |
| `global.extraVolumes` | Extra volumes added to all pods | `[]` |
| `global.extraVolumeMounts` | Extra volume mounts added to all containers | `[]` |
| `serviceAccount.create` | Create a dedicated ServiceAccount | `true` |
| `serviceAccount.name` | ServiceAccount name (generated if empty) | `""` |
| `serviceAccount.annotations` | Annotations for the ServiceAccount | `{}` |
| `podSecurityContext.fsGroup` | Filesystem group for mounted volumes | `1000` |
| `securityContext.runAsNonRoot` | Require non-root execution | `true` |
| `securityContext.runAsUser` | User ID for the container process | `1000` |
| `securityContext.runAsGroup` | Group ID for the container process | `1000` |
| `securityContext.allowPrivilegeEscalation` | Allow privilege escalation | `false` |
| `securityContext.readOnlyRootFilesystem` | Mount root filesystem read-only | `true` |
| `securityContext.capabilities.drop` | Linux capabilities to drop | `["ALL"]` |

### GUI

| Parameter | Description | Default |
|---|---|---|
| `gui.enabled` | Deploy the GUI | `false` |
| `gui.replicaCount` | GUI pod replicas (runner/loader are pinned to 1) | `1` |
| `gui.image.repository` | GUI image repository | `ghcr.io/fmidev/fmi-verification-gui` |
| `gui.image.tag` | GUI image tag — **required** | `""` |
| `gui.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `gui.service.type` | Kubernetes Service type | `ClusterIP` |
| `gui.service.port` | Service port (main HTTP) | `8080` |
| `gui.resources.requests.memory` | Memory request | `3Gi` |
| `gui.resources.requests.cpu` | CPU request | `2` |
| `gui.resources.limits.memory` | Memory limit | `3Gi` |
| `gui.resources.limits.cpu` | CPU limit | `2` |
| `gui.nodeSelector` | Node selector constraints | `{}` |
| `gui.tolerations` | Pod tolerations | `[]` |
| `gui.affinity` | Pod affinity rules | `{}` |
| `gui.podAnnotations` | Annotations added to GUI pods | `{}` |
| `gui.podLabels` | Labels added to GUI pods | `{}` |
| `gui.springProfile` | Comma-separated Spring profile(s) to activate | `production` |
| `gui.env` | Environment variables for the GUI container | see `values.yaml` |
| `gui.extraEnv` | Additional environment variables | `[]` |
| `gui.extraEnvFrom` | Additional `envFrom` sources | `[]` |
| `gui.extraVolumes` | Additional volumes | `[]` |
| `gui.extraVolumeMounts` | Additional volume mounts | `[]` |
| `gui.config.mode` | Config injection mode: `configMapFile`, `secretFile`, `env`, or `none` | `secretFile` |
| `gui.config.configMapFile.configMapName` | ConfigMap containing `application.yaml` — **required** for `configMapFile` mode | `""` |
| `gui.config.configMapFile.configMapKey` | Key within the ConfigMap | `application.yaml` |
| `gui.config.configMapFile.mountPath` | Mount path inside the container | `/var/app/config` |
| `gui.config.configMapFile.fileName` | Filename at mount path | `application.yaml` |
| `gui.config.secretFile.secretName` | Secret containing `application.yaml` — **required** for `secretFile` mode | `""` |
| `gui.config.secretFile.secretKey` | Key within the Secret | `application.yaml` |
| `gui.config.secretFile.mountPath` | Mount path inside the container | `/var/app/config` |
| `gui.config.secretFile.fileName` | Filename at mount path | `application.yaml` |
| `gui.config.envFrom.secretRefs` | Secrets to import as env vars (`env` mode) | `[]` |
| `gui.config.envFrom.configMapRefs` | ConfigMaps to import as env vars (`env` mode) | `[]` |
| `gui.persistence.logs.enabled` | Persist Tomcat logs to a PVC | `false` |
| `gui.persistence.logs.size` | Log PVC size | `5Gi` |
| `gui.persistence.logs.storageClassName` | Storage class for the log PVC | `""` |
| `gui.persistence.logs.mountPath` | Log directory mount path | `/var/log/tomcat` |
| `gui.tmpDir.enabled` | Mount a writable `emptyDir` at `/tmp` (required with read-only root filesystem) | `true` |
| `gui.managementPort` | Spring Boot Actuator management port | `8081` |
| `gui.probes.liveness.enabled` | Enable liveness probe | `true` |
| `gui.probes.liveness.httpGet.path` | Liveness probe HTTP path | `/actuator/health/liveness` |
| `gui.probes.liveness.httpGet.port` | Liveness probe port | `management` |
| `gui.probes.liveness.initialDelaySeconds` | Seconds before first liveness check | `30` |
| `gui.probes.liveness.periodSeconds` | Seconds between liveness checks | `10` |
| `gui.probes.liveness.timeoutSeconds` | Probe timeout | `3` |
| `gui.probes.liveness.failureThreshold` | Failures before pod restart | `6` |
| `gui.probes.readiness.enabled` | Enable readiness probe | `true` |
| `gui.probes.readiness.httpGet.path` | Readiness probe HTTP path | `/actuator/health/readiness` |
| `gui.probes.readiness.httpGet.port` | Readiness probe port | `management` |
| `gui.probes.readiness.initialDelaySeconds` | Seconds before first readiness check | `20` |
| `gui.probes.readiness.periodSeconds` | Seconds between readiness checks | `10` |
| `gui.probes.readiness.timeoutSeconds` | Probe timeout | `3` |
| `gui.probes.readiness.failureThreshold` | Failures before pod marked unready | `6` |
| `gui.ingress.enabled` | Enable Ingress (Kubernetes / RKE2) | `false` |
| `gui.ingress.className` | Ingress class name (e.g. `traefik`, `nginx`) | `""` |
| `gui.ingress.annotations` | Ingress annotations | `{}` |
| `gui.ingress.customAnnotations` | Additional ingress annotations merged with `annotations` (e.g. `cert-manager.io/cluster-issuer`) | `{}` |
| `gui.ingress.hosts` | Ingress host rules | see `values.yaml` |
| `gui.ingress.tls` | Ingress TLS configuration | `[]` |
| `gui.route.enabled` | Enable OpenShift Route (mutually exclusive with `ingress.enabled`) | `false` |
| `gui.route.annotations` | Route annotations (e.g. HAProxy IP whitelist) | `{}` |
| `gui.route.host` | Route hostname | `""` |
| `gui.route.tls.enabled` | Enable TLS on the Route | `true` |
| `gui.route.tls.termination` | TLS termination type | `edge` |
| `gui.route.tls.insecureEdgeTerminationPolicy` | HTTP → HTTPS redirect policy | `Redirect` |

### Runner

| Parameter | Description | Default |
|---|---|---|
| `runner.enabled` | Deploy the runner | `false` |
| `runner.image.repository` | Runner image repository | `ghcr.io/fmidev/fmi-verification-runner` |
| `runner.image.tag` | Runner image tag — **required** | `""` |
| `runner.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `runner.service.type` | Kubernetes Service type | `ClusterIP` |
| `runner.service.port` | Service port | `8080` |
| `runner.resources.requests.memory` | Memory request | `6Gi` |
| `runner.resources.requests.cpu` | CPU request | `2` |
| `runner.resources.limits.memory` | Memory limit | `6Gi` |
| `runner.resources.limits.cpu` | CPU limit | `2` |
| `runner.nodeSelector` | Node selector constraints | `{}` |
| `runner.tolerations` | Pod tolerations | `[]` |
| `runner.affinity` | Pod affinity rules | `{}` |
| `runner.podAnnotations` | Annotations added to runner pods | `{}` |
| `runner.podLabels` | Labels added to runner pods | `{}` |
| `runner.springProfile` | Comma-separated Spring profile(s) to activate | `production` |
| `runner.env` | Environment variables for the runner container | see `values.yaml` |
| `runner.extraEnv` | Additional environment variables | `[]` |
| `runner.extraEnvFrom` | Additional `envFrom` sources | `[]` |
| `runner.extraVolumes` | Additional volumes | `[]` |
| `runner.extraVolumeMounts` | Additional volume mounts | `[]` |
| `runner.config.mode` | Config injection mode: `configMapFile`, `secretFile`, `env`, or `none` | `secretFile` |
| `runner.config.configMapFile.configMapName` | ConfigMap containing `application.yaml` — **required** for `configMapFile` mode | `""` |
| `runner.config.configMapFile.configMapKey` | Key within the ConfigMap | `application.yaml` |
| `runner.config.configMapFile.mountPath` | Mount path inside the container | `/var/app/config` |
| `runner.config.configMapFile.fileName` | Filename at mount path | `application.yaml` |
| `runner.config.secretFile.secretName` | Secret containing `application.yaml` — **required** for `secretFile` mode | `""` |
| `runner.config.secretFile.secretKey` | Key within the Secret | `application.yaml` |
| `runner.config.secretFile.mountPath` | Mount path inside the container | `/var/app/config` |
| `runner.config.secretFile.fileName` | Filename at mount path | `application.yaml` |
| `runner.config.envFrom.secretRefs` | Secrets to import as env vars (`env` mode) | `[]` |
| `runner.config.envFrom.configMapRefs` | ConfigMaps to import as env vars (`env` mode) | `[]` |
| `runner.persistence.logs.enabled` | Persist Tomcat logs to a PVC | `false` |
| `runner.persistence.logs.size` | Log PVC size | `5Gi` |
| `runner.persistence.logs.storageClassName` | Storage class for the log PVC | `""` |
| `runner.persistence.logs.mountPath` | Log directory mount path | `/var/log/tomcat` |
| `runner.tmpDir.enabled` | Mount a writable `emptyDir` at `/tmp` | `true` |
| `runner.managementPort` | Spring Boot Actuator management port | `8082` |
| `runner.probes.liveness.enabled` | Enable liveness probe | `true` |
| `runner.probes.liveness.httpGet.path` | Liveness probe HTTP path | `/actuator/health/liveness` |
| `runner.probes.liveness.httpGet.port` | Liveness probe port | `management` |
| `runner.probes.liveness.initialDelaySeconds` | Seconds before first liveness check | `30` |
| `runner.probes.liveness.periodSeconds` | Seconds between liveness checks | `20` |
| `runner.probes.liveness.timeoutSeconds` | Probe timeout | `3` |
| `runner.probes.liveness.failureThreshold` | Failures before pod restart | `6` |
| `runner.probes.readiness.enabled` | Enable readiness probe | `true` |
| `runner.probes.readiness.httpGet.path` | Readiness probe HTTP path | `/actuator/health/readiness` |
| `runner.probes.readiness.httpGet.port` | Readiness probe port | `management` |
| `runner.probes.readiness.initialDelaySeconds` | Seconds before first readiness check | `20` |
| `runner.probes.readiness.periodSeconds` | Seconds between readiness checks | `20` |
| `runner.probes.readiness.timeoutSeconds` | Probe timeout | `3` |
| `runner.probes.readiness.failureThreshold` | Failures before pod marked unready | `6` |
