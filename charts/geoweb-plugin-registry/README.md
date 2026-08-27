# GeoWeb Plugin Registry Helm chart

This chart deploys the Verdaccio plugin registry.

The chart intentionally deploys one registry replica. The production OpenID
configuration uses a file-backed store on the mounted PVC, which cannot safely
be shared by replicas across nodes. Supporting multiple replicas would require
a shared OpenID store such as Redis or DynamoDB.

## Render and install

```bash
helm lint charts/geoweb-plugin-registry
helm template geoweb-plugin-registry charts/geoweb-plugin-registry
helm upgrade --install geoweb-plugin-registry charts/geoweb-plugin-registry \
  --namespace plugin-registry --create-namespace
```


## AWS deployment

The AWS environment repository should provide the bucket, region, GitLab OAuth
Secret name, service account IAM role, and public hostname as Helm values. Leave
`storage.s3.endpoint` empty and set `pathStyle` to `false` for native AWS S3.
The S3 bucket and IAM role should be created outside this chart.
Set `ingress.className` to the IngressClass installed in the target cluster, or
leave it empty to use the cluster default.

Create a Kubernetes Secret containing the GitLab OAuth client credentials:

```bash
kubectl create secret generic plugin-registry-oidc \
  --from-literal=VERDACCIO_OPENID_CLIENT_ID=<gitlab-client-id> \
  --from-literal=VERDACCIO_OPENID_CLIENT_SECRET=<gitlab-client-secret> \
  --namespace=plugin-registry
```

Configure the chart with values similar to:

```yaml
publicUrl: https://plugins.example.com
storage:
  backend: s3
  s3:
    bucket: my-plugin-registry
    prefix: verdaccio
    region: eu-north-1
    endpoint: ""
    pathStyle: false
serviceAccount:
  create: true
  name: plugin-registry
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/plugin-registry-s3
auth:
  existingSecret: plugin-registry-oidc
ingress:
  enabled: true
  className: ""
  host: plugins.example.com
route:
  enabled: false
```

The IAM role needs permission to list the configured prefix and read/write
objects in the bucket. Keep `persistence.enabled` enabled because the OpenID
plugin stores its state at `/verdaccio/storage/openid-store`.

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `versions.pluginRegistry` | Optional application version override | `""` |
| `publicUrl` | Canonical external registry URL used for UI assets and package metadata | `""` |
| `image.repository` | Container image repository | `registry.gitlab.com/opengeoweb/backend-services/plugin-registry-backend/plugin-registry-backend` |
| `image.tag` | Container image tag | `v0.4.2` |
| `image.pullPolicy` | Kubernetes image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Optional image pull secrets for private images | `[]` |
| `service.port` | Service and container port | `4873` |
| `route.enabled` | Enable the OpenShift Route | `true` |
| `ingress.enabled` | Enable the Kubernetes Ingress | `false` |
| `ingress.className` | Optional Kubernetes Ingress class | `""` |
| `ingress.host` | Hostname used by the Ingress | `""` |
| `ingress.annotations` | Custom Ingress annotations | `{}` |
| `ingress.tls` | Ingress TLS entries | `[]` |
| `persistence.enabled` | Enable the PVC used for local package storage and OpenID state in S3 mode | `true` |
| `persistence.size` | PVC storage size | `10Gi` |
| `storage.backend` | `local` or `s3` | `local` |
| `storage.s3.bucket` | S3 bucket name | `""` |
| `storage.s3.prefix` | Object key prefix shared by Verdaccio and the API | `verdaccio` |
| `storage.s3.region` | AWS/S3 region | `""` |
| `storage.s3.endpoint` | Optional S3-compatible endpoint; empty for AWS | `""` |
| `storage.s3.pathStyle` | Use path-style S3 addressing | `false` |
| `storage.s3.existingSecret` | Secret containing AWS credential keys | `""` |
| `storage.s3.sessionTokenKey` | Session-token key in the AWS credentials Secret | `AWS_SESSION_TOKEN` |
| `auth.existingSecret` | Secret containing GitLab OAuth client credentials | `""` |
| `auth.scope` | GitLab OAuth scopes | `openid profile email read_api` |
| `auth.usernameClaim` | GitLab identity claim used as username | `email` |
| `serviceAccount.create` | Create a service account for IAM credentials | `false` |
| `serviceAccount.name` | Existing or created service account name | `""` |
| `serviceAccount.annotations` | Service account annotations, including an AWS IAM role | `{}` |
| `serviceAccount.automountServiceAccountToken` | Mount the standard Kubernetes API token | `false` |
| `resources` | Container resource requests and limits | requests: `100m`/`128Mi`; limits: `500m`/`512Mi` |

## Chart versions

| Chart version | plugin-registry-backend version |
|---------------|---------------------------------|
| 0.1.0         | v0.4.2                          |
