# SmartMet Verify Helm Chart

This Helm chart deploys the **SmartMet Verify** system, consisting of:

- `fmi-verification-gui` (web application)
- `fmi-verification-runner` (background processing)

Both applications are deployed independently and can be enabled or disabled as needed.

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
kubectl create -f pull-secret.yaml --namespace=PUT_NAMESPACE_HERE
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
  imageTag: "1.2.3"    # override tag for all components at once
```

Per-component tags can be set under `gui.image.tag` and `runner.image.tag`.

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

## Installation

1. Add Helm repo:
```shell
helm repo add fmidev https://fmidev.github.io/helm-charts
helm repo update
```
2. Install chart:
```shell
helm install smartmet-verify fmidev/smartmet-verify -f values.yaml
```

## Notes for operators

- Always use Secrets for database credentials
- Keep GUI and runner configs separate
- Use different database users for each app
- Prefer separate namespaces for production deployments

## Troubleshooting

Check pods:

```shell
kubectl get pods
```

View logs:

```shell
kubectl logs <pod-name>
```

Check mounted configuration:

```shell
kubectl exec -it <pod> -- ls /var/app/config
```
