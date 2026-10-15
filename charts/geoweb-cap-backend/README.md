# Upgrade notes for chart 2.0.0

Chart `2.0.0` no longer assumes the nginx ingress controller. The Ingress defaults are neutral, so the chart works with any controller, including OpenShift:

- `ingress.customAnnotations` is renamed to `ingress.annotations`, which defaults to `{}`. The chart no longer sets nginx annotations itself. Template rendering fails if `ingress.customAnnotations` is still set.
- `ingress.ingressClassName` defaults to `""`, which uses the cluster's default IngressClass, instead of `nginx`.
- `cap.path` defaults to the plain prefix `/cap` instead of the nginx regex `/cap/(.*)`.
- The new `ingress.enabled` (default `true`) leaves the Ingress out when set to `false`.

With a plain prefix path the controller passes the prefix on, and FastAPI removes it based on `cap.env.APPLICATION_ROOT_PATH`, so keep that the same as `cap.path`.

To keep the previous nginx ingress controller setup, set:

```yaml
cap:
  path: /cap/(.*)
ingress:
  ingressClassName: nginx
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-methods: "DELETE, PUT, GET, POST, OPTIONS, PATCH, HEAD"
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

- Minimal setup

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
| `cap.path` | Path prefix of the service in the Ingress | `/cap` |
| `cap.svcPort` | Port used for service | `80` |
| `cap.containerPort` | Port used for container | `8080` |
| `cap.replicas` | Amount of replicas deployed | `1` |
| `cap.minPodsAvailable` | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0` |
| `cap.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `cap.livenessProbe` | Configure livenessProbe | see defaults from `values.yaml` |
| `cap.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `cap.startupProbe` | Configure startupProbe | see defaults from `values.yaml` |
| `cap.env.APPLICATION_ROOT_PATH` | Application root path for FastAPI. Generally the same as `cap.path`, without any regex part | `/cap` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.ingressClassName` | IngressClass for the Ingress. Empty uses the cluster's default IngressClass | `""` |
| `ingress.annotations` | Annotations for your ingress controller, for example nginx rewrite or cert-manager annotations. See the upgrade notes for the previous nginx defaults | `{}` |
| `ingress.enabled` | Create the Ingress | `true` |

# Chart versions

| Chart version | cap version |
|---------------|-------------|
| 2.0.0         | 0.11.0      |
| 1.9.1         | 0.11.0      |
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
