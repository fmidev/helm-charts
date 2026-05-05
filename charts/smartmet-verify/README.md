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

2. You must create:
   - A **pull secret** for Quay.io
   - **configuration Secrets** for GUI and/or runner

## Private container images

The application images are private and hosted in Quay.io

- `quay.io/fmi/fmi-verification-gui`
- `quay.io/fmi/fmi-verification-runner`

You must create an image pull secret:

```shell
kubectl create secret docker-registry container-registry-pull-secret \
  --docker-server=quay.io \
  --docker-username=<USERNAME> \
  --docker-password=<PASSWORD> \
  --docker-email=<EMAIL>
```

or:

1. Download the Kubernetes pull secret for the account (e.g. to `pull-secret.yaml`).
2. Submit the secret to the cluster:
```shell
kubectl create -f pull-secret.yaml --namespace=smartmet-verify
```
3. Update Kubernetes configuration:
```yaml
imagePullSecrets:
  - name: put-secret-name-here
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

## Runner monitoring port

The runner exposes port 8080 (Spring Boot Actuator) via a ClusterIP Service.
This allows external monitoring tools such as Prometheus to scrape metrics
without exposing the runner publicly. The port is configurable:

```yaml
runner:
  service:
    port: 8080   # default
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

The GUI and runner liveness and readiness probes support the full Kubernetes
probe-action set. Each of `gui.probes.liveness`, `gui.probes.readiness`,
`runner.probes.liveness` and `runner.probes.readiness` accepts one of the
optional keys `httpGet`, `tcpSocket` or `exec` (passed through verbatim to the
pod spec). If none is set, the template falls back to the existing `path:`
shortcut, which performs an `httpGet` against the named `http` port.

The runner does not expose an HTTP server by default, so `exec` probes are the
recommended choice there:

```yaml
runner:
  probes:
    liveness:
      exec:
        command: ["true"]
      initialDelaySeconds: 30
      periodSeconds: 30
    readiness:
      exec:
        command: ["true"]
      initialDelaySeconds: 10
      periodSeconds: 15
```

The GUI's Spring Security configuration protects `/actuator/**` by default, so
the `path:` shortcut returns HTTP 401 unless the `noauth` Spring profile is
active or the health endpoints are explicitly permitted. A `tcpSocket` probe
avoids this:

```yaml
gui:
  probes:
    liveness:
      tcpSocket:
        port: http
    readiness:
      tcpSocket:
        port: http
```

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
kubectl -n <ns> create configmap verification-db-init-sql \
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
