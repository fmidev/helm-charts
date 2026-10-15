# Upgrade notes for chart 2.0.0

Chart `2.0.0` no longer assumes the nginx ingress controller. The Ingress defaults are neutral, so the chart works with any controller, including OpenShift:

- `ingress.customAnnotations` is renamed to `ingress.annotations`, which defaults to `{}`. The chart no longer sets nginx annotations itself. Template rendering fails if `ingress.customAnnotations` is still set.
- `ingress.ingressClassName` defaults to `""`, which uses the cluster's default IngressClass, instead of `nginx`.
- `location.path` defaults to the plain prefix `/location-backend` instead of the nginx regex `/location-backend/(.*)`.
- The new `ingress.enabled` (default `true`) leaves the Ingress out when set to `false`.

With a plain prefix path the controller passes the prefix on, and FastAPI removes it based on `location.env.APPLICATION_ROOT_PATH`, so keep that the same as `location.path`.

To keep the previous nginx ingress controller setup, set:

```yaml
location:
  path: /location-backend/(.*)
ingress:
  ingressClassName: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "DELETE, PUT, GET, POST, OPTIONS, PATCH, HEAD"
```

# Upgrade notes for chart 1.2.0

Chart `1.2.0` sets the variables from `location.env` directly in the Deployment instead of in a ConfigMap.

- Values files do not need changes.
- Changing a variable now restarts the pods automatically, so `location.commitHash` is not needed for that.
- Values are passed to the containers as is, like before: Kubernetes does not expand `$(NAME)` or `$$` in them.

# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
```yaml
location:
  url: geoweb.example.com
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-location-backend fmi/geoweb-location-backend --dry-run --debug --namespace geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-location-backend fmi/geoweb-location-backend --namespace geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace geoweb geoweb-location-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the location backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.location` | Possibility to override application version | |
| `location.name` | Name of backend | `location` |
| `location.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/location-backend` |
| `location.commitHash` | Adds commitHash annotation to the deployment | |
| `location.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `location.url` | Url which the application can be accessed | |
| `location.path` | Path prefix of the service in the Ingress | `/location-backend` |
| `location.svcPort` | Port used for service | `80` |
| `location.containerPort` | Port used for container | `8080` |
| `location.replicas` | Amount of replicas deployed | `1` |
| `location.minPodsAvailable` | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0` |
| `location.resources` | Configure resource limits & requests | see defaults in `values.yaml` |
| `location.livenessProbe` | Configure livenessProbe | see defaults in `values.yaml` |
| `location.readinessProbe` | Configure readinessProbe | see defaults in `values.yaml` |
| `location.startupProbe` | Configure startupProbe | see defaults in `values.yaml` |
| `location.env.APPLICATION_DOC_ROOT` | Endpoint for OpenAPI specification. | `/api` |
| `location.env.APPLICATION_ROOT_PATH` | Application root path for FastAPI. Generally the same as `location.path`, without any regex part | `/location-backend` |
| `location.env.LOCALDATA` | Enable or disable searching local data sources. Either `True` or `False` | `True` |
| `location.env.PDOK_SUGGEST_URL` | PDOK suggest URL. Set empty string to disable. | Default value is set in the application |
| `location.env.PDOK_LOOKUP_URL` | PDOK lookup URL. Set empty string to disable. | Default value is set in the application |
| `location.env.GEONAMES_SEARCH_URL` | GeoNames search URL. Set empty string to disable. | Default value is set in the application |
| `location.env.GEONAMES_LOOKUP_URL` | GeoNames lookup URL. Set empty string to disable. | Default value is set in the application |
| `location.env.SMARTMET_AUTOCOMPLETE_URL` | SMARTMET autocomplete URL. | `` |
| `location.env.MAX_RESULTS` | Maximum amount of returned search results per source | `100` |
| `location.env.DEFAULT_TIMEOUT` | Application-wide value for request time-outs in seconds | `15` |
| `location.env.LOG_LEVEL` | Set the log level. Options are `DEBUG`, `INFO`, `WARNING`, `ERROR` | `INFO` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.ingressClassName` | IngressClass for the Ingress. Empty uses the cluster's default IngressClass | `""` |
| `ingress.annotations` | Annotations for your ingress controller, for example nginx rewrite or cert-manager annotations. See the upgrade notes for the previous nginx defaults | `{}` |
| `ingress.enabled` | Create the Ingress | `true` |

# Chart versions

| Chart version | location version |
|---------------|------------------|
| 2.0.0         | 0.3.1            |
| 1.2.0         | 0.3.1            |
| 1.1.10        | 0.3.1            |
| 1.1.9         | 0.3.0            |
| 1.1.8         | 0.2.6            |
| 1.1.7         | 0.2.5            |
| 1.1.6         | 0.2.2            |
| 1.1.5         | 0.2.0            |
| 1.1.4         | 0.0.16           |
| 1.1.3         | 0.0.15           |
| 1.1.2         | 0.0.13           |
| 1.1.1         | 0.0.10           |
| 1.1.0         | 0.0.9            |
| 1.0.3         | 0.0.7            |
| 1.0.2         | 0.0.5            |
| 1.0.1         | 0.0.1            |
| 1.0.0         | 0.0.1            |

