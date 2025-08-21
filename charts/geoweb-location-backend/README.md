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
| `location.path` | Path suffix added to url | `/location-backend/(.*)` |
| `location.svcPort` | Port used for service | `80` |
| `location.containerPort` | Port used for container | `8080` |
| `location.replicas` | Amount of replicas deployed | `1` |
| `location.minPodsAvailable` | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0` |
| `location.resources` | Configure resource limits & requests | see defaults in `values.yaml` |
| `location.livenessProbe` | Configure livenessProbe | see defaults in `values.yaml` |
| `location.readinessProbe` | Configure readinessProbe | see defaults in `values.yaml` |
| `location.startupProbe` | Configure startupProbe | see defaults in `values.yaml` |
| `location.env.APPLICATION_DOC_ROOT` | Endpoint for OpenAPI specification. | `/api` |
| `location.env.APPLICATION_ROOT_PATH` | Application root path for FastAPI. Generally same as `location.path` without the wildcard. | `/location-backend` |
| `location.env.LOCALDATA` | Enable or disable searching local data sources. Either `True` or `False` | `True` |
| `location.env.PDOK_SUGGEST_URL` | PDOK suggest URL. Set empty string to disable. | Default value is set in the application |
| `location.env.PDOK_LOOKUP_URL` | PDOK lookup URL. Set empty string to disable. | Default value is set in the application |
| `location.env.GEONAMES_SEARCH_URL` | GeoNames search URL. Set empty string to disable. | Default value is set in the application |
| `location.env.GEONAMES_LOOKUP_URL` | GeoNames lookup URL. Set empty string to disable. | Default value is set in the application |
| `location.env.MAX_RESULTS` | Maximum amount of returned search results per source | `100` |
| `location.env.DEFAULT_TIMEOUT` | Application-wide value for request time-outs in seconds | `15` |
| `location.env.LOG_LEVEL` | Set the log level. Options are `DEBUG`, `INFO`, `WARNING`, `ERROR` | `INFO` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | `nginx` |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |

# Chart versions

| Chart version | location version |
|---------------|------------------|
| 1.1.1         | 0.0.10           |
| 1.1.0         | 0.0.9            |
| 1.0.3         | 0.0.7            |
| 1.0.2         | 0.0.5            |
| 1.0.1         | 0.0.1            |
| 1.0.0         | 0.0.1            |

