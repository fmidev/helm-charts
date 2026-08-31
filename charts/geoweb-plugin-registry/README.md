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

## AWS EKS deployment

The chart supports native AWS S3 storage, IAM roles for service accounts
(IRSA), GitLab OAuth credentials synchronized from AWS Secrets Manager, and
Kubernetes Ingress.

See the [AWS EKS deployment guide](docs/aws-eks.md) for the complete S3, IAM,
IRSA, Secrets Manager, GitLab OAuth, and verification procedure. A matching
sanitized values file is available at
[examples/values-aws-eks.yaml](examples/values-aws-eks.yaml).

## Configuration

| Parameter | Description | Default |
|---|---|---|
| `versions.pluginRegistry` | Optional application version override | `""` |
| `publicUrl` | Canonical external registry URL used for UI assets and package metadata | `""` |
| `image.repository` | Container image repository | `registry.gitlab.com/opengeoweb/backend-services/plugin-registry-backend/plugin-registry-backend` |
| `image.tag` | Container image tag | `v0.4.3` |
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
| `auth.secretName` | Kubernetes Secret consumed for GitLab OAuth client credentials | `""` |
| `auth.scope` | GitLab OAuth scopes | `openid email read_api` |
| `auth.usernameClaim` | GitLab identity claim used as username | `email` |
| `auth.secretProviderClass.enabled` | Synchronize the OIDC Kubernetes Secret from AWS Secrets Manager | `false` |
| `auth.secretProviderClass.name` | Optional SecretProviderClass name | `""` |
| `auth.secretProviderClass.region` | AWS region containing the Secrets Manager object | `""` |
| `auth.secretProviderClass.objectName` | Name or ARN of the JSON Secrets Manager object | `""` |
| `serviceAccount.create` | Create a service account for IAM credentials | `false` |
| `serviceAccount.name` | Existing or created service account name | `""` |
| `serviceAccount.annotations` | Service account annotations, including an AWS IAM role | `{}` |
| `serviceAccount.automountServiceAccountToken` | Mount the standard Kubernetes API token | `false` |
| `resources` | Container resource requests and limits | requests: `100m`/`128Mi`; limits: `500m`/`512Mi` |

## Chart versions

| Chart version | plugin-registry-backend version |
|---------------|---------------------------------|
| 0.2.0         | v0.4.3                          |
| 0.1.0         | v0.4.2                          |
