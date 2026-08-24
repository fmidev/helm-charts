# fmi-redis

Minimal, single-instance Redis deployment on the official Redis image (`docker.io/library/redis`).

This chart currently intentionally does **not** provide replication, Sentinel, or clustering. It exists as a lightweight, non-Bitnami replacement for apps that just need a Redis (or Redis-protocol-compatible) cache reachable at a stable in-namespace address — no automatic failover. If you need HA, use a Sentinel- or Operator-based chart instead.

Resource names are derived from the Helm release name (`<release-name>-redis`), so multiple
releases can coexist in the same namespace, and this chart is also safe to use as a subchart
dependency of another chart — it won't collide with resources that chart names after the bare
release name.

## Usage

Install standalone or add as a dependency to another chart:

```yaml
# Chart.yaml
dependencies:
  - name: fmi-redis
    version: "0.1.0"
    repository: "https://fmidev.github.io/helm-charts"
```

When used as a dependency, nest values under `fmi-redis:`.

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `docker.io/library/redis` |
| `image.tag` | Container image tag | `8-alpine` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | List of imagePullSecrets objects (each item like `- name: my-registry-secret`) for pulling the image from a private registry | `[]` |
| `podSecurityContext` | Pod-level `securityContext`. Left at just `runAsNonRoot: true` by default so OpenShift's SCC can auto-assign a non-root uid/fsGroup from the namespace's own range — **do not hardcode `runAsUser`/`fsGroup` here for OpenShift**, the SCC will reject a fixed uid that doesn't fall in its allocated range. On a plain Kubernetes cluster with no such admission controller, override this to match the image's actual uid/gid instead (`redis:8-alpine` is `999:1000`, `redis:8` is `999:999`) — see `ci/kind-values.yaml` for that, used by this chart's own CI | `runAsNonRoot: true` |
| `resources` | Standard Kubernetes resources block | `256Mi/100m` requests, `512Mi/500m` limits |
| `persistence.enabled` | Back `/data` with a PVC instead of `emptyDir` | `true` |
| `persistence.size` | PVC storage request | `8Gi` |
| `persistence.storageClassName` | Storage class; omit to use the cluster default | `""` |
| `auth.enabled` | Require a password (`requirepass`) | `false` |
| `auth.existingSecret` | Name of an existing Secret with a `redis-password` key; takes precedence over `auth.password` | `""` |
| `auth.password` | Plaintext password, only used when `auth.existingSecret` is unset | `""` |
| `service.port` | Service port | `6379` |
| `config.enabled` | Mount a custom `redis.conf` at `/usr/local/etc/redis/redis.conf` and start `redis-server` with it | `false` |
| `config.existingConfigMap` | Name of an existing ConfigMap with a `redis.conf` key; takes precedence over `config.content` | `""` |
| `config.content` | Raw `redis.conf` content, only used when `config.existingConfigMap` is unset | `""` |

## Connecting

Other workloads in the same namespace can reach it at `<release-name>-redis:<service.port>` (or
`<release-name>-redis.<namespace>:<service.port>` from other namespaces). When used as a
dependency, `<release-name>` is the _parent_ chart's release name.

## Example

### With password and pre-existing secret

```yaml
fmi-redis:
  image:
    tag: "8-alpine"
  persistence:
    enabled: true
    size: 8Gi
  auth:
    enabled: true
    existingSecret: my-app-redis-secret
```

### With password and plain text password

```yaml
fmi-redis:
  image:
    tag: "8-alpine"
  persistence:
    enabled: true
    size: 8Gi
  auth:
    enabled: true
    password: my-super-secret-redis-password
```

### Without authentication

```yaml
fmi-redis:
  image:
    tag: "8-alpine"
  persistence:
    enabled: true
    size: 8Gi
  auth:
    enabled: false
```

### With a custom redis.conf

`auth.enabled`/`auth.password` still work on top of a custom config — they're applied as an
extra `--requirepass` argument after the config file, so don't set `requirepass` yourself in
`config.content`.

```yaml
fmi-redis:
  config:
    enabled: true
    content: |
      maxmemory 100mb
      maxmemory-policy allkeys-lru
```

Or reference a ConfigMap you manage yourself:

```yaml
fmi-redis:
  config:
    enabled: true
    existingConfigMap: my-redis-conf
```
