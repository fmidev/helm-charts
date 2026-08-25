# GeoWeb Plugin Registry Helm chart

This chart deploys the Verdaccio plugin registry.

## Render and install

```bash
helm lint charts/geoweb-plugin-registry
helm template geoweb-plugin-registry charts/geoweb-plugin-registry
helm upgrade --install geoweb-plugin-registry charts/geoweb-plugin-registry \
  --namespace plugin-registry --create-namespace
```

The default image is the private GitLab Container Registry image built by the
`plugin-registry-backend` repository. Create an image pull secret in the target
namespace before installing:

```bash
oc create secret docker-registry gitlab-registry \
  --docker-server=registry.gitlab.com \
  --docker-username=<gitlab-username> \
  --docker-password=<token-with-read-registry> \
  --namespace=plugin-registry

helm upgrade --install geoweb-plugin-registry charts/geoweb-plugin-registry \
  --namespace plugin-registry \
  --set image.pullPolicy=Always \
  --set imagePullSecrets[0].name=gitlab-registry
```
## Configuration

| Parameter | Description | Default |
|---|---|---|
| `versions.pluginRegistry` | Optional application version override | `""` |
| `image.repository` | Container image repository | `registry.gitlab.com/opengeoweb/backend-services/plugin-registry-backend/plugin-registry-backend` |
| `image.tag` | Container image tag | `v0.4.2` |
| `image.pullPolicy` | Kubernetes image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |
| `replicaCount` | Number of registry replicas | `1` |
| `service.port` | Service and container port | `4873` |
| `route.enabled` | Enable the OpenShift Route | `true` |
| `persistence.enabled` | Enable local PVC storage | `true` |
| `persistence.size` | PVC storage size | `10Gi` |

## Chart versions

| Chart version | plugin-registry-backend version |
|---------------|---------------------------------|
| 0.1.0         | v0.4.2                          |
