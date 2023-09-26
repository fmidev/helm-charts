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
helm install geoweb-cap-backend fmi/geoweb-cap-backend --dry-run --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-cap-backend fmi/geoweb-cap-backend -n geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb geoweb-cap-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the CAP backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.cap` | Possibility to override application version | `v0.4.0` |
| `cap.name` | Name of backend | `cap` |
| `cap.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/cap-backend` |
| `cap.commitHash` | Adds commitHash annotation to the deployment | |
| `cap.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `cap.url` | Url which the application can be accessed | |
| `cap.path` | Path suffix added to url | `/cap/(.*)` |
| `cap.svcPort` | Port used for service | `80` |
| `cap.containerPort` | Port used for container | `8080` |
| `cap.replicas` | Amount of replicas deployed | `1` |
| `cap.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | `nginx` |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |