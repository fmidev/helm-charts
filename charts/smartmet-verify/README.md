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

## Configuration

Each application requires its own configuration file (`application.yaml`).

These are provided via Kubernetes Secrets.

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
