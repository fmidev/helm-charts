# SmartMet Verify Helm Chart

This Helm chart deploys the **SmartMet Verify** system, consisting of:

- `fmi-verification-gui` (web application)
- `fmi-verification-runner` (background processing)

Both applications can be deployed together or independently. An optional PostgreSQL/PostGIS database can also be provisioned in the same namespace via the CloudNativePG operator.

## Overview

The chart is designed to:

- Work on standard Kubernetes (RKE2) and OpenShift
- Support separate deployments of GUI and runner
- Use **external services**:
  - PostgreSQL/PostGIS database
  - SmartMet Server (HTTP API)
- Use **Secrets for configuration** (recommended)

> **Both components are disabled by default.** You must explicitly enable at least one:
> ```yaml
> gui:
>   enabled: true
> runner:
>   enabled: true
> ```

## Prerequisites

Before installing:

1. You must have:
   - A Kubernetes or OpenShift cluster
   - `kubectl` or `oc` configured
   - `helm` installed
   - An ingress controller (Kubernetes) or Route support (OpenShift) — RKE2 includes Traefik by default
   - A DNS record for the GUI hostname pointing to the cluster's ingress IP
   - [cert-manager](https://cert-manager.io/) with a `letsencrypt` ClusterIssuer for automated TLS (Kubernetes); on OpenShift TLS is handled by the Route

2. You must create:
   - A **pull secret** for Quay.io
   - **configuration Secrets** for GUI and/or runner

## Private container images

The application images are private and hosted in Quay.io

- `quay.io/fmi/fmi-verification-gui`
- `quay.io/fmi/fmi-verification-runner`

You must create an image pull secret:

```shell
kubectl create secret docker-registry pull-secret \
  --docker-server=quay.io \
  --docker-username=<USERNAME> \
  --docker-password=<PASSWORD> \
  --docker-email=<EMAIL> \
  --namespace=smartmet-verify
```

or:

1. Download the Kubernetes pull secret for the account (e.g. to `pull-secret.yaml`).
2. Submit the secret to the cluster:
```shell
kubectl create -f pull-secret.yaml --namespace=smartmet-verify
```
3. Update Kubernetes configuration to reference the secret by the name used above:
```yaml
imagePullSecrets:
  - name: pull-secret
```

### Image registry and tag overrides

To use a mirror or a private registry for all images:

```yaml
global:
  imageRegistry: my-registry.example.org
```

Tags must be set per component, as GUI and runner are versioned independently:

```yaml
gui:
  image:
    tag: "1.2.3"
runner:
  image:
    tag: "4.5.6"
```

## Configuration

Each application requires its own configuration file (`application.yaml`).

### Configuration modes

Set `config.mode` for each component independently:

| Mode | Description |
|------|-------------|
| `secretFile` | Mount a single file from a Secret (default). Recommended. |
| `env` | Import environment variables from Secrets and/or ConfigMaps. |
| `none` | No configuration injection. |

#### `secretFile` mode (default)

Create a Secret containing `application.yaml` and reference it:

```yaml
gui:
  config:
    mode: secretFile
    secretFile:
      secretName: smartmet-verify-gui-config   # must be set
      secretKey: application.yaml              # key inside the Secret
      mountPath: /var/app/config
      fileName: application.yaml
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

### Example: GUI configuration secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: smartmet-verify-gui-config
type: Opaque
stringData:
  application.yaml: |
    spring:
      datasource:
        name: verification
        type: com.zaxxer.hikari.HikariDataSource
        driverClassName: org.postgresql.Driver
        jdbcUrl: jdbc:postgresql://verification-db.fmi.fi:5432/verifapi
        # readOnly: false is required to enable the result calculation and user UI selection storing from GUI, set this to true if not required
        readOnly: false
        username: verifwww
        password: change-me
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
      require-ssl: true
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
        url: https://wiki.fmi.fi/x/KQCB
    logging:
      level:
        fi.fmi.verification: INFO
```

### Example: Runner configuration secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: smartmet-verify-runner-config
type: Opaque
stringData:
  application.yaml: |
    spring:
      datasource:
        name: verification
        type: com.zaxxer.hikari.HikariDataSource
        driverClassName: org.postgresql.Driver
        jdbcUrl: jdbc:postgresql://verification-db.fmi.fi:5432/verifapi
        readOnly: false
        username: verifrun
        password: change-me
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

Both GUI and runner expose Spring Boot Actuator on a dedicated management port
(default **8081**), separate from the main HTTP port 8080. This port starts its
own HTTP listener that is independent of Spring Security, so health endpoints
are always reachable by probes regardless of the authentication profile active
on the main port.

The management port is used for liveness/readiness probes and can also be
scraped by Prometheus. It is configurable independently per component:

```yaml
gui:
  managementPort: 8081   # default
runner:
  managementPort: 8081   # default
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

Both components default to `httpGet` probes against the management port (8081).
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

## Database (optional)

The chart can optionally provision a PostgreSQL/PostGIS database using
[CloudNativePG](https://cloudnative-pg.io/) (CNPG). This is a convenience for
clusters that do not already have an external database; any existing
PostgreSQL/PostGIS instance continues to work unchanged.

### Install the CloudNativePG operator

**The CloudNativePG operator is NOT installed by this chart.** You must install
it separately, cluster-wide, before enabling the database:

```shell
kubectl apply --server-side -f \
  https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v1.29.0/cnpg-1.29.0.yaml
```

The above is the version this chart has been tested against. Any reasonably
current CNPG release should work.

### Enable the database

```yaml
database:
  enabled: true
  name: verification-db   # default
```

When enabled, the chart creates a `postgresql.cnpg.io/v1` `Cluster` named by
`database.name` (default `verification-db`). The default image is
`ghcr.io/cloudnative-pg/postgis:16-3.4`.

`database.spec` is a pass-through to the CNPG `Cluster.spec` — anything CNPG
supports goes there.

### Init SQL

The chart does not vendor the SmartMet Verify schema. You must provide the init
SQL yourself as an existing ConfigMap and reference it from `database.spec`.

Create the ConfigMap:

```shell
kubectl -n smartmet-verify create configmap verification-db-init-sql \
  --from-file=0000-pre-init.sql \
  --from-file=0001-production-schema.sql \
  --from-file=0002-post-ownership.sql
```

Reference it via CNPG's `postInitSQLRefs` and `postInitApplicationSQLRefs`:

```yaml
database:
  spec:
    bootstrap:
      initdb:
        postInitSQLRefs:
          configMapRefs:
            - { name: verification-db-init-sql, key: 0000-pre-init.sql }
        postInitApplicationSQLRefs:
          configMapRefs:
            - { name: verification-db-init-sql, key: 0002-post-ownership.sql }
            - { name: verification-db-init-sql, key: 0001-production-schema.sql }
```

`0002-post-ownership.sql` is a small user-supplied wrapper that transfers the
application database's ownership to `verifadmin` before the schema loads. It is
needed because the CNPG initdb `owner: app` default avoids conflicting with the
`CREATE ROLE verifadmin` in `0000-pre-init.sql`, so ownership has to be handed
over explicitly. Example contents:

```sql
ALTER DATABASE verifapi OWNER TO verifadmin;
ALTER SCHEMA public OWNER TO verifadmin;
GRANT USAGE ON SCHEMA public TO verif_ro;
GRANT CREATE ON SCHEMA public TO verifadmin;
```

### Role passwords

Role passwords come from `kubernetes.io/basic-auth` secrets that you create,
one per managed role:

```shell
kubectl -n smartmet-verify create secret generic verification-db-verifadmin \
  --type=kubernetes.io/basic-auth \
  --from-literal=username=verifadmin --from-literal=password=<password>
kubectl -n smartmet-verify create secret generic verification-db-verifwww \
  --type=kubernetes.io/basic-auth \
  --from-literal=username=verifwww --from-literal=password=<password>
kubectl -n smartmet-verify create secret generic verification-db-verifrun \
  --type=kubernetes.io/basic-auth \
  --from-literal=username=verifrun --from-literal=password=<password>
kubectl -n smartmet-verify create secret generic verification-db-verifimport \
  --type=kubernetes.io/basic-auth \
  --from-literal=username=verifimport --from-literal=password=<password>
```

The `verifwww` and `verifrun` passwords must also appear in the application
config Secrets (`smartmet-verify-gui-config` and `smartmet-verify-runner-config`
respectively). Keep the two in sync whenever you rotate a password.

### Managed role memberships

**Pitfall:** CNPG's `managed.roles` reconciliation removes any role memberships
it did not declare itself. If a role's privileges come from a
`GRANT <group_role> TO <user>` line in `0000-pre-init.sql`, you must **also**
repeat that via the `inRoles:` field on the managed role — otherwise CNPG will
revoke it on the next reconcile.

`examples/values-rke2.yaml` shows `verifwww` with `inRoles: [verif_ro]` and
`verifrun` with `inRoles: [verif_data_rw]` for exactly this reason.

### Service hostname

CNPG creates `<name>-rw`, `<name>-ro` and `<name>-r` services for the cluster.
Applications that hard-code `verification-db` as the database hostname (e.g.
in a pre-existing `application.yaml`) can get that name via
`database.spec.managed.services.additional` — a `selectorType: rw` service
template named `verification-db`. See `examples/values-rke2.yaml` for the exact
shape.

### Full example

See [`examples/values-rke2.yaml`](./examples/values-rke2.yaml) for a complete
working database configuration, including managed roles, additional services
and init SQL wiring.

## Notes for operators

- Always use Secrets for database credentials
- Keep GUI and runner configs separate
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
| `gui.replicaCount` | Number of GUI pod replicas | `1` |
| `gui.image.repository` | GUI image repository | `quay.io/fmi/fmi-verification-gui` |
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
| `gui.config.mode` | Config injection mode: `secretFile`, `env`, or `none` | `secretFile` |
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
| `runner.replicaCount` | Number of runner pod replicas | `1` |
| `runner.image.repository` | Runner image repository | `quay.io/fmi/fmi-verification-runner` |
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
| `runner.config.mode` | Config injection mode: `secretFile`, `env`, or `none` | `secretFile` |
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
| `runner.managementPort` | Spring Boot Actuator management port | `8081` |
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

### Database (CloudNativePG)

| Parameter | Description | Default |
|---|---|---|
| `database.enabled` | Provision a PostgreSQL/PostGIS database via CloudNativePG | `false` |
| `database.name` | CNPG `Cluster` name; also the stem of generated services (`<name>-rw`, `-ro`, `-r`) | `verification-db` |
| `database.spec.instances` | Number of PostgreSQL instances | `1` |
| `database.spec.imageName` | PostgreSQL + PostGIS container image | `ghcr.io/cloudnative-pg/postgis:16-3.4` |
| `database.spec.storage.size` | PVC size for database storage | `100Gi` |
| `database.spec.storage.storageClass` | Storage class for the database PVC | `""` |
| `database.spec.bootstrap.initdb.database` | Name of the application database to create | `verifapi` |
| `database.spec.bootstrap.initdb.owner` | Initial database owner role | `app` |
| `database.spec.bootstrap.initdb.postInitSQLRefs` | ConfigMap/Secret refs for SQL run before app init (e.g. `0000-pre-init.sql`) | `[]` |
| `database.spec.bootstrap.initdb.postInitApplicationSQLRefs` | ConfigMap/Secret refs for SQL run after app init (e.g. schema + ownership SQL) | `[]` |
| `database.spec.managed.roles` | CNPG managed roles with passwords from Kubernetes Secrets | `[]` |
| `database.spec.managed.services.additional` | Extra services (e.g. a `verification-db` alias for the primary) | `[]` |
