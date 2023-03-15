# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
```yaml
presets:
  url: geoweb.example.com
  PRESETS_BACKEND_DB: postgresql://[user[:password]@][netloc][:port][/dbname]
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-presets-backend fmi/geoweb-presets-backend --dry-run --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-presets-backend fmi/geoweb-presets-backend -n geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb geoweb-presets-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the Presets backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.presets` | Possibility to override application version | `1.4.1` |
| `presets.name` | Name of backend | `presets` |
| `presets.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/presets-backend` |
| `presets.url` | Url which the application can be accessed | |
| `presets.path` | Path suffix added to url | `/presets/(.*)` |
| `presets.svcPort` | Port used for service | `80` |
| `presets.PRESETS_PORT_HTTP` | Port used for container | `8080` |
| `presets.replicas` | Amount of replicas deployed | `1` |
| `presets.EXTERNALADDRESSES` | - | `0.0.0.0:80` |
| `presets.PRESETS_BACKEND_DB` | Postgresql database connection string | |
| `presets.nginx.name` | Name of nginx container | `nginx` |
| `presets.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/presets-backend/nginx-presets-backend` |
| `presets.nginx.PRESETS_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `presets.nginx.OAUTH2_USERINFO` | - | `https://gitlab.com/oauth/userinfo` |
| `presets.nginx.PRESETS_BACKEND_HOST` | Address where nginx accesses the backend | `0.0.0.0:8080` |
| `presets.nginx.NGINX_PORT_HTTP` | Port used for nginx | `80` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |