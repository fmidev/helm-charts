# Upgrade notes for chart 2.0.0

Chart `2.0.0` renames `ingress.customAnnotations` to `ingress.annotations`. The default nginx annotations are no longer hardcoded in the Ingress template but set as the default value of `ingress.annotations` in `values.yaml`. Template rendering fails if `ingress.customAnnotations` is still set. Values files that do not set `ingress.customAnnotations` do not need changes.

Annotations set in `ingress.annotations` are merged with the default annotations. To remove a default annotation, for example when using another ingress controller than nginx, set it to `null`:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: null
    nginx.ingress.kubernetes.io/force-ssl-redirect: null
    nginx.ingress.kubernetes.io/rewrite-target: null
    nginx.ingress.kubernetes.io/enable-cors: null
    nginx.ingress.kubernetes.io/cors-allow-methods: null
    traefik.annotation: exampleValue
```

# Upgrade notes for chart 1.9.0

Chart `1.9.0` sets the variables from `cap.env` directly in the Deployment instead of in a ConfigMap.

- Values files do not need changes.
- Changing a variable now restarts the pods automatically, so `cap.commitHash` is not needed for that.
- Values are passed to the containers as is, like before: Kubernetes does not expand `$(NAME)` or `$$` in them.

# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
```yaml
cap:
  url: geoweb.example.com
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-cap-backend fmi/geoweb-cap-backend --dry-run --debug --namespace geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-cap-backend fmi/geoweb-cap-backend --namespace geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace geoweb geoweb-cap-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the CAP backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.cap` | Possibility to override application version | |
| `cap.name` | Name of backend | `cap` |
| `cap.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/cap-backend/cap-backend` |
| `cap.commitHash` | Adds commitHash annotation to the deployment | |
| `cap.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `cap.url` | Url which the application can be accessed | |
| `cap.path` | Path suffix added to url | `/cap/(.*)` |
| `cap.svcPort` | Port used for service | `80` |
| `cap.containerPort` | Port used for container | `8080` |
| `cap.replicas` | Amount of replicas deployed | `1` |
| `cap.minPodsAvailable` | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0` |
| `cap.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `cap.livenessProbe` | Configure livenessProbe | see defaults from `values.yaml` |
| `cap.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `cap.startupProbe` | Configure startupProbe | see defaults from `values.yaml` |
| `cap.env.APPLICATION_ROOT_PATH` | Application root path for FastAPI. Generally same as `cap.path` without the wildcard. | `/cap`
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | `nginx` |
| `ingress.annotations` | Annotations for the ingress. Merged with the default nginx annotations, set a default annotation to `null` to remove it | See `values.yaml` |

# Chart versions

| Chart version | cap version |
|---------------|-------------|
| 2.0.0         | 0.11.0      |
| 1.9.0         | 0.11.0      |
| 1.8.6         | 0.11.0      |
| 1.8.5         | 0.10.17     |
| 1.8.4         | 0.10.15     |
| 1.8.3         | 0.10.14     |
| 1.8.2         | 0.10.13     |
| 1.8.1         | 0.10.11     |
| 1.8.0         | 0.10.9      |
| 1.7.5         | 0.10.7      |
| 1.7.4         | 0.10.5      |
| 1.7.3         | 0.10.2      |
| 1.7.2         | 0.10.0      |
| 1.7.1         | 0.10.0      |
| 1.7.0         | 0.8.4       |
| 1.6.0         | 0.8.4       |
| 1.5.2         | 0.8.4       |
| 1.5.1         | 0.8.3       |
| 1.4.1         | 0.8.0       |
| 1.4.0         | 0.6.0       |
